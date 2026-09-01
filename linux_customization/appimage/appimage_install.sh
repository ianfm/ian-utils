#!/usr/bin/env bash
set -euo pipefail

# AppImages suck. Install them for real!
#
# Usage: appimage_install.sh [-n|--dry-run] path/to/App.AppImage
#
# Extracts the AppImage to a scratch dir, works out its executable/icon/desktop
# entry, then installs:
#   payload -> /opt/$APPNAME
#   icon    -> /usr/share/$APPNAME/
#   entry   -> /usr/share/applications/ and ~/Desktop
# The scratch dir is removed on exit however the script ends, so nothing is left
# lying around in whatever directory you happened to run this from.
#
#   -n, --dry-run   print every command that would change the system, run none
#
#   APPIMAGE_INSTALL_ROOT=/some/dir
#                   install under /some/dir instead of /, without sudo. For
#                   testing the whole flow end to end without touching the
#                   system, e.g.
#                     APPIMAGE_INSTALL_ROOT=/tmp/stage ./appimage_install.sh x.AppImage
#
# TODO: look for existing installs in case we are updating!
# Should be able to get the right values from the existing install

DRY_RUN=0
IMAGE=""
APPNAME=""
WORKDIR=""
PAYLOAD=""

ICON=""
DESKTOP=""
EXE=""
EXEC_ARGS=""

# Staging root for testing; empty means a real install under /.
ROOT="${APPIMAGE_INSTALL_ROOT:-}"
if [[ -n $ROOT ]]; then
    SUDO=()          # a staging root is user-writable
else
    SUDO=(sudo)
fi

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

cleanup() {
    [[ -n $WORKDIR && -d $WORKDIR ]] && rm -rf "$WORKDIR"
}
trap cleanup EXIT

# extract the appimage contents -- should include
# - executable (AppRun, which sets up LD_LIBRARY_PATH etc before exec'ing)
# - .desktop example
# - app icon (.png usually)
extract_appimage() {
    local image_abs
    image_abs="$(realpath "$IMAGE")"
    chmod +x "$image_abs"

    # --appimage-extract always writes ./squashfs-root relative to the cwd, so
    # give it a scratch cwd of its own rather than littering the caller's.
    WORKDIR="$(mktemp -d)"
    PAYLOAD="$WORKDIR/squashfs-root"

    echo "extracting $(basename "$IMAGE") to $PAYLOAD"
    # redirecting stderr as well somehow prevents file extraction, leave it be
    ( cd "$WORKDIR" && "$image_abs" --appimage-extract > /dev/null )

    if [[ ! -d $PAYLOAD ]]; then
        echo "failed to extract"
        exit 1
    fi

    # APPNAME: prefer Name= from the embedded desktop, fallback to filename
    local desktop_in_img
    desktop_in_img="$(find "$PAYLOAD" -maxdepth 1 -type f -name '*.desktop' | head -n1)"
    if [[ -f $desktop_in_img ]]; then
        APPNAME="$(grep -m1 '^Name=' "$desktop_in_img" | cut -d= -f2)"
        APPNAME="${APPNAME// /-}"   # normalize spaces to dashes
    fi
    APPNAME="${APPNAME:-$(basename "$IMAGE" .AppImage)}"
}

# Pick the icon file that Icon= in the .desktop refers to. AppImages carry the
# same icon at several sizes, so prefer scalable, then the largest NxN dir.
pick_icon() {
    local name="$1" best="" best_score=-1 f score
    while IFS= read -r f; do
        if [[ $f == *.svg ]]; then
            score=100000                      # scalable beats any raster size
        elif [[ $f =~ /([0-9]+)x[0-9]+/ ]]; then
            score="${BASH_REMATCH[1]}"        # hicolor size dir
        else
            score=1
        fi
        if (( score > best_score )); then
            best_score=$score
            best="$f"
        fi
    done < <(find "$PAYLOAD" -type f \
                \( -iname "$name.png" -o -iname "$name.svg" -o -iname "$name.xpm" \) 2>/dev/null)
    printf '%s' "$best"
}

