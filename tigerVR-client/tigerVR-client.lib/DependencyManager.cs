using System.Reflection;
using System.Runtime.InteropServices;

namespace tigerVR_client.lib;

public class DependencyManager
{
    private static readonly Dictionary<string, string> NativeLibraries = new()
    {
        ["openvr_api.dll"] = "tigerVR_client.lib.Libraries.openvr.win64.openvr_api.dll"
    };
    
    [DllImport("kernel32", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern IntPtr LoadLibrary(string lpFileName);

    public static void LoadLibraries()
    {
        foreach (KeyValuePair<string, string> nativeLibraryLocationEntry in NativeLibraries)
        {
            if (!File.Exists(nativeLibraryLocationEntry.Key))
            {
                try
                {
                    using (Stream? stream = Assembly.GetExecutingAssembly()
                               .GetManifestResourceStream(nativeLibraryLocationEntry.Value))
                    {
                        if (stream != null)
                        {
                            byte[] ba = new byte[stream.Length];
                            stream.Read(ba, 0, ba.Length);
                            File.WriteAllBytes(nativeLibraryLocationEntry.Key, ba);
                            LoadLibrary(nativeLibraryLocationEntry.Key);
                            LogHelper.Debug($"Loaded Library {nativeLibraryLocationEntry.Key}");
                        }
                    }
                }
                catch (Exception e)
                {
                    LogHelper.Error($"Failed to load library {nativeLibraryLocationEntry.Key} with exception: {e}");
                }
            }
            else
            {
                LoadLibrary(nativeLibraryLocationEntry.Key);
                LogHelper.Debug($"Loaded Library {nativeLibraryLocationEntry.Key}");
            }
        }
    }
}