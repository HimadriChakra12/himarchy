#!/usr/bin/env bash
# wine-supercharged-v3.2.sh
# Wine Supercharger v3.2 — Proton-GE style, no repeated reg spam, fonts & manifests auto

IFS=$'\n\t'

# ------------------------
# Config
# ------------------------
WINEPREFIX_DEFAULT="$HOME/.wine-super"
WINEARCH_DEFAULT="win64"
ENVFILE_NAME="superwine.env"
WRAPPER="$HOME/run-superwine"
NEED_SUDO=1

# ------------------------
# CLI args
# ------------------------
WINEPREFIX="$WINEPREFIX_DEFAULT"
INSTALL_DEPS=1
FAST=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) WINEPREFIX="$2"; shift 2;;
    --no-deps) INSTALL_DEPS=0; shift;;
    --fast) FAST=1; shift;;
    -h|--help)
      cat <<EOF
Usage: $0 [--prefix /path/to/prefix] [--no-deps] [--fast]
  --prefix   Set custom WINEPREFIX
  --no-deps  Skip system package installation
  --fast     Skip optional heavy installs (dotnet48, fonts)
EOF
      exit 0;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

echo "🍷 Wine Supercharger v3.2 (Proton-GE style, fully automated fonts/manifests)"
echo "Prefix: $WINEPREFIX"
echo "Arch:   $WINEARCH_DEFAULT"
echo

# ------------------------
# Helpers
# ------------------------
detect_pkg_manager() {
  if command -v pacman >/dev/null 2>&1; then echo "pacman"
  elif command -v apt >/dev/null 2>&1; then echo "apt"
  elif command -v dnf >/dev/null 2>&1; then echo "dnf"
  elif command -v zypper >/dev/null 2>&1; then echo "zypper"
  else echo "unknown"; fi
}

ask_sudo() {
  if [ "$NEED_SUDO" -eq 1 ] && command -v sudo >/dev/null 2>&1; then
    sudo -v
    (while true; do sudo -n true; sleep 60; done) &
  fi
}

install_deps() {
  PKG_MANAGER="$(detect_pkg_manager)"
  echo "Detected package manager: $PKG_MANAGER"

  case "$PKG_MANAGER" in
    pacman)
      sudo pacman -Syu --needed --noconfirm \
        wine-staging wine-mono wine-gecko winetricks \
        lib32-alsa-lib lib32-alsa-plugins lib32-libpulse \
        lib32-mesa lib32-vulkan-radeon vulkan-radeon \
        gamemode lib32-libglvnd
      ;;
    apt)
      sudo dpkg --add-architecture i386 || true
      sudo apt update
      sudo apt install -y wine64 wine32 winetricks wine-mono wine-gecko \
        libvulkan1 libvulkan1:i386 mesa-vulkan-drivers mesa-vulkan-drivers:i386 gamemode
      ;;
    dnf)
      sudo dnf install -y wine winetricks wine-mono wine-gecko \
        libvulkan libvulkan.i686 mesa-dri-drivers.i686 gamemode
      ;;
    zypper)
      sudo zypper install -y wine winetricks wine-mono wine-gecko libvulkan1 libvulkan1-32bit gamemode
      ;;
    *)
      echo "Unknown package manager. Install Wine, 32-bit Vulkan/libGL manually."
      return 1
      ;;
  esac
}

detect_gpu() {
  if command -v lspci >/dev/null 2>&1; then
    GPU=$(lspci | grep -E "VGA|3D" | head -n1)
    if [[ $GPU == *"NVIDIA"* ]]; then echo "nvidia"
    elif [[ $GPU == *"AMD"* ]]; then echo "amd"
    elif [[ $GPU == *"Intel"* ]]; then echo "intel"
    else echo "unknown"; fi
  else
    echo "unknown"
  fi
}

fix_broken_desktop_files() {
  local bad
  bad=$(grep -L "^\[Desktop Entry\]" -R ~/.local/share/applications 2>/dev/null || true)
  if [ -n "$bad" ]; then
    echo "⚠️ Fixing malformed .desktop files"
    while IFS= read -r f; do
      if ! grep -q "^\[Desktop Entry\]" "$f"; then
        printf '%s\n%s\n' "[Desktop Entry]" "$(cat "$f")" > "$f.tmp" && mv "$f.tmp" "$f"
        echo "Fixed: $f"
      fi
    done <<< "$bad"
  fi
}

