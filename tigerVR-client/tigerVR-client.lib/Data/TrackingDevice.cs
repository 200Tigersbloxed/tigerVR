using System.Runtime.Serialization;
using Valve.VR;

namespace tigerVR_client.lib.Data;

[DataContract]
public record TrackingDevice
{
    private ulong TrackerIndex { get; }
    private TrackedDevicePose_t TrackedDevicePose { get; }
    
    [DataMember] public string Name { get; set; }
    [DataMember] public double3 Position { get; set; }
    [DataMember] public double4 Rotation { get; set; }

    public TrackingDevice(ulong index, HmdMatrix34_t m, string sn)
    {
        TrackerIndex = index;
        Name = sn;
        
        // https://steamcommunity.com/app/250820/discussions/7/1637549649113734898/
        Position = new double3(m.m3, m.m7, m.m11);
        double w = Math.Sqrt(1.0f + m.m0 + m.m5 + m.m10) / 2.0f;
        Rotation = new double4(-((m.m9 - m.m6) / (4 * w)), -((m.m2 - m.m8) / (4 * w)), ((m.m4 - m.m1) / (4 * w)),
            w);
    }
}