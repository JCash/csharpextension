#!/usr/bin/env bash

set -e

# https://github.com/dotnet/samples/blob/main/core/nativeaot/NativeLibrary/README.md

PROJ=./NativeLibrary/libNativeLibrary.csproj
NUGET_DIR=~/.nuget/packages
BUILD_DIR=./build

mkdir -p ${BUILD_DIR}

ARCH=arm64
if [ "i386" == "$(arch)" ]; then
    ARCH=x64
fi

AOTBASE=${NUGET_DIR}/runtime.osx-${ARCH}.microsoft.dotnet.ilcompiler/8.0.0

# setup
# dotnet add ${PROJ} package Microsoft.DotNet.ILCompiler --version 8.0.0

dotnet clean ${PROJ}
rm -rf ./NativeLibrary/bin/Release


dotnet publish -c Release -r osx-${ARCH} \
    -p:PublishAot=true \
    -p:NativeLib=Static \
    -p:PublishTrimmed=true \
     ${PROJ}

# -p:StaticallyLinked=true \
# --self-contained \
# -p:SelfContained=true

# -flto seems to remove something vital and the exe crashes
OPT="-O2 -flto"
#OPT="-O2"
OPT="-g -O0 -flto"
DOSTRIP=true

clang -c ${OPT} -o ${BUILD_DIR}/clib.o ./src/clib.c
ar rcs ${BUILD_DIR}/libclib.a ${BUILD_DIR}/clib.o

clang++ ${OPT} -o ${BUILD_DIR}/test \
    -L${BUILD_DIR} \
    -lclib \
    -L./NativeLibrary/bin/Release/net8.0/osx-${ARCH}/native\
    -lNativeLibrary \
    $AOTBASE/sdk/libbootstrapperdll.o \
    $AOTBASE/sdk/libRuntime.WorkstationGC.a \
    $AOTBASE/sdk/libeventpipe-enabled.a \
    $AOTBASE/framework/libSystem.Native.a \
    $AOTBASE/framework/libSystem.IO.Compression.Native.a \
    $AOTBASE/framework/libSystem.Globalization.Native.a \
    -Wl,-rpath,@executable_path/ \
    -framework Foundation \
    src/main.cpp

if [ "${DOSTRIP}" != "" ]; then
    strip ${BUILD_DIR}/test
fi

otool -L ${BUILD_DIR}/test

ls -la ${BUILD_DIR}/test