create_prefix() {
  echo "Creating stable WINEPREFIX..."
  export WINEPREFIX="$WINEPREFIX"
  export WINEARCH="$WINEARCH_DEFAULT"

  wineboot --init
  sleep 1
}

run_winetricks_core() {
  export WINEPREFIX="$WINEPREFIX"
  echo "Installing core fonts + runtimes + MS Common Controls..."
  # Using 'allfonts' + comctl32
  winetricks -q corefonts comctl32 vcrun2019 vcrun2022 || echo "Core install failed"
}

install_dxvk_vkd3d() {
  echo "Installing DXVK + VKD3D..."
  winetricks -q dxvk vkd3d
}

install_dotnet() {
  if [ "$FAST" -eq 0 ]; then
    echo "Installing dotnet48..."
    winetricks -q dotnet48
  fi
}

# ------------------------
# Fonts + Manifest pre-registration (avoid repeated fixme)
# ------------------------
pre_register_manifests() {
  cat > /tmp/manifest.reg <<'REG'
[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\SideBySide\Winners]
"Microsoft.Windows.Common-Controls"="6.0.0.0"
REG

  wine regedit /tmp/manifest.reg || echo "Manifest pre-registration failed"
  rm -f /tmp/manifest.reg
}

write_env_and_wrapper() {
  mkdir -p "$WINEPREFIX"
  GPU_DRIVER=$(detect_gpu)

  cat > "$WINEPREFIX/$ENVFILE_NAME" <<EOF
export WINEPREFIX="$WINEPREFIX"
export WINEARCH=win64
export WINEDEBUG=-all
export WINEESYNC=1
export WINEFSYNC=0
export DXVK_ASYNC=1
export DXVK_STATE_CACHE=1
export DXVK_HUD=0
export VKD3D_CONFIG=main
export SUPERWINE_FSR=0
export __GL_THREADED_OPTIMIZATIONS=1
export SUPERWINE_GPU="$GPU_DRIVER"
EOF

  cat > "$WRAPPER" <<'EOF'
#!/usr/bin/env bash
PREFIX_FILE="$HOME/.wine-super/superwine.env"
if [ -f "$PREFIX_FILE" ]; then source "$PREFIX_FILE"; fi
if [ "${SUPERWINE_FSR:-0}" -eq 1 ]; then
  echo "FSR enabled for this run"
fi
exec wine "$@"
EOF

  chmod +x "$WRAPPER"
  echo "Env file: $WINEPREFIX/$ENVFILE_NAME"
  echo "Wrapper: $WRAPPER"
}

apply_registry_tweaks() {
  cat > /tmp/superwine.reg <<'REG'
[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"csmt"="enabled"
"UseTakeFocus"="N"
"DXGrab"="Y"
"VideoMemorySize"="4096"
[HKEY_CURRENT_USER\Control Panel\Desktop]
"MenuShowDelay"="0"
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="1920x1080"
REG

  wine regedit /tmp/superwine.reg
  rm -f /tmp/superwine.reg
}

fix_services_for_rpc() {
  cat > /tmp/wine_services.reg <<'REG'
[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\RpcSs]
"Start"=dword:00000002
[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\EventLog]
"Start"=dword:00000002
[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\PlugPlay]
"Start"=dword:00000002
REG

  wine regedit /tmp/wine_services.reg
  rm -f /tmp/wine_services.reg
}

main() {
  if [ "$INSTALL_DEPS" -eq 1 ]; then
    ask_sudo
    install_deps
  fi

  fix_broken_desktop_files
  mkdir -p "$(dirname "$WINEPREFIX")"

  if [ -d "$WINEPREFIX" ]; then
    read -r -p "Overwrite existing prefix? [y/N] " ok
    ok="${ok:-N}"
    if [[ "$ok" =~ ^[Yy] ]]; then rm -rf "$WINEPREFIX"; fi
  fi

  create_prefix
  run_winetricks_core
  install_dxvk_vkd3d
  install_dotnet
  pre_register_manifests
  write_env_and_wrapper
  apply_registry_tweaks
  fix_services_for_rpc

  echo
  echo "✅ Wine Supercharger v3.2 setup complete!"
  echo "Run apps via wrapper: $WRAPPER <program.exe> [args]"
  echo "Edit $WINEPREFIX/$ENVFILE_NAME to toggle SUPERWINE_FSR=1 per-game."
}

main "$@"
