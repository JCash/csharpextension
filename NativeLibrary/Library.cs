using System.Runtime.InteropServices;

public unsafe class CS
{
    private static void CsRegisterExtensionInternal()
    {
        Console.WriteLine("CsRegisterExtensionInternal!");
    }

    [UnmanagedCallersOnly(EntryPoint = "CsRegisterExtension")]
    public static void CsRegisterExtension()
    {
        Console.WriteLine("CsRegisterExtension !");
        CsRegisterExtensionInternal();
    }

    // static void Main(string[] args)
    // {
    // }
}
