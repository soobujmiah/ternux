#!/bin/sh
# Render every scene, one Blender process per scene, with per-scene timing.
set -eu
cd "$(dirname "$0")/.."
mkdir -p renders logs
: > logs/render.log
for scene in 1 2 3 4 5; do
    rm -rf "renders/shot_0$scene"
    start=$(date +%s)
    ./scripts/blender-headless.sh -b --factory-startup --python scripts/render_film.py -- \
        --scene "$scene" --samples "${SAMPLES:-16}" > "logs/render-scene$scene.log" 2>&1
    end=$(date +%s)
    frames=$(find "renders/shot_0$scene" -name 'f_*.png' | wc -l)
    line="scene $scene: $frames frames in $((end - start))s"
    echo "$line" | tee -a logs/render.log
done
