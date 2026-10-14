#!/bin/sh
# Builds dist/perf_tweaks_khaje_<version>.zip (flashable in Magisk / KernelSU)
set -e
cd "$(dirname "$0")"
V=$(grep '^version=' module/module.prop | cut -d= -f2)
mkdir -p dist
rm -f "dist/perf_tweaks_khaje_$V.zip"
(cd module && zip -r9 "../dist/perf_tweaks_khaje_$V.zip" . -x '.*')
echo "built dist/perf_tweaks_khaje_$V.zip"
