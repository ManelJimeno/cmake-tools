#!/bin/sh
cd "$(dirname "$0")"
cd ../Resources/bin
export DYLD_LIBRARY_PATH=../lib:$DYLD_LIBRARY_PATH
export QT6_DIR=../lib
exec ./application "$@"
