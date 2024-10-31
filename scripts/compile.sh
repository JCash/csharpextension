#!/usr/bin/env bash

set -e

# https://github.com/dotnet/samples/blob/main/core/nativeaot/NativeLibrary/README.md

PROJ=./NativeLibrary/libNativeLibrary.csproj
NUGET_PACKAGES=$(echo .nuget/packages)

PLATFORM=$1
if [ "" == "${PLATFORM}" ]; then
    echo "Error, no platform specified"
    echo "Usage: ./compile_external.sh macos"
    exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_DIR=$(dirname ${SCRIPT_DIR})

WINE=
DOTNET=dotnet
ARCH=arm64
CLANG_ARCH=arm64
DOTNET_RID=
if [ ${PLATFORM} == "macos" ]; then
    if [ "i386" == "$(arch)" ]; then
        ARCH=x64
        CLANG_ARCH=x86_64
    fi
    DOTNET_RID=osx-${ARCH}
elif [ "${PLATFORM}" == "ios" ]; then
    DOTNET_RID=osx-${ARCH}
elif [ "${PLATFORM}" == "android" ]; then
    DOTNET_RID=linux-bionic-arm64
    CLANG_ARCH=aarch64
    DOTNET_SDK_VERSION="9.0.0-rc.2.24473.5"

elif [ "${PLATFORM}" == "win64" ]; then
    ARCH=x64
    DOTNET_RID=win-${ARCH}
    CLANG_ARCH=x86_64
    # WINE=wine
    # DOTNET=${DOTNET_WIN}
    # NUGET_PACKAGES=.nuget/win-packages

    # lib.exe
    export PATH=${PROJECT_DIR}/scripts/win64:${PATH}
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

if [ "" == "${DOTNET_SDK_VERSION}" ]; then
    DOTNET_SDK_VERSION=$(${WINE} ${DOTNET} --info | python -c "import sys; lns = sys.stdin.readlines(); i = lns.index('Host:\n'); print(lns[i+1].strip().split()[1])")
fi
echo "DOTNET_SDK_VERSION=${DOTNET_SDK_VERSION}"

AOTBASE=${NUGET_PACKAGES}/microsoft.netcore.app.runtime.nativeaot.${DOTNET_RID}/${DOTNET_SDK_VERSION}/runtimes/${DOTNET_RID}/native
echo AOTBASE=${AOTBASE}

PUBLISH_DIR=./NativeLibrary/bin/Release/net${DOTNET_MAJOR_VERSION}.0/${DOTNET_RID}/native
echo PUBLISH_DIR=${PUBLISH_DIR}

rm -rf ./NativeLibrary/obj
rm -rf ./NativeLibrary/bin
rm -rf ./Sdk/obj
rm -rf ./Sdk/bin

${WINE} ${DOTNET} clean -v diag  ${PROJ}
echo "Cleaned"

${WINE} ${DOTNET} publish -v diag -c Release -r ${DOTNET_RID} /bl:aot.binlog  ${PROJ}


#OPT=-O2
#OPT="-g -O0"
OPT="-g -O2 -flto"
DOSTRIP=true

MIN_OSX_VERSION=12.0

SUFFIX_EXE=
SUFFIX_OBJ=.o
SUFFIX_LIB=.a
PREFIX_LIB=lib
AOTLIB_SUFFIX=
FLAGS=
LINKER_FLAGS=
LIBPATHS="-L${BUILD_DIR}"
LIBS=""
INCLUDES="-I${PROJECT_DIR}/src/external"
DEFINES=""
EXTRA_CS_LIBS=
START_GROUP_STATIC=
END_GROUP_STATIC=

DEFOLDSDK=defoldsdk

if [ ${PLATFORM} == "macos" ]; then
    FLAGS="-arch ${CLANG_ARCH} -target arm-apple-darwin19 -m64"

    LINKER_FLAGS="-Wl,-rpath,@executable_path/ ${LINKER_FLAGS}"
    LINKER_FLAGS="-framework Foundation ${LINKER_FLAGS}"

    EXTRA_CS_LIBS="${AOTBASE}/${PREFIX_LIB}System.Native${SUFFIX_LIB} ${EXTRA_CS_LIBS}"
    EXTRA_CS_LIBS="${AOTBASE}/${PREFIX_LIB}Runtime.VxsortEnabled${SUFFIX_LIB} ${EXTRA_CS_LIBS}"


elif [ "${PLATFORM}" == "ios" ]; then
    FLAGS="-arch ${CLANG_ARCH} -target arm-apple-darwin19 -m64 -miphoneos-version-min=11.0"
    LINKER_FLAGS="-Wl,-rpath,@executable_path/ ${LINKER_FLAGS}"
    LINKER_FLAGS="-framework Foundation ${LINKER_FLAGS}"


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
    INCLUDES="-I${NDK}/toolchains/llvm/prebuilt/${tool_arch}-x86_64/sysroot/usr/include ${INCLUDES}"

    FLAGS="-fPIC ${FLAGS}"
    LINKER_FLAGS="-fPIC ${LINKER_FLAGS}"
    #SUFFIX_LIB=".so"

    START_GROUP_STATIC=-Wl,--start-group
    END_GROUP_STATIC=-Wl,--end-group

    LIBS="-llog ${LIBS}"

    EXTRA_CS_LIBS="${AOTBASE}/${PREFIX_LIB}System.Native${SUFFIX_LIB} ${EXTRA_CS_LIBS}"


