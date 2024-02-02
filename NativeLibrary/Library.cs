using System.Runtime.InteropServices;
using System.Reflection.Emit;
public unsafe class CS
{
    // [StructLayout(LayoutKind.Sequential)]
    // public class Person
    // {
    //     public int Age { get; set; }
    //     public Gender Gender { get; set; }
    // }

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    public delegate int ExtensionCallbackInit(ref CSExtensionContext ctx);

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    public delegate int ExtensionCallbackUpdate(ref CSExtensionContext ctx, dmSDK.ExtensionUpdateParams* update_params);

    public class CSExtensionContext
    {
        public int update;

        public ExtensionCallbackInit fn_init;
        public ExtensionCallbackUpdate fn_update;

        public CSExtensionContext() {
            update = -1;
        }
    }

    [DllImport("clib", CallingConvention = CallingConvention.Cdecl)]
    public static extern int Divide(int a, int b);

    [UnmanagedCallersOnly(EntryPoint = "CsAdd")]
    public static int CsAdd(int a, int b)
    {
        return a + b;
    }

    [UnmanagedCallersOnly(EntryPoint = "CsDivide")]
    public static int CsDivide(int a, int b)
    {
        return Divide(a, b);
    }

    static private int CSExtensionInit(ref CSExtensionContext ctx)
    {
        Console.WriteLine(String.Format("    CS: Extension Init! ctx: {0}", ctx.update));
        ++ctx.update;
        return 0;
    }

    static private int CSExtensionUpdate(ref CSExtensionContext ctx, dmSDK.ExtensionUpdateParams* update_params)
    {
        int frame = dmSDK.ExtensionParamsGetFrame(update_params);
        Console.WriteLine(String.Format("    CS: Extension Update! ctx: {0}  frame: {1}", ctx.update, frame));
        ++ctx.update;
        return 0;
    }

    static private CSExtensionContext g_Ctx = null;

    // ************************************************************

    private static void CsRegisterExtensionInternal()
    {
        Console.WriteLine("CsRegisterExtensionInternal!");

        CS.g_Ctx = new CSExtensionContext();
        dmSDK.Extension* extension = dmSDK.RegisterExtension("cs_extension");

        fixed (CSExtensionContext* ptr = &CS.g_Ctx)
        {
            dmSDK.ExtensionAddContext(extension, (void*)ptr);
        }

        CS.g_Ctx.fn_init = CSExtensionInit;
        CS.g_Ctx.fn_update = CSExtensionUpdate;

        void* pfn;
        if (dmSDK.TryGetFunctionPointer(CS.g_Ctx.fn_init, out pfn))
        {
            dmSDK.ExtensionAddInitFunc(extension, (IntPtr)pfn);
        }
        if (dmSDK.TryGetFunctionPointer(CS.g_Ctx.fn_update, out pfn))
        {
            dmSDK.ExtensionAddUpdateFunc(extension, (IntPtr)pfn);
        }

        UInt64 hash = dmSDK.dmHashString64("hello");

        Console.WriteLine(String.Format("dmSDK.dmHashString64(\"hello\"): {0}", hash));
    }

    [UnmanagedCallersOnly(EntryPoint = "CsRegisterExtension")]
    public static void CsRegisterExtension()
    {
        Console.WriteLine("CsRegisterExtension !");
        CsRegisterExtensionInternal();
    }


    // static CS()
    // {
    //     Console.WriteLine("STATIC CONSTRUCTOR!");
    //     CsRegisterExtensionInternal();
    // }
}
