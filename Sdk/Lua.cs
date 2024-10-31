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
    public static extern void SetField(State* L, int idx, String name);

    [DllImport("lua51", CallingConvention = CallingConvention.Cdecl, EntryPoint="lua_createtable")]
    public static extern void CreateTable(State* L, int narr, int nrec);

    [DllImport("lua51", CallingConvention = CallingConvention.Cdecl, EntryPoint="lua_settop")]
    public static extern void SetTop(State* L, int idx);

    public static void NewTable(State* L)
    {
        CreateTable(L, 0, 0);
    }

    public static void Pop(State* L, int n)
    {
        SetTop(L, -(n)-1);
    }
}
