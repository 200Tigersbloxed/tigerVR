using System.Runtime.Serialization;

namespace tigerVR_client.lib.Data;

public record FaceWeight
{
    [DataMember] public string Name { get; set; } = String.Empty;
    [DataMember] public float Value { get; set; }
}