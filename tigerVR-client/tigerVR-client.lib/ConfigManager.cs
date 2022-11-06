using Tommy.Serializer;

namespace tigerVR_client.lib;

public class ConfigManager
{
    public static Config LoadedConfig { get; private set; } = new();
    public static readonly string ConfigLocation = "config.cfg";
    
    public static void CreateConfig()
    {
        if (File.Exists(ConfigLocation))
        {
            // Load
            LogHelper.Debug("Loading Config.");
            Config nc = TommySerializer.FromTomlFile<Config>(ConfigLocation) ?? new Config();
            SaveConfig(nc);
            LoadedConfig = nc;
        }
        else
        {
            // Create
            LogHelper.Debug("No Config Found! Creating Config.");
            Config nc = new Config();
            SaveConfig(nc);
            LoadedConfig = nc;
        }
        LogHelper.Log("Loaded Config!");
    }

    public static void SaveConfig(Config config) => TommySerializer.ToTomlFile(config, ConfigLocation);
}

[TommyTableName("tigerVR-client")]
public class Config
{
    [TommyComment("Your Roblox Username")]
    [TommyInclude]
    public string Username = "";
    [TommyComment("The Token for your Account")]
    [TommyInclude]
    public string Token = "";
    [TommyComment("Whether or not to Authenticate. Cannot be used without a Scripting Utility")]
    [TommyInclude]
    public bool OfflineMode = false;
    [TommyComment("The Port to Broadcast VR Data to")]
    [TommyInclude]
    public int ServerPort = 8000;
    /*[TommyComment("Have the SocketServer broadcast messages on tracker update, rather than per request")]
    [TommyInclude]
    public bool FloodServer = false;*/
}