using BOLL7708;
using tigerVR_client.lib.Data;
using tigerVR_client.lib.Net;
using Valve.VR;

namespace tigerVR_client.lib;

public class main
{
    public static bool DidInitialize { get; private set; }
    public static bool DidNetInitialize { get; private set; }
    
    public static void Init()
    {
        DependencyManager.LoadLibraries();
        ConfigManager.CreateConfig();
        EasyOpenVRSingleton.Instance.Init();
        SocketServer.Start();
        if (!ConfigManager.LoadedConfig.OfflineMode)
        {
            Socket.Connect();
            Setup();
        }
        else
            Setup2(true);
    }

    private static void Setup(bool didRunAgain = false)
    {
        if (!didRunAgain)
            Socket.SubscribeToResponseMethod("ping", response =>
            {
                Task.Factory.StartNew(() =>
                {
                    Thread.Sleep(new Random().Next(0, 25) * 1000);
                    NetMessages.pong pong = new NetMessages.pong
                    {
                        pingId = response["pingId"]
                    };
                    Socket.Send(NetMessages.NetMessage.Serialize(pong));
                });
            });

        if (!ConfigManager.LoadedConfig.OfflineMode)
        {
            if (string.IsNullOrEmpty(ConfigManager.LoadedConfig.Username))
            {
                LogHelper.Log("Please enter your Roblox Username");
                ConfigManager.LoadedConfig.Username = Console.ReadLine() ?? String.Empty;
                ConfigManager.SaveConfig(ConfigManager.LoadedConfig);
                ConfigManager.LoadedConfig.Token = String.Empty;
            }

            if (string.IsNullOrEmpty(ConfigManager.LoadedConfig.Token))
            {
                LogHelper.Log("Please navigate to tigervr.fortnite.lol/verify and Verify your Roblox account\n" +
                              "After you verify, enter the token below. Make sure the token is exact!");
                ConfigManager.LoadedConfig.Token = Console.ReadLine() ?? String.Empty;
                ConfigManager.SaveConfig(ConfigManager.LoadedConfig);
            }
            LogHelper.Log("Authenticating...");
            if(!didRunAgain)
                Socket.SubscribeToResponseMethod("addUserResponse", response =>
                {
                    if (Convert.ToBoolean(response["userWasAdded"].Value))
                        Setup2();
                    else
                    {
                        LogHelper.Error(
                            "Failed to authenticate user! Please make sure all your information is correct and try again.");
                        ConfigManager.LoadedConfig.Username = String.Empty;
                        ConfigManager.LoadedConfig.Token = String.Empty;
                        ConfigManager.SaveConfig(ConfigManager.LoadedConfig);
                        Setup(true);
                    }
                });
            NetMessages.addUser au = new NetMessages.addUser
            {
                username = ConfigManager.LoadedConfig.Username,
                token = ConfigManager.LoadedConfig.Token
            };
            Socket.Send(NetMessages.NetMessage.Serialize(au));
        }
        else
            Setup2(true);
    }

    private static void Setup2(bool isOffline = false)
    {
        if(!isOffline)
            LogHelper.Log("Authenticated!");
        else
            LogHelper.Warn("Continuing in OfflineMode. You will not be able to upload tracking data to the Server.");
        ConfigManager.SaveConfig(ConfigManager.LoadedConfig);
        DidNetInitialize = true;
        DidInitialize = true;
    }

    private static bool didWarnNoTrackers;
    private static bool didWarnNoInit;
    private static bool didError;

    public static List<TrackingDevice> GetTrackers()
    {
        if (DidInitialize)
        {
            didWarnNoInit = false;
            try
            {
                TrackedDevicePose_t[] tdp =
                    EasyOpenVRSingleton.Instance.GetDeviceToAbsoluteTrackingPose(OpenVR.Compositor.GetTrackingSpace());
                uint[] trackerIndexes =
                    EasyOpenVRSingleton.Instance.GetIndexesForTrackedDeviceClass(ETrackedDeviceClass.GenericTracker);
                if (trackerIndexes.Length > 0)
                {
                    didWarnNoTrackers = false;
                    List<TrackingDevice> trackingDevices = new();
                    for (int i = 0; i < trackerIndexes.Length; i++)
                    {
                        for (int y = 0; y < tdp.Length; y++)
                        {
                            uint trackerIndex = trackerIndexes[i];
                            if (y == trackerIndex)
                            {
                                // This links the positional data to a tracker, verifying that it is indeed a tracker
                                string sn = EasyOpenVRSingleton.Instance.GetStringTrackedDeviceProperty(trackerIndex,
                                    ETrackedDeviceProperty.Prop_SerialNumber_String);
                                TrackedDevicePose_t dp = tdp[y];
                                TrackingDevice trackingDevice = new(trackerIndex, dp.mDeviceToAbsoluteTracking, sn);
                                trackingDevices.Add(trackingDevice);
                            }
                        }
                    }
                    didError = false;

                    return trackingDevices;
                }
                else
                {
                    if (!didWarnNoTrackers)
                    {
                        didWarnNoTrackers = true;
                        LogHelper.Warn("No trackers are connected! Please connect a tracker.");
                    }

                    return new();
                }
            }
            catch (Exception e)
            {
                if(!didError)
                    LogHelper.Error("Failed to GetTrackers! Is SteamVR open and running? Exception: " + e);
                didError = true;
                return new();
            }
        }
        else
        {
            if (didWarnNoInit)
            {
                didWarnNoInit = true;
                LogHelper.Warn("OpenVR is not initialized!");
            }
            return new();
        }
    }

    public static NetBulkTrackingDevices BundleTrackers(List<TrackingDevice> trackingDevices) =>
        new NetBulkTrackingDevices(trackingDevices)
        {
            username = ConfigManager.LoadedConfig.Username,
            token = ConfigManager.LoadedConfig.Token
        };

    public static void Shutdown()
    {
        Socket.ShouldShutdown = true;
        Socket.Close();
        SocketServer.Stop();
    }
}