using tigerVR_client.lib;
using tigerVR_client.lib.Data;
using tigerVR_client.lib.Net;

CancellationTokenSource ctx = new CancellationTokenSource();
Thread worker;

NetBulkTrackingDevices btd = new(new());

LogHelper.Log("Welcome to tigerVR!", ConsoleColor.Cyan);
LogHelper.Log("Initializing libraries...", ConsoleColor.Cyan);
try
{
    main.Init();
    worker = new Thread(secondaryThread);
    worker.Start();
    while (!main.DidInitialize && !main.DidNetInitialize)
    {
        // Wait until it initializes
        Thread.Sleep(1);
    }
    LogHelper.Log("Initialized all libraries!", ConsoleColor.Cyan);
    HandleCommand();
}
catch (Exception e)
{
    LogHelper.Error("Failed to initialize libraries! Exception: " + e);
    End();
}

void HandleCommand()
{
    bool didEnd = false;
    string? command = Console.ReadLine();
    if (!string.IsNullOrEmpty(command))
    {
        string[] cmd = command.Split(' ');
        switch (cmd[0].ToLower())
        {
            case "getcurrenttracking":
                string? gct_res = btd.ToString();
                if(gct_res != null)
                    LogHelper.Log("\n" + gct_res);
                else
                    LogHelper.Warn("No current TrackingDevices.");
                break;
            case "save":
                ConfigManager.SaveConfig(ConfigManager.LoadedConfig);
                break;
            case "exit":
                didEnd = true;
                End();
                break;
        }
    }
    if(!didEnd)
        HandleCommand();
}

void End()
{
    ConfigManager.SaveConfig(ConfigManager.LoadedConfig);
    LogHelper.Log("Press any key to close...");
    Console.ReadKey(false);
    main.Shutdown();
    Environment.Exit(0);
}

void secondaryThread()
{
    while (!ctx.IsCancellationRequested)
    {
        if (main.DidNetInitialize && !ConfigManager.LoadedConfig.OfflineMode)
        {
            List<TrackingDevice> trackingDevices = main.GetTrackers();
            btd = main.BundleTrackers(trackingDevices);
            string data = NetMessages.NetMessage.Serialize(btd);
            if(Socket.IsSocketConnected)
                Socket.Send(data);
        }
        Thread.Sleep(50);
    }
}