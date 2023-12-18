#!/usr/bin/env bash

# https://github.com/dotnet/samples/blob/main/core/nativeaot/NativeLibrary/README.md

PROJ=./NativeLibrary/libNativeLibrary.csproj
NUGET_DIR=~/.nuget/packages
BUILD_DIR=./build

mkdir -p ${BUILD_DIR}

RT_LIB_DIR=${NUGET_DIR}/runtime.osx-arm64.microsoft.dotnet.ilcompiler/8.0.0/sdk
FRAMEWORK_LIB_DIR=${NUGET_DIR}/runtime.osx-arm64.microsoft.dotnet.ilcompiler/8.0.0/framework

RT_LIB=Runtime.WorkstationGC
EVENT_LIB=eventpipe-enabled
CPP_LIB=stdc++compat
BS_LIB=${RT_LIB_DIR}/libbootstrapperdll.o

SYS_NATIVE_LIB=System.Native
SYS_GLOBAL_LIB=System.Globalization.Native
SYS_COMPRESSION_LIB=System.IO.Compression.Native

# setup
# dotnet add ${PROJ} package Microsoft.DotNet.ILCompiler --version 8.0.0

dotnet clean ${PROJ}
rm -rf ./NativeLibrary/bin/Release

dotnet publish -c Release -r osx-arm64 -p:PublishAot=true -p:NativeLib=Static -p:PublishTrimmed=true -p:SelfContained=true --use-current-runtime ${PROJ}

cp -v ${FRAMEWORK_LIB_DIR}/libSystem.Globalization.Native.dylib ${BUILD_DIR}
cp -v ${FRAMEWORK_LIB_DIR}/libSystem.IO.Compression.Native.dylib ${BUILD_DIR}
cp -v ${FRAMEWORK_LIB_DIR}/libSystem.Native.dylib ${BUILD_DIR}

clang -c -g -O0 -o ${BUILD_DIR}/clib.o ./src/clib.c
ar rcs ${BUILD_DIR}/libclib.a ${BUILD_DIR}/clib.o

# -flto seems to remove something vital and the exe crashes

OPT=-O2
OPT="-g -O0"
clang++ ${OPT} -o ${BUILD_DIR}/test -L./NativeLibrary/bin/Release/net8.0/osx-arm64/native -lNativeLibrary  ${BS_LIB} -L${BUILD_DIR} -L${RT_LIB_DIR} -L${FRAMEWORK_LIB_DIR} -lclib -l${RT_LIB} -l${EVENT_LIB} -l${CPP_LIB} -l${SYS_NATIVE_LIB} -l${SYS_GLOBAL_LIB} -l${SYS_COMPRESSION_LIB} -Wl,-rpath,@executable_path/ src/main.cpp
