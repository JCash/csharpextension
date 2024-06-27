## Prerequisites

* DotNet 9

    brew install dotnet-sdk@preview

## Build

iOS

    ./scripts/compile.sh ios

## Error

Observe the error in the output log:
```bash
users/mawe/csharpextension $ ./scripts/compile.sh ios                                                  [dotnet-9-ios] 10:05:47
AOTBASE=/Users/mathiaswesterdahl/.nuget/packages/microsoft.netcore.app.runtime.nativeaot.ios-arm64/9.0.0-preview.5.24306.7/runtimes/ios-arm64/native/
PUBLISH_DIR=./NativeLibrary/bin/Release/net9.0/ios-arm64/native
You are using a preview version of .NET. See: https://aka.ms/dotnet-support-policy

Build succeeded in 0,2s
Restore complete (0,3s)
You are using a preview version of .NET. See: https://aka.ms/dotnet-support-policy
  libNativeLibrary failed with 1 error(s) (0,2s)
    CSC : error CS5001: Program does not contain a static 'Main' method suitable for an entry point

Build failed with 1 error(s) in 0,7s
```
