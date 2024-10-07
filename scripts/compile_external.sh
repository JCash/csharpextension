#! /usr/bin/env bash

set -e

PLATFORM=$1
if [ "" == "${PLATFORM}" ]; then
    echo "Error, no platform specified"
    echo "Usage: ./compile_external.sh macos"
    exit 1
fi

BUILD_DIR=./build/${PLATFORM}
LUA_DIR=./src/external/lua

#source ./run.sh

echo "Compiling Lua 5.1"

HOST_ARCH=arm64
if [ "i386" == "$(arch)" ]; then
    HOST_ARCH=x86_64
fi

SUFFIX_OBJ=.o
SUFFIX_LIB=.a
PREFIX_LIB=lib
TARGET=
if [ "${PLATFORM}" == "ios" ]; then
    TARGET_ARCH=arm64
    SDK=$(xcrun -f --sdk iphoneos --show-sdk-path)
    TARGET="-arch ${TARGET_ARCH} -miphoneos-version-min=11.0 -isystem ${SDK}/usr/include/c++/v1 -isysroot ${SDK} -DLUA_USE_IOS"
elif [ "${PLATFORM}" == "macos" ]; then
    TARGET="-arch ${HOST_ARCH} -target ${HOST_ARCH}-apple-darwin19"
elif [ "${PLATFORM}" == "linux" ]; then
    TARGET="-arch ${HOST_ARCH}"
elif [ "${PLATFORM}" == "win64" ]; then
    TARGET="-m64 -target x86_64-pc-win32-msvc"

    INCLUDES="-I/opt/platformsdk/Win32/WindowsKits/10/Include/10.0.20348.0/ucrt"
    INCLUDES="-I/opt/platformsdk/Win32/MicrosoftVisualStudio2022/VC/Tools/MSVC/14.37.32822/include ${INCLUDES}"
    INCLUDES="-I/opt/platformsdk/Win32/WindowsKits/10/Include/10.0.20348.0/um ${INCLUDES}"
    INCLUDES="-I/opt/platformsdk/Win32/WindowsKits/10/Include/10.0.20348.0/shared ${INCLUDES}"


    SUFFIX_OBJ=.obj
    SUFFIX_LIB=.lib
    PREFIX_LIB=
fi

mkdir -p ${BUILD_DIR}

clang -c -O2 -g ${TARGET} -DMAKE_LIB ${INCLUDES} -o ${BUILD_DIR}/onelua${SUFFIX_OBJ} ${LUA_DIR}/onelua.c
ar rcs ${BUILD_DIR}/${PREFIX_LIB}lua51${SUFFIX_LIB} ${BUILD_DIR}/onelua${SUFFIX_OBJ}

rm ${BUILD_DIR}/onelua${SUFFIX_OBJ}

echo "done."
