#!/bin/bash
# Construye dist/iReport-5.6.0-x86_64.AppImage con iReport, el JDK 7 embebido y el lanzador Xpra.
# En el sistema donde se ejecute el AppImage hacen falta: xpra xorg-server-xvfb xorg-xauth
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
BUILD="$REPO/build"
APPDIR="$BUILD/iReport.AppDir"
OUT="$REPO/dist/iReport-5.6.0-x86_64.AppImage"
TOOL="$BUILD/appimagetool-x86_64.AppImage"
TOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"

cd "$REPO"
[ -x jre/bin/java ] || ./setup.sh

rm -rf "$APPDIR"
mkdir -p "$APPDIR/app" "$(dirname "$OUT")"

# Archivos versionados (sin los del repo) + el JDK
git ls-files -z -- . ':!.gitignore' ':!README.md' ':!build-appimage.sh' ':!setup.sh' \
    | xargs -0 cp --parents -t "$APPDIR/app"
cp -a jre "$APPDIR/app/"

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/app/ireport-x11.sh" "$@"
EOF
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/ireport.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=iReport 5.6.0
Comment=Diseñador de reportes JasperReports
Exec=ireport
Icon=ireport
Categories=Development;Office;
Terminal=false
EOF

# Icono: frame48_ireport.gif del branding de iReport, convertido a PNG con el propio JDK
ICON_JAR="ireport/core/locale/core_ireport.jar"
unzip -p "$ICON_JAR" org/netbeans/core/startup/frame48_ireport.gif > "$BUILD/icon.gif"
cat > "$BUILD/Gif2Png.java" <<'EOF'
public class Gif2Png {
    public static void main(String[] a) throws Exception {
        javax.imageio.ImageIO.write(javax.imageio.ImageIO.read(new java.io.File(a[0])), "png", new java.io.File(a[1]));
    }
}
EOF
jre/bin/javac -d "$BUILD" "$BUILD/Gif2Png.java"
jre/bin/java -cp "$BUILD" Gif2Png "$BUILD/icon.gif" "$APPDIR/ireport.png"
ln -sf ireport.png "$APPDIR/.DirIcon"

if [ ! -x "$TOOL" ]; then
    curl -fL --progress-bar -o "$TOOL" "$TOOL_URL"
    chmod +x "$TOOL"
fi

rm -f "$OUT"
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$TOOL" --no-appstream "$APPDIR" "$OUT"
ls -lh "$OUT"
