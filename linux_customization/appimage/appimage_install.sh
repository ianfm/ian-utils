#!/usr/bin/env bash
set -euo pipefail

# AppImages suck. Install them for real!
#
# Usage: appimage_install.sh [-n|--dry-run] path/to/App.AppImage
#
# Extracts the AppImage, asks you to point at its executable/icon/.desktop,
# then installs:
#   payload -> /opt/$APPNAME
#   icon    -> /usr/share/$APPNAME/
#   entry   -> /usr/share/applications/ and ~/Desktop
#
# -n prints every command that would change the system instead of running it.
# That flag replaces the old appimage_extract.sh, which was this script with
# the mutating lines echo'd -- except it still ran its sed calls, so the "dry
# run" rewrote the extracted .desktop for real.
#
# TODO: look for existing installs in case we are updating!
# Should be able to get the right values from the existing install

DRY_RUN=0
IMAGE=""
APPNAME=""
APPDIR=""
TEMPDIR="./squashfs-root"

ICON=""
DESKTOP=""
EXE=""
EXEC_ARGS=""

usage() {
    echo "Usage: $0 [-n|--dry-run] path/to/App.AppImage"
    exit "${1:-1}"
}

# Everything that touches the system goes through run(), so --dry-run stays dry
# without needing a second copy of the script to drift out of sync.
run() {
    if (( DRY_RUN )); then
        printf '  DRY RUN: '
        printf '%q ' "$@"
        printf '\n'
    else
        "$@"
    fi
}

# extract the appimage contents -- should include
# - executable
# - .desktop example
# - app icon (.png usually)
extract_appimage() {
    echo "making $IMAGE executable"
    chmod +x "$IMAGE"
    echo "extracting $IMAGE to $TEMPDIR"
    # redirecting stderr as well somehow prevents file extraction, leave it be
    "$IMAGE" --appimage-extract > /dev/null

    if [[ ! -d "$TEMPDIR" ]]; then
        echo "failed to extract"
        exit 1
    fi
    echo "extracted $IMAGE to $TEMPDIR"

    # APPNAME: prefer Name= from the embedded desktop, fallback to filename
    local desktop_in_img
    desktop_in_img="$(find "$TEMPDIR" -type f -name '*.desktop' | head -n1)"
    if [[ -f "$desktop_in_img" ]]; then
        APPNAME="$(grep -m1 '^Name=' "$desktop_in_img" | cut -d= -f2)"
        APPNAME="${APPNAME// /-}"   # normalize spaces to dashes
    fi
    APPNAME="${APPNAME:-$(basename "$IMAGE" .AppImage)}"

    APPDIR="/opt/$APPNAME"

    echo ""
    echo "App details identified after extraction:"
    echo "IMAGE:   $IMAGE"
    echo "APPNAME: $APPNAME"
    echo "APPDIR:  $APPDIR"
    echo "----------------"
}

