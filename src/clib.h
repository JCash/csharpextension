#pragma once

int Multiply(int a, int b);
int Divide(int a, int b);


struct Extension;
typedef struct Extension Extension;

typedef struct ExtensionUpdateParams
{
    int frame;
} ExtensionUpdateParams;

int ExtensionParamsGetFrame(const ExtensionUpdateParams* p);

typedef void (*ExtensionInitFn)(void* ctx);
typedef void (*ExtensionUpdateFn)(void* ctx, ExtensionUpdateParams* p);

Extension*  RegisterExtension(const char* name);
void        ExtensionAddContext(Extension* extension, void* ctx);
void        ExtensionAddInitFunc(Extension* extension, ExtensionInitFn fn);
void        ExtensionAddUpdateFunc(Extension* extension, ExtensionUpdateFn fn);

void ExtensionsInit();              // Call init
void ExtensionsUpdate(ExtensionUpdateParams* p);   // Call update
