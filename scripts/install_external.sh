#! /usr/bin/env bash

if [ -d ./src/external/lua ]; then
    rm -rf ./src/external/lua
fi

curl  -o ./build/lua.zip -L https://github.com/lua/lua/archive/refs/heads/master.zip
unzip -q ./build/lua.zip -d ./src/external
mv ./src/external/lua-master ./src/external/lua
