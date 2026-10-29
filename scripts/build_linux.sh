#!/usr/bin/env bash
# Compila o app Flutter para Linux desktop com a versao gerada pela data/hora
# da compilacao (formato yy.DDD.HHmm).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# 1. Gera a versao com base na data/hora atual
source "$SCRIPT_DIR/generate_version.sh"

# 2. Resolve dependencias
flutter pub get

# 3. Compila para Linux injetando a versao gerada via --build-name
flutter build linux --build-name="$VERSION"

echo "Build concluido: build/linux/x64/release/bundle/sound_labels (versao $VERSION)"
