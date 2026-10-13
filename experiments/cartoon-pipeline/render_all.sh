#!/bin/sh
# Render every shot, one Blender process per shot.
set -eu
cd "$(dirname "$0")"
for shot in 1 2 3 4; do
    rm -rf "out/shot$shot"
    start=$(date +%s)
    ./blender-headless.sh -b --factory-startup --python render.py -- --shot "$shot" \
        > "out/render-shot$shot.log" 2>&1
    end=$(date +%s)
    frames=$(find "out/shot$shot" -name 'f_*.png' | wc -l)
    echo "shot $shot: $frames frames in $((end - start))s"
done
