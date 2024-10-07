#!/usr/bin/env bash

set -e

# https://github.com/dotnet/samples/blob/main/core/nativeaot/NativeLibrary/README.md

PROJ=./NativeLibrary/libNativeLibrary.csproj
NUGET_PACKAGES=.nuget/packages

PLATFORM=$1
if [ "" == "${PLATFORM}" ]; then
    echo "Error, no platform specified"
    echo "Usage: ./compile_external.sh macos"
    exit 1
fi

WINE=
DOTNET=dotnet
ARCH=arm64
if [ ${PLATFORM} == "macos" ]; then
    OS=osx
    if [ "i386" == "$(arch)" ]; then
        ARCH=x64
    fi
elif [ "${PLATFORM}" == "ios" ]; then
    OS=ios
elif [ "${PLATFORM}" == "win64" ]; then
    OS=win
    ARCH=x64
    # WINE=wine
    # DOTNET=${DOTNET_WIN}
    # NUGET_PACKAGES=.nuget/win-packages

    # lib.exe
    export PATH=$(pwd)/scripts/win64:${PATH}
    #export PATH=/opt/local/dotnet-win:${PATH}

fi

BUILD_DIR=./build/${PLATFORM}

mkdir -p ${BUILD_DIR}
mkdir -p ${NUGET_PACKAGES}
NUGET_PACKAGES=$(realpath ${NUGET_PACKAGES})
echo "NUGET_PACKAGES=${NUGET_PACKAGES}"

echo "DOTNET=${DOTNET}"
# echo $(which ${WINE})
# echo $(ls -la ${DOTNET})
# echo $(${WINE} ${DOTNET})

echo DOTNET_CLI_HOME=${DOTNET_CLI_HOME}
export PATH=$PATH:$DOTNET_CLI_HOME
echo "PATH=${PATH}"

DOTNET_MAJOR_VERSION=$(${WINE} ${DOTNET} --version | awk -F'.' '{print $1}')
echo "DOTNET_MAJOR_VERSION=${DOTNET_MAJOR_VERSION}"

DOTNET_VERSION=$(${WINE} ${DOTNET} --version)
echo "DOTNET_VERSION=${DOTNET_VERSION}"

DOTNET_SDK_VERSION=$(${WINE} ${DOTNET} --info | python -c "import sys; lns = sys.stdin.readlines(); i = lns.index('Host:\n'); print(lns[i+1].strip().split()[1])")
echo "DOTNET_SDK_VERSION=${DOTNET_SDK_VERSION}"

AOTBASE=${NUGET_PACKAGES}/microsoft.netcore.app.runtime.nativeaot.${OS}-${ARCH}/${DOTNET_SDK_VERSION}/runtimes/${OS}-${ARCH}/native
echo AOTBASE=${AOTBASE}

PUBLISH_DIR=./NativeLibrary/bin/Release/net${DOTNET_MAJOR_VERSION}.0/${OS}-${ARCH}/native
echo PUBLISH_DIR=${PUBLISH_DIR}

# setup
# ${DOTNET} add ${PROJ} package Microsoft.DotNet.ILCompiler --version 8.0.0

# rm -rf ./NativeLibrary/obj
# rm -rf ./NativeLibrary/bin

# ${WINE} ${DOTNET} clean ${PROJ}
# echo "Cleaned"

# ${WINE} ${DOTNET} publish -c Release -r ${OS}-${ARCH} /bl:aot.binlog  ${PROJ}

# -p:StaticallyLinked=true \
# --self-contained \
# -p:SelfContained=true

# patch the library for macos (issue https://github.com/dotnet/runtime/issues/96663)
#python ./scripts/patch_macho.py ${PUBLISH_DIR}/libNativeLibrary.a

#(cd machorepack && cargo build)

#./machorepack/target/debug/machorepack ${PUBLISH_DIR}/libNativeLibrary.a ${BUILD_DIR}/libNativeLibraryPatched.a

#OPT=-O2
#OPT="-g -O0"
OPT="-g -O2 -flto"
DOSTRIP=true

MIN_OSX_VERSION=12.0

SUFFIX_OBJ=.o
SUFFIX_LIB=.a
PREFIX_LIB=lib
AOTLIB_SUFFIX=
FLAGS=
LIBPATHS="-L${BUILD_DIR}"
LIBS=""
INCLUDES="-I./src/external"
DEFINES=""

if [ ${PLATFORM} == "macos" ]; then
    FLAGS="-arch ${ARCH} -target arm-apple-darwin19 -m64 -miphoneos-version-min=11.0"
    FLAGS="-Wl,-rpath,@executable_path/ ${FLAGS}"
    FLAGS="-framework Foundation ${FLAGS}"

elif [ "${PLATFORM}" == "ios" ]; then
    FLAGS="-arch ${ARCH} -target arm-apple-darwin19 -m64 -miphoneos-version-min=11.0"
    FLAGS="-Wl,-rpath,@executable_path/ ${FLAGS}"
    FLAGS="-framework Foundation ${FLAGS}"

