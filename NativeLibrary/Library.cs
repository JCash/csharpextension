using System.Runtime.InteropServices;
using System.Reflection.Emit;

using dmSDK.Dlib;
using dmSDK.Extension;
using dmSDK.Lua;

// naming conventions: https://stackoverflow.com/a/1618325/468516

public unsafe partial class CS
{
    private static ConfigFile.Config* g_ConfigFile = null;


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

    static private int CSExtensionAppInitialize(ref Extension.AppParams parameters)
    {
        g_ConfigFile = parameters.ConfigFile;
        return 0; // TODO: Return dmsdk ExtensionResult enum
    }

    static private int CSExtensionAppFinalize(ref Extension.AppParams parameters)
    {
        return 0;
    }

    static private int CSExtensionInitialize(ref Extension.Params parameters)
    {
        // // Register a new Lua module
        // LuaL.RegHelper[] functions = {
        //     new() {name = "rot13", func = Extension.GetFunctionPointer(Rot13)},
        //     new() {name = "get_info", func = Extension.GetFunctionPointer(GetInfo)},
        //     new() {name = null, func = 0}
        // };

        // LuaL.Register(parameters.L, "encoder_cs", functions);
        // Lua.pop(parameters.L, 1);

        Console.WriteLine("Registered ExtensionCSharp");
        return 0;
    }

    static private int CSExtensionFinalize(ref Extension.Params parameters)
    {
        Console.WriteLine(String.Format("    CS: Extension Finalize!"));
        return 0;
    }

    static private int CSExtensionUpdate(ref Extension.Params updateParams)
    {
        return 0;
    }

    // ************************************************************

    private static System.Runtime.InteropServices.GCHandle g_ExtensionBlob;

    private static void CsRegisterExtensionInternal()
    {
        IntPtr app_initialize = Extension.GetFunctionPointer(CSExtensionAppInitialize);
        IntPtr app_finalize = Extension.GetFunctionPointer(CSExtensionAppFinalize);;
        IntPtr initialize = Extension.GetFunctionPointer(CSExtensionInitialize);;
        IntPtr finalize = Extension.GetFunctionPointer(CSExtensionFinalize);;
        IntPtr update = Extension.GetFunctionPointer(CSExtensionUpdate);;
        IntPtr on_event = 0;//Extension.GetFunctionPointer(CSExtensionOnEvent);;

        g_ExtensionBlob = GCHandle.Alloc(new byte[256], GCHandleType.Pinned);

        Extension.Register((void*)g_ExtensionBlob.AddrOfPinnedObject(), 256,
                            "ExtensionCSharp",
                            app_initialize,
                            app_finalize,
                            initialize,
                            finalize,
                            update,
                            on_event);
    }

    [UnmanagedCallersOnly(EntryPoint = "CsRegisterExtension")]
    public static void CsRegisterExtension()
    {
        CsRegisterExtensionInternal();
    }
}


// using System.Runtime.InteropServices;
// using System.Reflection.Emit;

// using System.Reflection; // fieldinfo

// public unsafe class CS
// {
//     [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
//     public delegate int ExtensionCallbackInit(ref CSExtensionContext ctx);

//     [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
//     public delegate int ExtensionCallbackUpdate(ref CSExtensionContext ctx, ref dmSDK.ExtensionUpdateParams update_params);

//     public class CSExtensionContext
//     {
//         public int update;

//         public ExtensionCallbackInit fn_init;
//         public ExtensionCallbackUpdate fn_update;

//         public CSExtensionContext() {
//             update = -1;
//         }
//     }

//     [DllImport("clib", CallingConvention = CallingConvention.Cdecl)]
//     public static extern int Divide(int a, int b);

//     [UnmanagedCallersOnly(EntryPoint = "CsAdd")]
//     public static int CsAdd(int a, int b)
//     {
//         return a + b;
//     }

//     [UnmanagedCallersOnly(EntryPoint = "CsDivide")]
//     public static int CsDivide(int a, int b)
//     {
//         return Divide(a, b);
//     }

//     static private int CSExtensionInit(ref CSExtensionContext ctx)
//     {
//         Console.WriteLine(String.Format("    CS: Extension Init! ctx: {0}", ctx.update));
//         ++ctx.update;
//         return 0;
//     }

