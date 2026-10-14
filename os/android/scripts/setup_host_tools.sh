#!/bin/bash
# Host shader tools the gta4-native override cache needs at build time.
#   - DXC: the copy bundled in tools/XenosRecomp (1.8.2407) crashes on the
#     Bink pixel shaders, so a newer official release is used.
#   - glslangValidator: GLSL overrides (motion blur).
#   - spirv-val ships with the NDK and needs no download.
# Everything lands in out/host-tools inside the repository.
set -euo pipefail
. "$(dirname "$0")/env.sh"
DEST="$REPO/out/host-tools"
DXC_BASE="https://github.com/microsoft/DirectXShaderCompiler/releases/download/v1.9.2609"
GLSLANG_BASE="https://github.com/KhronosGroup/glslang/releases/download/16.6.0"
mkdir -p "$DEST"
cd "$DEST"

case "$HOST_OS" in
  windows)
    if [ ! -x dxc/bin/x64/dxc.exe ]; then
      curl -fsSL -o dxc.zip "$DXC_BASE/dxc_2026_09_29.zip"
      # The archive uses backslash separators, which unzip mangles.
      powershell -NoProfile -Command "Expand-Archive -Force dxc.zip dxc"
    fi
    if [ ! -x glslang/bin/glslangValidator.exe ]; then
      curl -fsSL -o glslang.zip "$GLSLANG_BASE/glslang-16.6.0-windows-x86_64-release.zip"
      unzip -q -o glslang.zip -d glslang
      cp glslang/bin/glslang.exe glslang/bin/glslangValidator.exe
    fi
    DXC_BIN=dxc/bin/x64/dxc.exe
    ;;
  linux)
    [ "$(uname -m)" = "x86_64" ] || { echo "!! host tools are only fetched for x86_64 Linux"; exit 1; }
    if [ ! -x dxc/bin/dxc ]; then
      curl -fsSL -o dxc.tar.gz "$DXC_BASE/linux_dxc_2026_09_28.x86_x64.tar.gz"
      rm -rf dxc && mkdir -p dxc
      tar -xzf dxc.tar.gz -C dxc
    fi
    if [ ! -x glslang/bin/glslangValidator ]; then
      curl -fsSL -o glslang.tar.gz "$GLSLANG_BASE/glslang-16.6.0-linux-x86_64-release.tar.gz"
      rm -rf glslang && mkdir -p glslang
      tar -xzf glslang.tar.gz -C glslang
      # Older releases name the binary glslang only.
      [ -e glslang/bin/glslangValidator ] || cp glslang/bin/glslang glslang/bin/glslangValidator
    fi
    DXC_BIN=dxc/bin/dxc
    ;;
  *)
    echo "!! unsupported host OS for the bundled shader tools: $HOST_OS"
    exit 1
    ;;
esac
LD_LIBRARY_PATH="$DEST/dxc/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$DEST/$DXC_BIN" --version
"$DEST/glslang/bin/glslangValidator$EXE" --version | head -1
