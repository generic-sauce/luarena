#!/bin/bash

./build.sh

current=$(pwd)
dir=$(mktemp -d)
cp -r src/* "$dir"
cp -r libs "$dir"
cp -r ffi_libs "$dir"
cd "$dir"
zip luarena.love -r . > /dev/null
mv luarena.love "$current"