elif [ "${PLATFORM}" == "win64" ]; then
    FLAGS="-m64 -target x86_64-pc-win32-msvc -fuse-ld=lld -Wl,-subsystem:console -Wl,/entry:mainCRTStartup -Wl,/safeseh:no"

    DOSTRIP=
    SUFFIX_OBJ=.obj
    SUFFIX_LIB=.lib
    PREFIX_LIB=
    AOTLIB_SUFFIX=.Aot
    LIBPATHS="-L${WINDOWS_MSVC_DIR_2022}/lib/x64 ${LIBPATHS}"
    LIBPATHS="-L${WINDOWS_MSVC_DIR_2022}/atlmfc/lib/x64 ${LIBPATHS}"
    LIBPATHS="-L${WINDOWS_SDK_10_DIR}/Lib/${WINDOWS_SDK_10_20348_VERSION}/ucrt/x64 ${LIBPATHS}"
    LIBPATHS="-L${WINDOWS_SDK_10_DIR}/Lib/${WINDOWS_SDK_10_20348_VERSION}/um/x64 ${LIBPATHS}"

    # DEFINES="-D_CRT_SECURE_NO_WARNINGS ${DEFINES}"
    # DEFINES="-D_CRT_USE_BUILTIN_OFFSETOF ${DEFINES}"
    # DEFINES="-D_WINSOCK_DEPRECATED_NO_WARNINGS ${DEFINES}"
    # DEFINES="-D__STDC_LIMIT_MACROS ${DEFINES}"
    # DEFINES="-DWINVER=0x0600 ${DEFINES}"
    # DEFINES="-DWIN32 ${DEFINES}"
    # DEFINES="-DNOMINMAX ${DEFINES}"

    LIBS="-lbcrypt ${LIBS}"
    LIBS="-lOle32 ${LIBS}"
    LIBS="-ladvapi32 ${LIBS}"

    INCLUDES="-I${WINDOWS_MSVC_DIR_2022}/include ${INCLUDES}"
    INCLUDES="-I${WINDOWS_SDK_10_DIR}/Include/${WINDOWS_SDK_10_20348_VERSION}/ucrt ${INCLUDES}"
    INCLUDES="-I${WINDOWS_SDK_10_DIR}/Include/${WINDOWS_SDK_10_20348_VERSION}/um ${INCLUDES}"
    INCLUDES="-I${WINDOWS_SDK_10_DIR}/Include/${WINDOWS_SDK_10_20348_VERSION}/shared ${INCLUDES}"
fi


clang -c ${OPT} ${FLAGS} ${DEFINES} ${INCLUDES} -o ${BUILD_DIR}/clib${SUFFIX_OBJ} ./src/clib.c
ar rcs ${BUILD_DIR}/${PREFIX_LIB}clib${SUFFIX_LIB} ${BUILD_DIR}/clib${SUFFIX_OBJ}

cp -v ${PUBLISH_DIR}/libNativeLibrary${SUFFIX_LIB} ${BUILD_DIR}/${PREFIX_LIB}NativeLibrary${SUFFIX_LIB}


# -flto seems to remove something vital and the exe crashes
# -force_load instead of --whole-archive and --no-whole-archive

clang++ ${OPT} ${FLAGS} -o ${BUILD_DIR}/test \
    ${INCLUDES} \
    ${DEFINES} \
    ${LIBPATHS} \
    -l${BUILD_DIR}/${PREFIX_LIB}clib${SUFFIX_LIB} \
    -l${BUILD_DIR}/${PREFIX_LIB}lua51${SUFFIX_LIB} \
    -l${BUILD_DIR}/${PREFIX_LIB}NativeLibrary${SUFFIX_LIB} \
    ${LIBS} \
    ${AOTBASE}/${PREFIX_LIB}bootstrapperdll${SUFFIX_OBJ} \
    ${AOTBASE}/${PREFIX_LIB}Runtime.WorkstationGC${SUFFIX_LIB} \
    ${AOTBASE}/${PREFIX_LIB}Runtime.VxsortEnabled${SUFFIX_LIB} \
    ${AOTBASE}/${PREFIX_LIB}eventpipe-enabled${SUFFIX_LIB} \
    ${AOTBASE}/${PREFIX_LIB}standalonegc-enabled${SUFFIX_LIB} \
    ${AOTBASE}/${PREFIX_LIB}System.IO.Compression.Native${AOTLIB_SUFFIX}${SUFFIX_LIB} \
    ${AOTBASE}/${PREFIX_LIB}System.Globalization.Native${AOTLIB_SUFFIX}${SUFFIX_LIB} \
    src/main.cpp

if [ "${DOSTRIP}" != "" ]; then
    echo strip ${BUILD_DIR}/test
    strip ${BUILD_DIR}/test
fi

if [ "$(uname)" == "Darwin" ]; then
    otool -L ${BUILD_DIR}/test
fi

ls -la ${BUILD_DIR}/test
