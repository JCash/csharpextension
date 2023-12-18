## Prerequisites

* DotNet 8

    brew install dotnet

* ILCompiler

https://www.nuget.org/packages/Microsoft.DotNet.ILCompiler
Required for the toolset to be installed, not the project itself

    dotnet add package Microsoft.DotNet.ILCompiler --version 8.0.0 ./NativeLibrary/NativeLibrary.csproj

## Build

    ./scripts/compile.sh

## Run

    ./scripts/run.sh


## Links

* https://github.com/dotnet/samples/blob/main/core/nativeaot/NativeLibrary/README.md

* https://learn.microsoft.com/en-gb/dotnet/core/deploying/native-aot/?tabs=net8plus%2Cwindows#limitations-of-native-aot-deployment

About some limitations:
* https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/?tabs=net8plus%2Cwindows#limitations-of-native-aot-deployment
* https://devblogs.microsoft.com/dotnet/creating-aot-compatible-libraries/

* https://joeysenna.com/posts/nativeaot-in-c-plus-plus

* https://github.com/Joey0x646576/nativeaot-to-cplusplus-example/blob/main/NativeAot/NativeDll/Library.cs

Marshalling:
* https://learn.microsoft.com/en-us/cpp/dotnet/using-cpp-interop-implicit-pinvoke?view=msvc-170#in-this-section

* https://mark-borg.github.io/blog/2017/interop/

Short example
* https://ericsink.com/native_aot/mul_cpp_win_static.html

Compile example:
* https://github.com/ericsink/native-aot-samples/blob/main/mul_cpp_win_static/build.bat

Platform support:
(experimental, apart from Desktop)

* https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/?tabs=net8plus%2Cwindows#platformarchitecture-restrictions

How to create a delegate from the C side, to call C# functions that takes delegates
* https://github.com/ericsink/native-aot-samples/tree/main/delegate_i32