//     static private int CSExtensionUpdate(ref CSExtensionContext ctx, ref dmSDK.ExtensionUpdateParams update_params)
//     {
//         // int size = System.Runtime.InteropServices.Marshal.SizeOf(typeof(dmSDK.ExtensionUpdateParams));
//         // Console.WriteLine(String.Format("    CS:   struct: size: {0}", size));
//         // Console.WriteLine(String.Format("    CS:   struct: size: {0}", System.Runtime.InteropServices.Marshal.SizeOf(typeof(dmSDK.ExtensionUpdateParams))));
//         // Console.WriteLine(String.Format("    CS:   field:  frame: {0}", System.Runtime.InteropServices.Marshal.OffsetOf(typeof(dmSDK.ExtensionUpdateParams), "frame")));
//         // Console.WriteLine(String.Format("    CS:   field:  u8: {0}", System.Runtime.InteropServices.Marshal.OffsetOf(typeof(dmSDK.ExtensionUpdateParams), "u8")));
//         // Console.WriteLine(String.Format("    CS:   field:  u16: {0}", System.Runtime.InteropServices.Marshal.OffsetOf(typeof(dmSDK.ExtensionUpdateParams), "u16")));
//         // Console.WriteLine(String.Format("    CS:   field:  u32: {0}", System.Runtime.InteropServices.Marshal.OffsetOf(typeof(dmSDK.ExtensionUpdateParams), "u32")));
//         // Console.WriteLine(String.Format("    CS:   field:  f32: {0}", System.Runtime.InteropServices.Marshal.OffsetOf(typeof(dmSDK.ExtensionUpdateParams), "f32")));
//         // Console.WriteLine(String.Format("    CS:   field:  f64: {0}", System.Runtime.InteropServices.Marshal.OffsetOf(typeof(dmSDK.ExtensionUpdateParams), "f64")));
//         // Console.WriteLine(String.Format("    CS:   field:  L: {0}", System.Runtime.InteropServices.Marshal.OffsetOf(typeof(dmSDK.ExtensionUpdateParams), "L")));

//         ++update_params.u8;
//         ++update_params.u16;
//         ++update_params.u32;
//         ++update_params.f32;
//         ++update_params.f64;

//         Lua.PushNumber(update_params.L, 14);
//         Lua.SetField(update_params.L, -2, "csharp_value");

//         Lua.NewTable(update_params.L);

//             Lua.PushNumber(update_params.L, 4);
//             Lua.SetField(update_params.L, -2, "csharp_subvalue");

//         Lua.SetField(update_params.L, -2, "csharp_subtable");

//         ++ctx.update;
//         return 0;
//     }

//     static private CSExtensionContext g_Ctx = null;

//     // ************************************************************

//     private static void CsRegisterExtensionInternal()
//     {
//         Console.WriteLine("CsRegisterExtensionInternal!");

//         CS.g_Ctx = new CSExtensionContext();
//         dmSDK.Extension* extension = dmSDK.RegisterExtension("cs_extension");

//         fixed (CSExtensionContext* ptr = &CS.g_Ctx)
//         {
//             dmSDK.ExtensionAddContext(extension, (void*)ptr);
//         }

//         CS.g_Ctx.fn_init = CSExtensionInit;
//         CS.g_Ctx.fn_update = CSExtensionUpdate;

//         void* pfn;
//         if (dmSDK.TryGetFunctionPointer(CS.g_Ctx.fn_init, out pfn))
//         {
//             dmSDK.ExtensionAddInitFunc(extension, (IntPtr)pfn);
//         }
//         if (dmSDK.TryGetFunctionPointer(CS.g_Ctx.fn_update, out pfn))
//         {
//             dmSDK.ExtensionAddUpdateFunc(extension, (IntPtr)pfn);
//         }

//         // UInt64 hash = dmSDK.dmHashString64("hello");

//         // Console.WriteLine(String.Format("dmSDK.dmHashString64(\"hello\"): {0}", hash));
//     }

//     [UnmanagedCallersOnly(EntryPoint = "CsRegisterExtension")]
//     public static void CsRegisterExtension()
//     {
//         Console.WriteLine("CsRegisterExtension !");
//         CsRegisterExtensionInternal();
//     }


//     // static CS()
//     // {
//     //     Console.WriteLine("STATIC CONSTRUCTOR!");
//     //     CsRegisterExtensionInternal();
//     // }

//     static void Main(string[] args)
//     {
//     }
// }
