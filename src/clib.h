#pragma once

#include <stdint.h>

#include "lua/lualib.h"
#include "lua/lauxlib.h"

int Multiply(int a, int b);
int Divide(int a, int b);

#pragma pack(push, 1)

struct Extension;
typedef struct Extension Extension;

typedef struct ExtensionUpdateParams
{
    int         frame;
    uint8_t     u8;
    uint16_t    u16;
    uint32_t    u32;
    float       f32;
    double      f64;

    lua_State*  L;
} ExtensionUpdateParams;

#pragma pack(pop)

int ExtensionParamsGetFrame(const ExtensionUpdateParams* p);

typedef void (*ExtensionInitFn)(void* ctx);
typedef void (*ExtensionUpdateFn)(void* ctx, ExtensionUpdateParams* p);

Extension*  RegisterExtension(const char* name);
void        ExtensionAddContext(Extension* extension, void* ctx);
void        ExtensionAddInitFunc(Extension* extension, ExtensionInitFn fn);
void        ExtensionAddUpdateFunc(Extension* extension, ExtensionUpdateFn fn);

void ExtensionsInit();              // Call init
void ExtensionsUpdate(ExtensionUpdateParams* p);   // Call update
