#!/usr/bin/env bash

set -e

# https://github.com/dotnet/samples/blob/main/core/nativeaot/NativeLibrary/README.md

PLATFORM=$1
if [ "" == "${PLATFORM}" ]; then
    echo "Error, no platform specified"
    echo "Usage: ./compile_external.sh macos"
    exit 1
fi

PROJ=./NativeLibrary/libNativeLibrary.csproj
NUGET_DIR=~/.nuget/packages
BUILD_DIR=./build/${PLATFORM}

mkdir -p ${BUILD_DIR}

OS=ios
ARCH=arm64
if [ "i386" == "$(arch)" ]; then
    ARCH=x64
fi

DOTNET_MAJOR_VERSION=$(dotnet --info | dotnet --version | awk -F'.' '{print $1}')
DOTNET_SDK_VERSION=$(dotnet --info | python -c "import sys; lns = sys.stdin.readlines(); i = lns.index('Host:\n'); print(lns[i+1].strip().split()[1])")

AOTBASE=${NUGET_DIR}/microsoft.netcore.app.runtime.nativeaot.${OS}-${ARCH}/${DOTNET_SDK_VERSION}/runtimes/${OS}-${ARCH}/native/
echo AOTBASE=${AOTBASE}
# ${NUGET_DIR}/microsoft.netcore.app.runtime.nativeaot.ios-arm64/8.0.6/runtimes/ios-arm64//native/libbootstrapperdll.o

PUBLISH_DIR=./NativeLibrary/bin/Release/net${DOTNET_MAJOR_VERSION}.0/${OS}-${ARCH}/native
echo PUBLISH_DIR=${PUBLISH_DIR}

# setup
# dotnet add ${PROJ} package Microsoft.DotNet.ILCompiler --version 8.0.0

dotnet clean ${PROJ}
rm -rf ./NativeLibrary/obj
rm -rf ./NativeLibrary/bin


dotnet publish -c Release -r ${OS}-${ARCH} /bl:aot.binlog ${PROJ}

# -p:StaticallyLinked=true \
# --self-contained \
# -p:SelfContained=true

# patch the library for macos (issue https://github.com/dotnet/runtime/issues/96663)
#python ./scripts/patch_macho.py ${PUBLISH_DIR}/libNativeLibrary.a

(cd machorepack && cargo build)

#./machorepack/target/debug/machorepack ${PUBLISH_DIR}/libNativeLibrary.a ${BUILD_DIR}/libNativeLibraryPatched.a
cp -v ${PUBLISH_DIR}/libNativeLibrary.a ${BUILD_DIR}/


OPT=-O2
#OPT="-g -O0"
#OPT="-g -O2 -flto"
DOSTRIP=true

TARGET=
if [ "${PLATFORM}" == "ios" ]; then
    SDK=$(xcrun -f --sdk iphoneos --show-sdk-path)
    TARGET="-arch arm64 -miphoneos-version-min=11.0 -isystem ${SDK}/usr/include/c++/v1 -isysroot ${SDK}"
elif [ "${PLATFORM}" == "macos" ]; then
    TARGET="-arch arm64 -target arm64-apple-darwin19"
fi

echo TARGET=${TARGET}

clang -c ${OPT} ${TARGET} -I./src/external -o ${BUILD_DIR}/clib.o ./src/clib.c
ar rcs ${BUILD_DIR}/libclib.a ${BUILD_DIR}/clib.o


clang++ ${OPT} ${TARGET} -o ${BUILD_DIR}/test \
    -I./src/external \
    -L${BUILD_DIR} \
    -lclib \
    -llua51 \
    -lNativeLibrary \
    ${AOTBASE}/libbootstrapperdll.o \
    ${AOTBASE}/libRuntime.WorkstationGC.a \
    ${AOTBASE}/libeventpipe-disabled.a \
    ${AOTBASE}/libstandalonegc-disabled.a \
    ${AOTBASE}/libstdc++compat.a \
    ${AOTBASE}/libSystem.Native.a \
    ${AOTBASE}/libSystem.Globalization.Native.a \
    ${AOTBASE}/libSystem.IO.Compression.Native.a \
    ${AOTBASE}/libSystem.Net.Security.Native.a \
    ${AOTBASE}/libSystem.Security.Cryptography.Native.Apple.a \
    ${AOTBASE}/libicucore.a \
    -Wl,-rpath,@executable_path/ \
    -framework Foundation \
    src/main.cpp

if [ "${DOSTRIP}" != "" ]; then
    echo strip ${BUILD_DIR}/test
    strip ${BUILD_DIR}/test
fi

otool -L ${BUILD_DIR}/test

ls -la ${BUILD_DIR}/test
