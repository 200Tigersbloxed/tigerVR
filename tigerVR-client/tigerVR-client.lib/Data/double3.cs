using System.Runtime.Serialization;

namespace tigerVR_client.lib.Data;

[DataContract]
public record double3
{
    [DataMember] public double X { get; set; }
    [DataMember] public double Y { get; set; }
    [DataMember] public double Z { get; set; }
    
    public double3(){}

    public double3(double x, double y, double z)
    {
        X = x;
        Y = y;
        Z = z;
    }

    public override string ToString() => $"{X}, {Y}, {Z}";
}