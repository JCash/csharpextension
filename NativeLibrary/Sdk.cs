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

    [StructLayout(LayoutKind.Explicit, Size=23, CharSet = CharSet.Ansi)]
    public class ExtensionUpdateParams
    {
        [FieldOffset(0)]
        public int          frame;
        [FieldOffset(4)]
        public byte         u8;
        [FieldOffset(5)]
        public ushort       u16;
        [FieldOffset(7)]
        public uint         u32;
        [FieldOffset(11)]
        public float        f32;
        [FieldOffset(15)]
        public double       f64;
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
