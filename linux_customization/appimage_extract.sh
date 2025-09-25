#!/usr/bin/env bash
set -euo pipefail

# AppImages suck. Install them for real!
# Run this from wherever the .AppImage is located, probably /home/$USER/Downloads

# Set these correctly for your appimage after extracting it
IMAGE="Inkscape-xxx.AppImage"
APPNAME="Inkscape"
APPDIR="/opt/$APPNAME"
TEMPDIR="./squashfs-root"

ICON=""
DESKTOP=""
EXE=""
RESPONSE=""

# extract the appimage contents -- should include
# - executable
# - .desktop example
# - app icon (.png usually)
extract_appimage() {
    echo "making $IMAGE executable"
    chmod +x "$IMAGE"
    echo "extracting $IMAGE to $TEMPDIR"
    "$IMAGE" --appimage-extract 2&>1 > /dev/null

    if [[ -d "$TEMPDIR" ]]; then
        echo "extracted $IMAGE to $TEMPDIR"
    else
        echo "failed to extract"
        exit 1
    fi

    # examine extracted folder for app APPNAME
    desktop_in_img="$(find "$TEMPDIR" -type f -name '*.desktop' | head -n1)"

    # APPNAME: prefer Name= from the embedded desktop, fallback to filename
    if [[ -f "$desktop_in_img" ]]; then
        APPNAME="$(grep -m1 '^Name=' "$desktop_in_img" | cut -d= -f2)"
        APPNAME="${APPNAME// /-}"   # normalize spaces to dashes
    fi
    APPNAME="${APPNAME:-$(basename "$IMAGE" .AppImage)}"

    # Where we'll install it
    APPDIR="/opt/$APPNAME"

    echo ""
    echo ""
    echo "App details identified after extraction: "
    echo "IMAGE:   $IMAGE"
    echo "APPNAME: $APPNAME"
    echo "APPDIR:  $APPDIR"
    echo "----------------"
}

find_components() {
    echo "Look for the executable, desktop file, and icon. The icon might be buried!"
    echo "When you find them, paste the absolute paths to executable and icon into the prompt"
    echo ""
    echo "Desktop file(s):"
    find "$TEMPDIR" -iname '*.desktop' || true
    echo "----------------"
    echo "Icon candidates:"
    find "$TEMPDIR" -iname '*.png' -o -iname '*.svg' || true
    echo "----------------"
    echo "Executable candidates:"
    find "$TEMPDIR" -iname '*AppRun' -o -iname "*$APPNAME*" || true
    echo "----------------"

    read -r -p "Paste the path to the desktop file: " deskfile
    read -r -p "Paste the path to the icon file: " iconfile
    read -r -p "Paste the path to the executable: " exefile
    read -r -p "Proceed to install with these files? [y/n] " ans

    if [[ $ans == y || $ans == Y ]]; then
        ICON="$iconfile"
        DESKTOP="$deskfile"
        EXE="$exefile"
    else
        echo "exiting"
        exit 1
    fi
}

install_appimage() {
    ## Perform the installation if identified values are correct
    echo ""
    echo ""
    echo "current settings:"
    echo "----------------"
    echo "IMAGE:   $IMAGE"
    echo "APPNAME: $APPNAME"
    echo "APPDIR:  $APPDIR"
    echo "ICON:    $ICON"
    echo "DESKTOP: $DESKTOP"
    echo "EXE:     $EXE"
    echo "----------------"

    # Calculate final file locations
    FINAL_ICON="/usr/share/$APPNAME/$(basename "$ICON")"
    FINAL_EXE="$APPDIR/$(basename "$EXE")"
    FINAL_DESKTOP="/usr/share/applications/$(basename "$DESKTOP")"

    echo ""
    echo "Files will be copied to:"
    echo "----------------"
    echo "ICON:    $ICON -> $FINAL_ICON"
    echo "EXE:     $EXE -> $FINAL_EXE"
    echo "DESKTOP: $DESKTOP -> $FINAL_DESKTOP"
    echo "APPDIR:  $TEMPDIR -> $APPDIR"
    echo "----------------"

    read -r -p "install the appimage with the above settings? [y/n] " ans
    if [[ $ans =~ ^[Yy]$ ]]; then
        echo "installing appimage"
    else
        echo "exiting"
        exit 1
    fi

    # Copy files to their final locations
    echo "copying icon to /usr/share/$APPNAME/"
    sudo mkdir -p "/usr/share/$APPNAME"
    sudo cp "$ICON" "$FINAL_ICON"

    echo "updating icon and exec fields in desktop file"
    # update Exec and Icon fields with final paths
    sed -i -E "s|^Exec=.*$|Exec=${FINAL_EXE} --no-sandbox|"  "$DESKTOP"
    sed -i -E "s|^Icon=.*$|Icon=${FINAL_ICON}|" "$DESKTOP"

    cat "$DESKTOP"
    read -r -p "Does the desktop file look ok? [y/n] " ans

    if [[ $ans == y || $ans == Y ]]; then
        # install desktop entry and move extracted payload
        sudo desktop-file-install "$DESKTOP"
        mkdir -p "/home/$USER/Desktop"
        cp "$DESKTOP" "/home/$USER/Desktop/"

        echo "moving contents of $TEMPDIR to $APPDIR"
        sudo mkdir -p "/opt"
        # -T ensures destination treated as a normal target path, not dir merge
        sudo mv -T "$TEMPDIR" "$APPDIR"
    else
        echo "desktop file not accepted. Exiting"
        exit 1
    fi
}

### ----------------------------------------------------------------
###                      Script Entrypoint
### ----------------------------------------------------------------

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 path/to/AppImage"
    exit 1
fi

# Parse appimage arg
if [[ $1 == *.AppImage ]]; then
    IMAGE="$1"
else
    echo "Usage: $0 path/to/*.AppImage"
    exit 1
fi

extract_appimage
find_components

echo ""
read -r -p "Install now with auto-detected values (y), select components manually (n), or exit (x)? [y/n/x] " ans
if [[ $ans == y || $ans == Y ]]; then
    install_appimage
    exit 0
else
    echo "exiting"
    exit 1
fi
