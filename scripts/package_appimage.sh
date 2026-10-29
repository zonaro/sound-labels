#!/usr/bin/env bash
# Empacota o build Flutter Linux como AppImage.
# Uso: scripts/package_appimage.sh <versao>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${1:?Informe a versao: scripts/package_appimage.sh <versao>}"

BUNDLE_DIR="build/linux/x64/release/bundle"
APPDIR="AppDir"
APPNAME="sound_labels"

if [ ! -x "$BUNDLE_DIR/$APPNAME" ]; then
  echo "Build nao encontrado em $BUNDLE_DIR. Rode scripts/build_linux.sh primeiro." >&2
  exit 1
fi

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib/$APPNAME"

# Copia o binario e todos os recursos do bundle Flutter para o AppDir
cp "$BUNDLE_DIR/$APPNAME" "$APPDIR/usr/bin/$APPNAME"
cp -r "$BUNDLE_DIR/"* "$APPDIR/usr/lib/$APPNAME/"

# Arquivo .desktop
cat > "$APPDIR/$APPNAME.desktop" <<EOF
[Desktop Entry]
Name=Sound Labels
Comment=Friendly audio device labels and routing for PipeWire Linux desktops.
Exec=$APPNAME
Icon=$APPNAME
Type=Application
Categories=AudioVideo;Audio;
Terminal=false
EOF

# Icone (usa o SVG do projeto se disponivel)
if [ -f "assets/icons/sound-labels.svg" ]; then
  cp "assets/icons/sound-labels.svg" "$APPDIR/$APPNAME.svg"
fi

# Wrapper: o binario do Flutter espera ser executado a partir do seu diretorio
# de recursos. Ajusta para nao quebrar caminhos relativos dentro do AppImage.
cat > "$APPDIR/usr/bin/$APPNAME" <<WRAPPER
#!/usr/bin/env bash
exec "\${APPDIR:-$(dirname "$(readlink -f "\$0")")/..}/usr/lib/$APPNAME/$APPNAME" "\$@"
WRAPPER
chmod +x "$APPDIR/usr/bin/$APPNAME"

echo "AppDir montado em $APPDIR (versao $VERSION)"
echo "Rode: linuxdeploy --appdir $APPDIR --output appimage"
