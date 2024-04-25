#! /usr/bin/env bash

set -e

BUILD_DIR=./build
LUA_DIR=./src/external/lua

#source ./run.sh

echo "Compiling Lua 5.1"

clang -c -O2 -g -DMAKE_LIB -o ${BUILD_DIR}/onelua.o ${LUA_DIR}/onelua.c
ar rcs ${BUILD_DIR}/liblua51.a ${BUILD_DIR}/onelua.o

rm ${BUILD_DIR}/onelua.o

echo "done."
