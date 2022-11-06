using tigerVR_client.lib.Data;
using WebSocketSharp;
using WebSocketSharp.Server;

namespace tigerVR_client.lib.Net;

public class SocketServer
{
    private static WebSocketServer? server;

    public static void Start()
    {
        Stop();
        server = new WebSocketServer(ConfigManager.LoadedConfig.ServerPort);
        server.AddWebSocketService<WebSocketServerHandler>("/tigervr");
        server.Start();
    }

    public static void Stop()
    {
        if(server != null)
            server.Stop();
    }

    private class WebSocketServerHandler : WebSocketBehavior
    {
        private bool messageError;
        /*private CancellationTokenSource cts = new();
        private Task t;

        protected override void OnOpen()
        {
            cts = new();
            if (ConfigManager.LoadedConfig.FloodServer)
            {
                t = Task.Run(() =>
                {
                    while (!cts.IsCancellationRequested)
                    {
                        try
                        {
                            List<TrackingDevice> trackingDevices = main.GetTrackers();
                            NetBulkTrackingDevices btd = main.BundleTrackers(trackingDevices);
                            string data = NetMessages.NetMessage.Serialize(btd);
                            Send(data);
                        }
                        catch(Exception){}
                        Thread.Sleep(10);
                    }
                });
            }
        }*/

        protected override void OnMessage(MessageEventArgs e)
        {
            switch (e.Data.ToLower())
            {
                case "getcurrenttrackers":
                    try
                    {
                        List<TrackingDevice> trackingDevices = main.GetTrackers();
                        NetBulkTrackingDevices btd = main.BundleTrackers(trackingDevices);
                        string data = NetMessages.NetMessage.Serialize(btd);
                        Send(data);
                        messageError = false;
                    }
                    catch (Exception ee)
                    {
                        if (!messageError)
                        {
                            LogHelper.Error("Failed to send message to client! Exception: " + ee);
                            messageError = true;
                        }
                        Send("{}");
                    }
                    break;
            }
        }

        /*protected override void OnClose(CloseEventArgs e)
        {
            cts.Cancel();
        }*/
    }
}