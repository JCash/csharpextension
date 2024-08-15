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

ARCH=arm64
if [ "i386" == "$(arch)" ]; then
    ARCH=x86_64
fi

TARGET=
if [ "${PLATFORM}" == "ios" ]; then
    SDK=$(xcrun -f --sdk iphoneos --show-sdk-path)
    TARGET="-arch ${ARCH} -miphoneos-version-min=11.0 -isystem ${SDK}/usr/include/c++/v1 -isysroot ${SDK} -DLUA_USE_IOS"
elif [ "${PLATFORM}" == "macos" ]; then
    TARGET="-arch ${ARCH} -target ${ARCH}-apple-darwin19"
fi

mkdir -p ${BUILD_DIR}

clang -c -O2 -g ${TARGET} -DMAKE_LIB -o ${BUILD_DIR}/onelua.o ${LUA_DIR}/onelua.c
ar rcs ${BUILD_DIR}/liblua51.a ${BUILD_DIR}/onelua.o

rm ${BUILD_DIR}/onelua.o

echo "done."
