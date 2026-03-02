#!/bin/bash
if command -v appimage-builder &> /dev/null
then
    echo "Found appimage-builder"
elif command -v linuxdeploy &> /dev/null
then
    echo "Found linuxdeploy"
else
    echo "Neither found. We should download appimagetool"
fi
