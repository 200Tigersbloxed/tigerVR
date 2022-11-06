using System.Runtime.Serialization;
using tigerVR_client.lib.Net;

namespace tigerVR_client.lib.Data;

[DataContract]
public class NetBulkTrackingDevices : NetMessages.NetMessage
{
    [DataMember] public override string method { get; set; } = "pushTrackers";
    [DataMember] public string username;
    [DataMember] public string token;
    [DataMember] public TrackingDevice[] trackers;
    // TODO: waiting on Roblox
    [DataMember] public FaceWeight[] faceweights;

    public NetBulkTrackingDevices(List<TrackingDevice> trackingDevices) => trackers = trackingDevices.ToArray();

    public override string? ToString()
    {
        if (trackers.Length <= 0)
            return null;
        string g = String.Empty;
        int i = 0;
        foreach (TrackingDevice trackingDevice in trackers)
        {
            string a = $"[{i}]:\n" +
                       $"   Name: {trackingDevice.Name},\n" +
                       $"   Position: {trackingDevice.Position},\n" +
                       $"   Rotation: {trackingDevice.Rotation}\n";
            g += a;
            i++;
        }
        return g;
    }
}