find_components() {
    echo ""
    echo "Look for the executable, desktop file, and icon. The icon might be buried!"
    echo "When you find them, paste the absolute paths into the prompts below."
    echo ""
    echo "Desktop file(s):"
    find "$TEMPDIR" -iname '*.desktop' || true
    echo "----------------"
    echo "Icon candidates (top level first, then a deeper sweep):"
    find "$TEMPDIR" -maxdepth 1 \( -iname '*.png' -o -iname '*.svg' \) || true
    find "$TEMPDIR" -mindepth 2 -maxdepth 4 \( -iname '*.png' -o -iname '*.svg' \) 2>/dev/null | head -20 || true
    echo "----------------"
    echo "Executable candidates:"
    find "$TEMPDIR" -maxdepth 1 -type f \( -iname 'AppRun' -o -iname "*$APPNAME*" \) || true
    # AppRun often just execs a binary in bin/ or usr/bin/, so sweep deeper too
    find "$TEMPDIR" -mindepth 2 -maxdepth 3 -type f -perm -u+x \
        \( -iname 'AppRun' -o -iname "*$APPNAME*" \) 2>/dev/null | head -20 || true
    echo "----------------"
    # For example, these are correct for Logic 2.4.29:
    #   ./squashfs-root/Logic.desktop
    #   ./squashfs-root/resources/linux-x64/LogicIcon.png
    #   ./squashfs-root/Logic

    read -r -p "Paste the path to the desktop file: " DESKTOP
    read -r -p "Paste the path to the icon file: " ICON
    read -r -p "Paste the path to the executable: " EXE

    local f
    for f in "$DESKTOP" "$ICON" "$EXE"; do
        if [[ ! -f "$f" ]]; then
            echo "not a file: $f"
            exit 1
        fi
    done
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
        || find "$TEMPDIR" -maxdepth 2 \( -name 'libEGL.so' -o -name 'snapshot_blob.bin' \) | grep -q .; then
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
    detect_exec_args

    # Where everything lands. The executable keeps its path within the payload,
    # so AppImages whose binary sits in a subdir (bin/, usr/bin/) still work.
    local final_icon final_exec preview
    final_icon="/usr/share/$APPNAME/$(basename "$ICON")"
    final_exec="$APPDIR/$(realpath --relative-to="$TEMPDIR" "$EXE")${EXEC_ARGS}"

    echo ""
    echo "Files will be copied to:"
    echo "----------------"
    echo "ICON:    $ICON"
    echo "            -> $final_icon"
    echo "EXE:     $EXE"
    echo "            -> Exec=$final_exec"
    echo "DESKTOP: $DESKTOP"
    echo "            -> /usr/share/applications/ and $HOME/Desktop"
    echo "APPDIR:  $TEMPDIR"
    echo "            -> $APPDIR"
    echo "----------------"

    # Render the entry into a temp dir so it can be reviewed before anything
    # real is written. desktop-file-install also validates it on the way.
    preview="$(mktemp -d)"
    trap 'rm -rf "$preview"' RETURN
    desktop-file-install --dir="$preview" \
        --set-key=Exec --set-value="$final_exec" \
        --set-key=Icon --set-value="$final_icon" \
        "$DESKTOP"

    echo ""
    echo "desktop entry that will be installed:"
    echo "----------------"
    cat "$preview/$(basename "$DESKTOP")"
    echo "----------------"

    read -r -p "Install the appimage with the above settings? [y/N] " ans
    if [[ ! $ans =~ ^[Yy]$ ]]; then
        echo "exiting"
        exit 1
    fi

    echo "copying icon to /usr/share/$APPNAME/"
    run sudo mkdir -p "/usr/share/$APPNAME"
    run sudo cp "$ICON" "$final_icon"

    echo "installing desktop entry"
    # Desktop entries go to /usr/share/applications/ for system visibility.
    # --rebuild-mime-info-cache is not the default, and without it the MimeType=
    # associations are ignored until something else refreshes the cache.
    run sudo desktop-file-install --rebuild-mime-info-cache \
        --set-key=Exec --set-value="$final_exec" \
        --set-key=Icon --set-value="$final_icon" \
        "$DESKTOP"

    # Same entry on the Desktop. No sudo: it belongs to the user, and both
    # copies come from one command so they cannot drift apart.
    run mkdir -p "$HOME/Desktop"
    run desktop-file-install --dir="$HOME/Desktop" -m 755 \
        --set-key=Exec --set-value="$final_exec" \
        --set-key=Icon --set-value="$final_icon" \
        "$DESKTOP"

    echo "moving contents of $TEMPDIR to $APPDIR"
    run sudo mkdir -p /opt
    # -T ensures destination treated as a normal target path, not dir merge
    run sudo mv -T "$TEMPDIR" "$APPDIR"

    if (( DRY_RUN )); then
        echo ""
        echo "dry run: nothing above was executed, $TEMPDIR left in place"
    else
        echo "installed $APPNAME"
    fi
}

### ----------------------------------------------------------------
###                      Script Entrypoint
### ----------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=1; shift ;;
        -h|--help)    usage 0 ;;
        *.AppImage)   IMAGE="$1"; shift ;;
        *)            echo "unrecognized argument: $1"; usage ;;
    esac
done

[[ -n $IMAGE && -f $IMAGE ]] || usage

extract_appimage
find_components
install_appimage
