#include <stdio.h>
#include <stddef.h>

extern "C" {
#include "clib.h"
#include "lua/lualib.h"
#include "lua/lauxlib.h"
}

extern "C" int libNativeLibrary_CS__CsAdd(int a, int b);
extern "C" int libNativeLibrary_CS__CsDivide(int a, int b);
extern "C" int libNativeLibrary_CS__CsRegisterExtension();

static void print_indent(int indent)
{
    for (int i = 0; i < indent; ++i)
    {
        printf("    ");
    }
}

static void print_table(lua_State* L, int indent)
{
    if ((lua_type(L, -2) == LUA_TSTRING))
    {
        print_indent(indent);
        printf("%s\n", lua_tostring(L, -2));
    }

    lua_pushnil(L);
    while(lua_next(L, -2) != 0) {
        if(lua_isstring(L, -1))
        {
            print_indent(indent);
            printf("%s = %s\n", lua_tostring(L, -2), lua_tostring(L, -1));
        }
        else if(lua_isnumber(L, -1))
        {
            print_indent(indent);
            printf("%s = %f\n", lua_tostring(L, -2), lua_tonumber(L, -1));
        }
        else if(lua_istable(L, -1))
        {
            print_table(L, indent+1);
        }
        lua_pop(L, 1);
    }
}

int main(int argc, char** argv)
{
    int a = 7;
    int b = 3;
    printf("ADD: %d = %d + %d (C++ -> C#)\n", libNativeLibrary_CS__CsAdd(a,b), a, b);
    printf("DIV: %d = %d + %d (C++ -> C# -> C)\n", libNativeLibrary_CS__CsDivide(a,b), a, b);
    printf("MUL: %d = %d + %d (C++ -> C)\n", Multiply(a,b), a, b);

    libNativeLibrary_CS__CsRegisterExtension();
    ExtensionsInit();

    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    luaL_loadstring(L, "print('Hello from Lua')");
    lua_pcall(L, 0, LUA_MULTRET, 0);

    ExtensionUpdateParams p = {.frame = 0};
    printf("sizeof(ExtensionUpdateParams) == %zu\n", sizeof(ExtensionUpdateParams));

    p.u8    = 8;
    p.u16   = 16;
    p.u32   = 32;
    p.frame = 0;
    p.f32   = 0.5f;
    p.f64   = 1.5;
    p.L     = L;

    printf("BEFORE (C)\n");
    printf("  frame: %d\n", p.frame);
    printf("  u8: %u\n", (uint32_t)p.u8);
    printf("  u16: %u\n", (uint32_t)p.u16);
    printf("  u32: %u\n", p.u32);
    printf("  f32: %f\n", p.f32);
    printf("  f64: %f\n", p.f64);

    // printf("C POINTER: %lld  %llu\n", (long long)&p, (unsigned long long)&p);
    // printf("  size: %lu\n", sizeof(ExtensionUpdateParams));
    // printf("  offsetof: frame %lu\n", offsetof(ExtensionUpdateParams, frame));
    // printf("  offsetof: u8 %lu\n", offsetof(ExtensionUpdateParams, u8));
    // printf("  offsetof: u16 %lu\n", offsetof(ExtensionUpdateParams, u16));
    // printf("  offsetof: u32 %lu\n", offsetof(ExtensionUpdateParams, u32));
    // printf("  offsetof: f32 %lu\n", offsetof(ExtensionUpdateParams, f32));
    // printf("  offsetof: f64 %lu\n", offsetof(ExtensionUpdateParams, f64));
    // printf("  offsetof: L %lu\n", offsetof(ExtensionUpdateParams, L));

    lua_newtable(L);

    lua_pushnumber(L, 17);
    lua_setfield(L, -2, "c_value");

    for (int i = 0; i < 3; ++i, ++p.frame)
    {
        ExtensionsUpdate(&p);
    }

    printf("Lua Table (C)\n");
    print_table(L, 1);
    printf("\n");

    printf("AFTER (C)\n");
    printf("  frame: %d\n", p.frame);
    printf("  u8: %u\n", (uint32_t)p.u8);
    printf("  u16: %u\n", (uint32_t)p.u16);
    printf("  u32: %u\n", p.u32);
    printf("  f32: %f\n", p.f32);
    printf("  f64: %f\n", p.f64);

    return 0;
}