# The .desktop file inside the AppImage already names the icon and the binary,
# so read it instead of dumping the whole tree at the user and asking them to
# spot the right three files.
autodetect_components() {
    DESKTOP="$(find "$PAYLOAD" -maxdepth 1 -type f -name '*.desktop' | head -n1)"
    if [[ -z $DESKTOP ]]; then
        DESKTOP="$(find "$PAYLOAD" -type f -name '*.desktop' | head -n1)"
    fi

    # AppRun is the AppImage entrypoint and usually sets up the environment the
    # binary needs, so prefer it over whatever Exec= names.
    if [[ -x $PAYLOAD/AppRun ]]; then
        EXE="$PAYLOAD/AppRun"
    elif [[ -n $DESKTOP ]]; then
        local exec_line exec_bin
        exec_line="$(grep -m1 '^Exec=' "$DESKTOP" | cut -d= -f2-)"
        exec_bin="$(basename "${exec_line%% *}")"
        EXE="$(find "$PAYLOAD" -type f -perm -u+x -name "$exec_bin" | head -n1)"
    fi

    if [[ -n $DESKTOP ]] && grep -q '^Icon=' "$DESKTOP"; then
        local icon_name
        icon_name="$(grep -m1 '^Icon=' "$DESKTOP" | cut -d= -f2)"
        icon_name="$(basename "$icon_name")"
        icon_name="${icon_name%.png}"; icon_name="${icon_name%.svg}"; icon_name="${icon_name%.xpm}"
        ICON="$(pick_icon "$icon_name")"
    fi
    # .DirIcon is the AppImage thumbnail; last resort, and follow the symlink
    if [[ -z $ICON && -e $PAYLOAD/.DirIcon ]]; then
        ICON="$(realpath "$PAYLOAD/.DirIcon")"
    fi
}

