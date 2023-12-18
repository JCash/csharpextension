#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "clib.h"

int Multiply(int a, int b)
{
    return a * b;
}

int Divide(int a, int b)
{
    return a / b;
}

typedef struct Extension
{
    struct Extension*   next;
    const char*         name;
    void*               ctx;

    ExtensionInitFn     fn_init;
    ExtensionUpdateFn   fn_update;
} Extension;

static Extension* g_Extensions = 0;

Extension* RegisterExtension(const char* name)
{
    printf("C: RegisterExtension: '%s'\n", name);
    Extension* ext = (Extension*)malloc(sizeof(Extension));
    memset(ext, 0, sizeof(Extension));
    ext->next = g_Extensions;
    ext->name = strdup(name);
    g_Extensions = ext;

    return ext;
}

void ExtensionAddContext(Extension* extension, void* ctx)
{
    extension->ctx = ctx;
}

void ExtensionAddInitFunc(Extension* extension, ExtensionInitFn fn)
{
    extension->fn_init = fn;
    printf("C: Set init function: %p\n", fn);
}

void ExtensionAddUpdateFunc(Extension* extension, ExtensionUpdateFn fn)
{
    extension->fn_update = fn;
    printf("C: Set update function: %p\n", fn);
}

void ExtensionsInit()
{
    printf("C: Initializing extensions\n");
    Extension* ext = g_Extensions;
    while (ext)
    {
        if (ext->fn_init)
        {
            printf("  C: Initializing extension '%s'\n", ext->name);
            ext->fn_init(ext->ctx);
        }
        ext = ext->next;
    }
}

void ExtensionsUpdate(ExtensionUpdateParams* p)
{
    printf("C: Updating extensions\n");
    Extension* ext = g_Extensions;
    while (ext)
    {
        if (ext->fn_init)
        {
            printf("  C: Updating extension '%s'\n", ext->name);
            ext->fn_update(ext->ctx, p);
        }
        ext = ext->next;
    }
}

int ExtensionParamsGetFrame(const ExtensionUpdateParams* p)
{
    return p->frame;
}
