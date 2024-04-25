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

PUBLISH_DIR=./NativeLibrary/bin/Release/net8.0/osx-${ARCH}/native

# setup
# dotnet add ${PROJ} package Microsoft.DotNet.ILCompiler --version 8.0.0

dotnet clean ${PROJ}
rm -rf ./NativeLibrary/bin/Release


dotnet publish -c Release -r osx-${ARCH} \
    -p:PublishAot=true \
    -p:NativeLib=Static \
    -p:PublishTrimmed=true \
    -p:IlcDehydrate=false \
     ${PROJ}

# -p:StaticallyLinked=true \
# --self-contained \
# -p:SelfContained=true

# patch the library for macos (issue https://github.com/dotnet/runtime/issues/96663)
#python ./scripts/patch_macho.py ${PUBLISH_DIR}/libNativeLibrary.a

(cd machorepack && cargo build)

./machorepack/target/debug/machorepack ${PUBLISH_DIR}/libNativeLibrary.a ${BUILD_DIR}/libNativeLibraryPatched.a


OPT=-O2
OPT="-g -O0"
#OPT="-g -O2 -flto"
DOSTRIP=true

MIN_OSX_VERSION=11.0

clang -c ${OPT} -o ${BUILD_DIR}/clib.o ./src/clib.c
ar rcs ${BUILD_DIR}/libclib.a ${BUILD_DIR}/clib.o

# -flto seems to remove something vital and the exe crashes
# -force_load instead of --whole-archive and --no-whole-archive

clang++ ${OPT} -o ${BUILD_DIR}/test \
    -I./src/external \
    -L${BUILD_DIR} \
    -lclib \
    -ldlib \
    -llua51 \
    -lNativeLibraryPatched \
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
