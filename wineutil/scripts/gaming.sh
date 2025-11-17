#!/usr/bin/env bash
# Gaming Profile

set -e
PROFILE_DIR="$HOME/wine_profiles/gaming"
WRAPPER="$PROFILE_DIR/run-superwine"

mkdir -p "$PROFILE_DIR"

WINEPREFIX="$PROFILE_DIR/prefix"
WINEARCH="win64"

echo "🎮 Setting up Gaming profile..."
echo "WINEPREFIX: $WINEPREFIX"
echo "WINEARCH: $WINEARCH"

# Initialize prefix if not exist
if [ ! -d "$WINEPREFIX" ]; then
    wineboot --init
    sleep 2
fi

# Install DXVK, corefonts, and optional vkd3d
winetricks -q corefonts dxvk vkd3d || echo "Some components may already be installed"

# Write the run-superwine wrapper
cat > "$WRAPPER" <<'EOF'
#!/usr/bin/env bash

PREFIX_FILE="$HOME/wine_profiles/gaming/superwine.env"
if [ -f "$PREFIX_FILE" ]; then
    source "$PREFIX_FILE"
fi

export WINVER=win10
if [ ! -f "$WINEPREFIX/.winver_fixed" ]; then
    winetricks -q settings win10 >/dev/null 2>&1
    touch "$WINEPREFIX/.winver_fixed"
fi

RESOLUTION=""
FULLSCREEN=1
FSR=1
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --res) RESOLUTION="$2"; shift 2;;
        --nofullscreen) FULLSCREEN=0; shift;;
        --fsr) FSR="$2"; shift 2;;
        *) ARGS+=("$1"); shift;;
    esac
done

if [[ -z "$RESOLUTION" && ${#ARGS[@]} -gt 0 ]]; then
    echo "🎮 Select resolution:"
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

export WINEPREFIX
export WINEARCH
export WINEDEBUG
export DXVK_HUD
export DXVK_STATE_CACHE
export SUPERWINE_GPU
export SUPERWINE_FSR=$FSR
export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/intel_icd.x86_64.json"
export VK_LAYER_PATH="/usr/share/vulkan/explicit_layer.d"

if [[ $FULLSCREEN -eq 1 ]]; then
    export DXVK_FULLSCREEN=1
else
    export DXVK_FULLSCREEN=0
    export WINE_FULLSCREEN_WIDTH=$WIDTH
    export WINE_FULLSCREEN_HEIGHT=$HEIGHT
fi

echo "Launching game with:"
echo "  Resolution: $RESOLUTION"
echo "  Fullscreen: $FULLSCREEN"
echo "  FSR: $FSR"
echo "  Windows Mode: Win10"
echo

exec wine "${ARGS[@]}"
EOF

chmod +x "$WRAPPER"
echo "✅ Gaming profile ready. Use: $WRAPPER <program.exe> [args]"

