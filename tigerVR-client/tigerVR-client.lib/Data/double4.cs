using System.Runtime.Serialization;

namespace tigerVR_client.lib.Data;

[DataContract]
public record double4
{
    [DataMember] public double X { get; set; }
    [DataMember] public double Y { get; set; }
    [DataMember] public double Z { get; set; }
    [DataMember] public double W { get; set; }
    
    public double4(){}

    public double4(double x, double y, double z, double w)
    {
        X = x;
        Y = y;
        Z = z;
        W = w;
    }

    public override string ToString() => $"{X}, {Y}, {Z}, {W}";
}