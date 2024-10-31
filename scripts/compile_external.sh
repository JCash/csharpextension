#! /usr/bin/env bash

PLATFORM=$1
if [ "" == "${PLATFORM}" ]; then
    echo "Error, no platform specified"
    echo "Usage: ./compile_external.sh macos"
    exit 1
fi

BUILD_DIR=./build/${PLATFORM}
LUA_DIR=./src/external/lua

#source ./run.sh

HOST_ARCH=$(arch)
if [ "i386" == "${HOST_ARCH}" ]; then
    HOST_ARCH=x86_64
fi

SUFFIX_OBJ=.o
SUFFIX_LIB=.a
PREFIX_LIB=lib
TARGET=
TARGET_ARCH=
DEFINES=
FLAGS=
CXX=$(which clang++)
CC=$(which clang)
AR=$(which ar)

set -e

if [ "${PLATFORM}" == "ios" ]; then
    TARGET_ARCH=arm64
    SDK=$(xcrun -f --sdk iphoneos --show-sdk-path)
    TARGET="-arch ${TARGET_ARCH} -miphoneos-version-min=11.0 -isystem ${SDK}/usr/include/c++/v1 -isysroot ${SDK} -DLUA_USE_IOS"
elif [ "${PLATFORM}" == "macos" ]; then
    TARGET="-arch ${HOST_ARCH} -target ${HOST_ARCH}-apple-darwin19"
elif [ "${PLATFORM}" == "linux" ]; then
    TARGET="-arch ${HOST_ARCH}"
elif [ "${PLATFORM}" == "android" ]; then
    ANDROID_HOME=/opt/platformsdk/android/
    SDK=${ANDROID_HOME}/android-sdk-linux
    NDK=${ANDROID_HOME}/android-ndk-r25b
    echo "Using ANDROID_HOME=/opt/platformsdk/android"
    echo "Using SDK=${SDK}"
    echo "Using NDK=${NDK}"

    tool_arch="darwin"
    if [ "Linux" == "$(uname)" ]; then
        tool_arch="linux"
    fi
    TARGET_ARCH="aarch64"
    CXX="${NDK}/toolchains/llvm/prebuilt/${tool_arch}-x86_64/bin/aarch64-linux-android21-clang++"
    CC="${NDK}/toolchains/llvm/prebuilt/${tool_arch}-x86_64/bin/aarch64-linux-android21-clang"
    AR="${NDK}/toolchains/llvm/prebuilt/${tool_arch}-x86_64/bin/llvm-ar"
    INCLUDES="-I${NDK}/toolchains/llvm/prebuilt/${tool_arch}-x86_64/sysroot/usr/include"
    FLAGS="-fPIC ${FLAGS}"

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

echo "Using CXX=${CXX}"
echo "Using CC=${CC}"
echo "Using AR=${AR}"

echo "Compiling Lua 5.1"

mkdir -p ${BUILD_DIR}

${CC} -c -O2 -g ${TARGET} -DMAKE_LIB ${DEFINES} ${INCLUDES} -o ${BUILD_DIR}/onelua${SUFFIX_OBJ} ${LUA_DIR}/onelua.c
${AR} rcs ${BUILD_DIR}/${PREFIX_LIB}lua51${SUFFIX_LIB} ${BUILD_DIR}/onelua${SUFFIX_OBJ}

rm ${BUILD_DIR}/onelua${SUFFIX_OBJ}

echo "done."
