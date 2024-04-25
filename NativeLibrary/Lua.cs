using System.Runtime.InteropServices;
using System.Reflection.Emit;

public unsafe class Lua
{
    [StructLayout(LayoutKind.Sequential)]
    public class State
    {
        // opaque class
    }

    [DllImport("lua51", CallingConvention = CallingConvention.Cdecl, EntryPoint="lua_pushstring")]
    public static extern void PushString(State* L, String s);

    [DllImport("lua51", CallingConvention = CallingConvention.Cdecl, EntryPoint="lua_pushnumber")]
    public static extern void PushNumber(State* L, double f);

    [DllImport("lua51", CallingConvention = CallingConvention.Cdecl, EntryPoint="lua_setfield")]
    public static extern void SetField(State* L, int index, String name);
}
