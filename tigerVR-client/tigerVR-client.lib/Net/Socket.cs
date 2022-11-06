using WebSocketSharp;
using SimpleJSON;

namespace tigerVR_client.lib.Net;

public class Socket
{
    public static bool IsSocketConnected => socket?.IsAlive ?? false;
    
    private static WebSocket? socket;

    public static Action<bool, JSONNode> OnResult = (result, response) => { };
    internal static bool ShouldShutdown;

    public static void Connect()
    {
        Close();
        socket = new WebSocket($"wss://{NetData.baseDomain}:{NetData.websocketPort}/{NetData.websocketEndpoint}");
        socket.OnMessage += (sender, data) =>
        {
            string msg = data.Data;
            try
            {
                JSONNode parsed = JSON.Parse(msg);
                if (parsed["result"] != null && parsed["response"] != null)
                    OnResult.Invoke(parsed["result"].Value == "Success", parsed["response"]);
                else
                    LogHelper.Warn("Unknown WebSocket Message From Server: \n " + msg);
            }
            catch (Exception e)
            {
                LogHelper.Error("Failed to Parse WebSocket Message! msg: \n" + msg + "\n Exception: " + e);
            }
        };
        socket.OnClose += (sender, args) =>
        {
            if(!ShouldShutdown)
                Connect();
        };
        socket.Connect();
    }

    public static void SubscribeToResponseMethod(string method, Action<JSONNode> callback)
    {
        OnResult += (b, response) =>
        {
            try
            {
                if (b || response["method"] != null)
                {
                    if (response["method"].Value == method)
                        callback.Invoke(response);
                }
            }
            catch(Exception e){}
        };
    }

    public static void Send(string data)
    {
        if (IsSocketConnected)
            socket?.Send(data);
        else
            LogHelper.Warn("Attempt to send WebSocket Message while no Socket");
    }

    public static void Close()
    {
        socket?.Close();
        socket = null;
    }
}