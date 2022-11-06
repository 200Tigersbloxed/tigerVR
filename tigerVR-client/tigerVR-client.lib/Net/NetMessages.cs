using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;

namespace tigerVR_client.lib.Net;

public class NetMessages
{
    [DataContract]
    public abstract class NetMessage
    {
        [DataMember] public abstract string method { get; set; }

        public static string Serialize<T>(T item)
        {
            DataContractJsonSerializer js = new DataContractJsonSerializer(typeof(T));
            MemoryStream ms = new MemoryStream();
            js.WriteObject(ms, item);
            ms.Position = 0;
            StreamReader sr = new StreamReader(ms);
            string json = sr.ReadToEnd();
            sr.Close();
            ms.Close();
            return json;
        }
    }
    
    [DataContract]
    public class pong : NetMessage
    {
        public override string method { get; set; } = "pong";
        [DataMember] public string pingId;
    }

    [DataContract]
    public class addUser : NetMessage
    {
        public override string method { get; set; } = "addUser";
        [DataMember] public string username;
        [DataMember] public string token;
    }
}