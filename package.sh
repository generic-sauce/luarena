#!/bin/bash

current=$(pwd)
dir=$(mktemp -d)
cp -r src/* "$dir"
cp -r libs "$dir"
cd "$dir"
zip luarena.love -r . > /dev/null
mv luarena.love "$current"
