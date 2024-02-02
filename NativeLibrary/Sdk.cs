using System.Runtime.InteropServices;
using System.Reflection.Emit;

public unsafe class dmSDK
{
    [StructLayout(LayoutKind.Sequential)]
    public class Extension
    {
        // opaque class
    }

    [StructLayout(LayoutKind.Sequential)]
    public class ExtensionUpdateParams
    {
        // opaque class
    }

    [DllImport("clib", CallingConvention = CallingConvention.Cdecl)]
    public static extern Extension* RegisterExtension(string name);

    [DllImport("clib", CallingConvention = CallingConvention.Cdecl)]
    public static extern void ExtensionAddContext(Extension* extension, void* ctx);

    [DllImport("clib", CallingConvention = CallingConvention.StdCall)]
    public static extern void ExtensionAddInitFunc(Extension* extension, IntPtr callback);

    [DllImport("clib", CallingConvention = CallingConvention.StdCall)]
    public static extern void ExtensionAddUpdateFunc(Extension* extension, IntPtr callback);

    [DllImport("clib", CallingConvention = CallingConvention.Cdecl)]
    public static extern int ExtensionParamsGetFrame(ExtensionUpdateParams* update_params);

    [DllImport("dlib", CallingConvention = CallingConvention.Cdecl)]
    public static extern UInt64 dmHashString64(string buffer);

    public static bool TryGetFunctionPointer(Delegate d, out void* pointer)
    {
        ArgumentNullException.ThrowIfNull(d);
        var method = d.Method;

        if (d.Target is {} || !method.IsStatic || method is DynamicMethod)
        {
            pointer = null;
            return false;
        }

        pointer = (void*)method.MethodHandle.GetFunctionPointer();
        return true;
    }
}
