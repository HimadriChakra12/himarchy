#!/usr/bin/env bash
# Photoshop CS6 Profile

set -e
PROFILE_DIR="$HOME/wine_profiles/photoshop"
WRAPPER="$PROFILE_DIR/run-photoshop"

mkdir -p "$PROFILE_DIR"

WINEPREFIX="$PROFILE_DIR/prefix"
WINEARCH="win64"

echo "🖌️ Setting up Photoshop CS6 profile..."
echo "WINEPREFIX: $WINEPREFIX"
echo "WINEARCH: $WINEARCH"

# Initialize prefix if not exist
if [ ! -d "$WINEPREFIX" ]; then
    wineboot --init
    sleep 2
fi

# Install corefonts and necessary components for Photoshop
winetricks -q corefonts gdiplus || echo "Some components may already be installed"

# Create the run wrapper
cat > "$WRAPPER" <<'EOF'
#!/usr/bin/env bash

PREFIX_FILE="$HOME/wine_profiles/photoshop/photoshop.env"
if [ -f "$PREFIX_FILE" ]; then
    source "$PREFIX_FILE"
fi

export WINVER=win10
export WINEDLLOVERRIDES="winex11.drv=b"   # Force XWayland for proper mouse drag
export WINE_HIDE_CURSOR=0                  # Fix selection tool cursor issues
export WINEPREFIX="$HOME/wine_profiles/photoshop/prefix"
export WINEARCH="win64"
export WINEDEBUG=-all

RESOLUTION=""
FULLSCREEN=0
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --res) RESOLUTION="$2"; shift 2;;
        --fullscreen) FULLSCREEN=1; shift;;
        *) ARGS+=("$1"); shift;;
    esac
done

# Ask for resolution if not provided
if [[ -z "$RESOLUTION" && ${#ARGS[@]} -gt 0 ]]; then
    echo "🖌️ Select resolution:"
    echo "1) 1280x720 (720p)"
    echo "2) 1920x1080 (1080p)"
    echo "3) 2560x1440 (1440p)"
    read -rp "Enter choice [1-3, default 2]: " choice
    case "$choice" in
        1) RESOLUTION="1280x720" ;;
        3) RESOLUTION="2560x1440" ;;
        *) RESOLUTION="1920x1080" ;;
    esac
fi

RESOLUTION=${RESOLUTION:-1920x1080}
WIDTH=${RESOLUTION%x*}
HEIGHT=${RESOLUTION#*x}

# Force XWayland and fix mouse grab issues
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
export WINEESYNC=1
export WINEFSYNC=1

# Optional: Photoshop window rules for Hyprland
# (disable animations and maximization requests)
# You can also add these to hyprland.conf if desired

echo "Launching Photoshop CS6 with:"
echo "  Resolution: $RESOLUTION"
echo "  Fullscreen: $FULLSCREEN"
echo "  Windows Mode: Win10"
echo

exec wine "${ARGS[@]}"
EOF

chmod +x "$WRAPPER"
echo "✅ Photoshop profile ready. Use: $WRAPPER photoshop.exe"
