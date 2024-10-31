using System.Runtime.InteropServices;
using System.Reflection.Emit;

public unsafe class dmSDK
{
    [StructLayout(LayoutKind.Sequential)]
    public class Extension
    {
        // opaque class
    }

    // examples: https://stackoverflow.com/questions/11968960/how-use-pinvoke-for-c-struct-array-pointer-to-c-sharp
    // field offset: https://stackoverflow.com/questions/8757855/getting-pointer-to-struct-inside-itself-unsafe-context

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi, Pack=1)]
    public struct ExtensionUpdateParams
    {
        public int          frame;
        public byte         u8;
        public ushort       u16;
        public uint         u32;
        public float        f32;
        public double       f64;
        public Lua.State*   L;
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

    // [DllImport("dlib", CallingConvention = CallingConvention.Cdecl)]
    // public static extern UInt64 dmHashString64(string buffer);

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
