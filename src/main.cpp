#include <stdio.h>

extern "C" {
#include "clib.h"
}

extern "C" int libNativeLibrary_CS__CsAdd(int a, int b);
extern "C" int libNativeLibrary_CS__CsDivide(int a, int b);

int main(int argc, char** argv)
{
    int a = 7;
    int b = 3;
    printf("ADD: %d = %d + %d (C++ -> C#)\n", libNativeLibrary_CS__CsAdd(a,b), a, b);
    printf("DIV: %d = %d + %d (C++ -> C# -> C)\n", libNativeLibrary_CS__CsDivide(a,b), a, b);
    printf("MUL: %d = %d + %d (C++ -> C)\n", Multiply(a,b), a, b);

    ExtensionsInit();

    ExtensionUpdateParams p = {.frame = 0};
    for (int i = 0; i < 3; ++i, ++p.frame)
    {
        ExtensionsUpdate(&p);
    }
    return 0;
}
