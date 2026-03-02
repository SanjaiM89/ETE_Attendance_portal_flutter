#!/bin/bash
set -e

APPIMAGE_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"

if [ ! -f "appimagetool-x86_64.AppImage" ]; then
    echo "Downloading appimagetool..."
    wget -q "$APPIMAGE_URL"
    chmod +x appimagetool-x86_64.AppImage
fi

export ARCH=x86_64

function create_appimage {
    APP_NAME=$1
    BUNDLE_DIR=$2
    OUTPUT_NAME=$3
    
    echo "Creating AppDir for $OUTPUT_NAME..."
    APP_DIR="${OUTPUT_NAME}.AppDir"
    
    rm -rf "$APP_DIR"
    mkdir -p "$APP_DIR/usr/bin"
    mkdir -p "$APP_DIR/usr/share/applications"
    mkdir -p "$APP_DIR/usr/share/icons/hicolor/256x256/apps"
    
    # Copy all flutter bundle contents into usr/bin
    cp -r "$BUNDLE_DIR"/* "$APP_DIR/usr/bin/"
    
    # Create AppRun (symlink or script)
    cat > "$APP_DIR/AppRun" <<EOF
#!/bin/sh
HERE="\$(dirname "\$(readlink -f "\${0}")")"
export LD_LIBRARY_PATH="\${HERE}/usr/bin/lib:\$LD_LIBRARY_PATH"
exec "\${HERE}/usr/bin/$APP_NAME" "\$@"
EOF
    chmod +x "$APP_DIR/AppRun"
    
    # Create Desktop file
    cat > "$APP_DIR/$OUTPUT_NAME.desktop" <<EOF
[Desktop Entry]
Name=$OUTPUT_NAME
Exec=$APP_NAME
Icon=$OUTPUT_NAME
Type=Application
Categories=Utility;
EOF

    # Copy the provided logo
    cp "/home/sanjai/Desktop/Projects/College/club/Attendance/ETE_STUDENT_BACKEND/logo.png" "$APP_DIR/$OUTPUT_NAME.png"
    # symlink icon
    ln -s "$OUTPUT_NAME.png" "$APP_DIR/.DirIcon"

    echo "Building AppImage for $OUTPUT_NAME..."
    ./appimagetool-x86_64.AppImage "$APP_DIR" "${OUTPUT_NAME}-x86_64.AppImage" || {
        echo "Failed to run appimagetool natively, trying with extract-and-run"
        ./appimagetool-x86_64.AppImage --appimage-extract-and-run "$APP_DIR" "${OUTPUT_NAME}-x86_64.AppImage"
    }
}

create_appimage "frontend" "FrontEnd/build/linux/x64/release/bundle" "Student_Frontend"
create_appimage "frontend" "admin_frontend/build/linux/x64/release/bundle" "Admin_Frontend"

echo "Done packaging AppImages."