# Fallback when autodetection comes up short or picks wrong. Still filtered:
# icons are limited to the top level and to icon theme dirs, executables to the
# top level and the usual bin dirs, rather than everything in the payload.
choose_components_manually() {
    echo ""
    echo "Desktop file(s):"
    find "$PAYLOAD" -type f -name '*.desktop' | head -20 || true
    echo "----------------"
    echo "Icon candidates:"
    { find "$PAYLOAD" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.svg' \)
      find "$PAYLOAD" -type d -name apps -path '*icons*' -exec find {} -type f \; ; } 2>/dev/null | head -20 || true
    echo "----------------"
    echo "Executable candidates:"
    { find "$PAYLOAD" -maxdepth 1 -type f -perm -u+x
      find "$PAYLOAD"/{bin,usr/bin} -maxdepth 1 -type f -perm -u+x 2>/dev/null ; } 2>/dev/null | head -20 || true
    echo "----------------"

    read -r -e -p "Desktop file: " -i "$DESKTOP" DESKTOP
    read -r -e -p "Icon file:    " -i "$ICON" ICON
    read -r -e -p "Executable:   " -i "$EXE" EXE
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
    if [[ -e "$PAYLOAD/chrome-sandbox" ]] \
        || [[ -e "$PAYLOAD/resources/app.asar" ]] \
        || find "$PAYLOAD" -maxdepth 2 \( -name 'libEGL.so' -o -name 'snapshot_blob.bin' \) | grep -q .; then
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

    local appdir icondir appsdir deskdir final_icon final_exec preview
    appdir="$ROOT/opt/$APPNAME"
    icondir="$ROOT/usr/share/$APPNAME"
    appsdir="$ROOT/usr/share/applications"
    deskdir="$ROOT$HOME/Desktop"

    final_icon="$icondir/$(basename "$ICON")"
    # Keep the executable's path within the payload, so AppImages whose binary
    # lives in bin/ or usr/bin/ still get a working Exec=.
    final_exec="$appdir/$(realpath --relative-to="$PAYLOAD" "$EXE")${EXEC_ARGS}"

    echo ""
    echo "Files will be installed to:"
    echo "----------------"
    echo "ICON:    $ICON"
    echo "            -> $final_icon"
    echo "EXE:     $EXE"
    echo "            -> Exec=$final_exec"
    echo "DESKTOP: $DESKTOP"
    echo "            -> $appsdir/ and $deskdir/"
    echo "PAYLOAD: $PAYLOAD"
    echo "            -> $appdir"
    echo "----------------"

    # Render the entry into a temp dir so it can be reviewed before anything
    # real is written. desktop-file-install also validates it on the way.
    preview="$WORKDIR/preview"
    mkdir -p "$preview"
    desktop-file-install --dir="$preview" \
        --set-key=Exec --set-value="$final_exec" \
        --set-key=Icon --set-value="$final_icon" \
        "$DESKTOP"

    echo ""
    echo "desktop entry that will be installed:"
    echo "----------------"
    cat "$preview/$(basename "$DESKTOP")"
    echo "----------------"

    read -r -p "Install with the above settings? [y/N] " ans
    if [[ ! $ans =~ ^[Yy]$ ]]; then
        echo "exiting"
        exit 1
    fi

    echo "installing icon"
    run "${SUDO[@]}" mkdir -p "$icondir"
    run "${SUDO[@]}" cp "$ICON" "$final_icon"

    # Desktop entries go to /usr/share/applications/ for system visibility.
    # --rebuild-mime-info-cache is not the default, and without it the MimeType=
    # associations are ignored until something else refreshes the cache.
    echo "installing desktop entry to $appsdir"
    run "${SUDO[@]}" mkdir -p "$appsdir"
    run "${SUDO[@]}" desktop-file-install --dir="$appsdir" --rebuild-mime-info-cache \
        --set-key=Exec --set-value="$final_exec" \
        --set-key=Icon --set-value="$final_icon" \
        "$DESKTOP"

    # Same entry on the Desktop, from the same command, so the two copies cannot
    # drift apart. No sudo: it belongs to the user. It needs the exec bit to be
    # launchable by double-click.
    echo "installing desktop entry to $deskdir"
    run mkdir -p "$deskdir"
    run desktop-file-install --dir="$deskdir" -m 755 \
        --set-key=Exec --set-value="$final_exec" \
        --set-key=Icon --set-value="$final_icon" \
        "$DESKTOP"

    echo "moving payload to $appdir"
    run "${SUDO[@]}" mkdir -p "$(dirname "$appdir")"
    # -T ensures destination treated as a normal target path, not dir merge
    run "${SUDO[@]}" mv -T "$PAYLOAD" "$appdir"

    if (( DRY_RUN )); then
        echo ""
        echo "dry run: nothing above was executed"
    else
        echo ""
        echo "installed $APPNAME. Verify with:"
        # strip the desktop field codes; they are not shell arguments
        echo "  ${final_exec%% %[FfUu]}"
        echo "  gtk-launch $(basename "${DESKTOP%.desktop}")"
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
autodetect_components

echo ""
echo "App:      $APPNAME"
echo "Desktop:  ${DESKTOP:-<not found>}"
echo "Icon:     ${ICON:-<not found>}"
echo "Exe:      ${EXE:-<not found>}"
echo ""

if [[ -f ${DESKTOP:-} && -f ${ICON:-} && -f ${EXE:-} ]]; then
    read -r -p "Use these? [Y/n] " ans
    [[ $ans =~ ^[Nn]$ ]] && choose_components_manually
else
    echo "could not autodetect all three, pick them manually"
    choose_components_manually
fi

for f in "$DESKTOP" "$ICON" "$EXE"; do
    if [[ ! -f $f ]]; then
        echo "not a file: $f"
        exit 1
    fi
done

install_appimage