elif [ "${PLATFORM}" == "win64" ]; then
    FLAGS="-m64 -target x86_64-pc-win32-msvc -fuse-ld=lld -Wl,-subsystem:console -Wl,/entry:mainCRTStartup -Wl,/safeseh:no"

    DOSTRIP=
    SUFFIX_EXE=.exe
    SUFFIX_OBJ=.obj
    SUFFIX_LIB=.lib
    PREFIX_LIB=
    AOTLIB_SUFFIX=.Aot
    LIBPATHS="-L${WINDOWS_MSVC_DIR_2022}/lib/x64 ${LIBPATHS}"
    LIBPATHS="-L${WINDOWS_MSVC_DIR_2022}/atlmfc/lib/x64 ${LIBPATHS}"
    LIBPATHS="-L${WINDOWS_SDK_10_DIR}/Lib/${WINDOWS_SDK_10_20348_VERSION}/ucrt/x64 ${LIBPATHS}"
    LIBPATHS="-L${WINDOWS_SDK_10_DIR}/Lib/${WINDOWS_SDK_10_20348_VERSION}/um/x64 ${LIBPATHS}"

    LIBS="-lbcrypt ${LIBS}"
    LIBS="-lOle32 ${LIBS}"
    LIBS="-ladvapi32 ${LIBS}"

    INCLUDES="-I${WINDOWS_MSVC_DIR_2022}/include ${INCLUDES}"
    INCLUDES="-I${WINDOWS_SDK_10_DIR}/Include/${WINDOWS_SDK_10_20348_VERSION}/ucrt ${INCLUDES}"
    INCLUDES="-I${WINDOWS_SDK_10_DIR}/Include/${WINDOWS_SDK_10_20348_VERSION}/um ${INCLUDES}"
    INCLUDES="-I${WINDOWS_SDK_10_DIR}/Include/${WINDOWS_SDK_10_20348_VERSION}/shared ${INCLUDES}"

    EXTRA_CS_LIBS="${AOTBASE}/${PREFIX_LIB}Runtime.VxsortEnabled${SUFFIX_LIB} ${EXTRA_CS_LIBS}"
fi

echo "Using CXX=${CXX}"
echo "Using CC=${CC}"
echo "Using AR=${AR}"

${CC} -c ${OPT} ${FLAGS} ${DEFINES} ${INCLUDES} -o ${BUILD_DIR}/clib${SUFFIX_OBJ} ./src/clib.c
${AR} rcs ${BUILD_DIR}/${PREFIX_LIB}clib${SUFFIX_LIB} ${BUILD_DIR}/clib${SUFFIX_OBJ}

cp -v ${PUBLISH_DIR}/libNativeLibrary${SUFFIX_LIB} ${BUILD_DIR}/${PREFIX_LIB}NativeLibrary${SUFFIX_LIB}


DEFOLD_LIBRARIES=
if [ "" != "${DEFOLDSDK}" ]; then
    DEFOLD_LIBRARIES="-lextension -ldlib -lprofile_null"

    if [ ${PLATFORM} == "macos" ]; then
        LIBPATHS="-L${DEFOLDSDK}/lib/${CLANG_ARCH}-macos/ ${LIBPATHS}"

    elif [ "${PLATFORM}" == "win64" ]; then
        LIBPATHS="-L${DEFOLDSDK}/lib/x86_64-win32/ ${LIBPATHS}"
        DEFOLD_LIBRARIES="-llibextension -llibdlib -llibprofile_null -lOle32 -lWS2_32 -liphlpapi -lAdvAPI32"

    elif [ "${PLATFORM}" == "android" ]; then
        LIBPATHS="-L${DEFOLDSDK}/lib/arm64-android/ ${LIBPATHS}"
        DEFOLD_LIBRARIES="-lextension -ldlib -lprofile_null"
        LINKER_FLAGS="-shared"
        # SUFFIX_EXE=".so"
        # SUFFIX_LIB=".a"

        echo "LIBPATHS = $LIBPATHS"
    fi
fi

# -flto seems to remove something vital and the exe crashes
# -force_load instead of --whole-archive and --no-whole-archive

OUTPUT=${BUILD_DIR}/test${SUFFIX_EXE}

echo "Linking..."
${CXX} ${OPT} ${FLAGS} ${LINKER_FLAGS} -o ${OUTPUT} \
    ${INCLUDES} \
    ${DEFINES} \
    ${LIBPATHS} \
    ${START_GROUP_STATIC} \
    ${DEFOLD_LIBRARIES} \
    -lclib \
    -llua51 \
    -lNativeLibrary \
    ${LIBS} \
    ${EXTRA_CS_LIBS} \
    ${END_GROUP_STATIC} \
    ${AOTBASE}/${PREFIX_LIB}bootstrapperdll${SUFFIX_OBJ} \
    ${AOTBASE}/${PREFIX_LIB}Runtime.WorkstationGC${SUFFIX_LIB} \
    ${AOTBASE}/${PREFIX_LIB}eventpipe-enabled${SUFFIX_LIB} \
    ${AOTBASE}/${PREFIX_LIB}standalonegc-enabled${SUFFIX_LIB} \
    ${AOTBASE}/${PREFIX_LIB}System.IO.Compression.Native${AOTLIB_SUFFIX}${SUFFIX_LIB} \
    ${AOTBASE}/${PREFIX_LIB}System.Globalization.Native${AOTLIB_SUFFIX}${SUFFIX_LIB} \
    src/main.cpp

echo "Done."

find . -iname "*NativeLibrary.dll" | xargs rm -v
find . -iname "dmsdk.dll" | xargs rm -v

if [ "${DOSTRIP}" != "" ]; then
    echo strip ${OUTPUT}
    strip ${OUTPUT}
fi

if [ "$(uname)" == "Darwin" ]; then
    otool -L ${OUTPUT}
fi

ls -la ${OUTPUT}
