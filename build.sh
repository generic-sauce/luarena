#!/bin/bash

[ ! -d ffi_libs ] && mkdir ffi_libs

for lib in $(ls ffi_src); do
	gcc ffi_src/$lib/lib.c -shared -o ffi_libs/lib$lib.so
	cp ffi_src/$lib/lib.h ffi_libs/lib$lib.h
done
