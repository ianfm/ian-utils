#!/usr/bin/env bash
set -euo pipefail +x
# set +x

# AppImages suck. Install them for real!
# Run this from wherever the .AppImage is located, probably /home/$USER/Downloads

# TODO: look for existing installs in case we are updating!
# Should be able to get the right values from the existing install

# Set these correctly for your appimage after extracting it
IMAGE="Inkscape-xxx.AppImage"
APPNAME="Inkscape"
APPDIR="/opt/$APPNAME"
TEMPDIR="./squashfs-root"

ICON=""
DESKTOP=""
EXE=""
RESPONSE=""

# Extra args appended to Exec= in the installed .desktop file.
# Left empty by default and filled in by detect_exec_args(); see the notes there
# before hardcoding anything into it.
EXEC_ARGS=""

# extract the appimage contents -- should include
# - executable
# - .desktop example
# - app icon (.png usually)
extract_appimage() {
    echo "making $IMAGE executable"
    chmod +x "$IMAGE"
    echo "extracting $IMAGE to $TEMPDIR"
    "$IMAGE" --appimage-extract > /dev/null

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
    find "$TEMPDIR" -maxdepth 1 -iname '*.png' -o -iname '*.svg' || true
    find "$TEMPDIR/resources" -maxdepth 3 -iname '*.png' -o -iname '*.svg' || true
    echo "----------------"
    echo "Executable candidates:"
    find "$TEMPDIR" -maxdepth 1 -iname '*AppRun' -o -iname "*$APPNAME*" || true
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


# --no-sandbox and AppImages, as of 2026:
#
# The flag is a Chromium/Electron option. It is NOT a property of AppImages.
# Only AppImages that bundle Electron/CEF understand it. Everything else --
# wxWidgets (BambuStudio, OrcaSlicer), Qt (FreeCAD), GTK (Inkscape) -- parses
# its own argv, hits an unknown option, prints usage and exits 1. The launcher
# then looks "broken": the icon blips, no window appears, and nothing is logged
# where you would notice. A Desktop copy of the same entry without the flag
# works fine, which makes it look like a desktop-database problem when it isn't.
#
# Why it got added in the first place: on Ubuntu 24.04+ the AppArmor restriction
# on unprivileged user namespaces (kernel.apparmor_restrict_unprivileged_userns=1)
# breaks Chromium's SUID sandbox, so Electron AppImages die at startup with
# "The SUID sandbox helper binary was found, but is not configured correctly".
# --no-sandbox makes them start by turning the renderer sandbox OFF -- that is a
# real security downgrade, not a cosmetic flag, and it applies to every page or
# file the app opens. Prefer, in order:
#   1) an AppArmor profile for the app in /etc/apparmor.d/ (Ubuntu ships a
#      template at /etc/apparmor.d/chrome for reference)
#   2) chmod 4755 + root-owned chrome-sandbox inside the extracted payload
#   3) --no-sandbox, only if neither of the above is workable
#
# So: detect, ask, and default to no flag.
detect_exec_args() {
    EXEC_ARGS=""

    # Electron/CEF payloads ship these; nothing else does.
    if [[ -e "$TEMPDIR/chrome-sandbox" ]] \
        || [[ -e "$TEMPDIR/resources/app.asar" ]] \
        || find "$TEMPDIR" -maxdepth 2 -name 'libEGL.so' -o -maxdepth 2 -name 'snapshot_blob.bin' | grep -q .; then
        echo ""
        echo "This looks like an Electron/Chromium AppImage."
        echo "It may need --no-sandbox on Ubuntu 24.04+ (restricted user namespaces),"
        echo "but that disables the renderer sandbox. See the notes above this function"
        echo "for the safer alternatives (AppArmor profile, or setuid chrome-sandbox)."
        read -r -p "Append --no-sandbox to Exec=? [y/N] " ans
        if [[ $ans =~ ^[Yy]$ ]]; then
            EXEC_ARGS=" --no-sandbox"
        fi
    else
        # Non-Chromium toolkit: the flag is guaranteed to break the launcher.
        echo "Non-Electron AppImage detected; not appending --no-sandbox."
    fi

    # %F lets the entry receive file arguments, so double-clicking an associated
    # file (see MimeType= in the .desktop) opens it in the app instead of
    # launching an empty window.
    if grep -q '^MimeType=' "$DESKTOP" && [[ $EXEC_ARGS != *%[FfUu]* ]]; then
        EXEC_ARGS="$EXEC_ARGS %F"
    fi
}


install_appimage() {
    ## Perform the installation if identified values are correct
    detect_exec_args

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
    echo "ARGS:   ${EXEC_ARGS:-(none)}"
    echo "----------------"

    # Calculate final file locations
    FINAL_ICON="/usr/share/$APPNAME/$(basename "$ICON")"
    FINAL_EXE="$APPDIR/$(basename "$EXE")"
    FINAL_DESKTOP="/usr/share/applications/$(basename "$DESKTOP")"

    echo ""
    echo "Files will be copied to:"
    echo "----------------"
    echo "ICON:    $ICON"
    echo "            -> $FINAL_ICON"
    echo "EXE:     $EXE"
    echo "            -> $FINAL_EXE"
    echo "DESKTOP: $DESKTOP"
    echo "            -> $FINAL_DESKTOP"
    echo "APPDIR:  $TEMPDIR"
    echo "            -> $APPDIR"
    echo -e "----------------\n\n"


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
    sed -i -E "s|^Exec=.*$|Exec=${FINAL_EXE}${EXEC_ARGS}|"  "$DESKTOP"
    sed -i -E "s|^Icon=.*$|Icon=${FINAL_ICON}|" "$DESKTOP"

    cat "$DESKTOP"
    read -r -p "Does the desktop file look ok? [y/n] " ans

    if [[ $ans == y || $ans == Y ]]; then
        # install desktop entry and move extracted payload
        sudo desktop-file-install "$DESKTOP"
        mkdir -p "/home/$USER/Desktop"
        # -a preserves file attributes
        sudo cp -a "$DESKTOP" "/home/$USER/Desktop/"

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
