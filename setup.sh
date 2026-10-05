#!/bin/bash
# Descarga el JDK 7 embebido (Azul Zulu) en ./jre y añade el driver MySQL compatible.
set -euo pipefail

APPDIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
ZULU="zulu7.56.0.11-ca-jdk7.0.352-linux_x64"
URL="https://cdn.azul.com/zulu/bin/$ZULU.tar.gz"
SHA256="8a7387c1ed151474301b6553c6046f865dc6c1e1890bcf106acc2780c55727c8"
MYSQL_JAR="mysql-connector-java-5.1.49.jar"

cd "$APPDIR"

if [ ! -x jre/bin/java ]; then
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT
    echo "Descargando $ZULU..."
    curl -fL --progress-bar -o "$TMP/jdk.tar.gz" "$URL"
    echo "$SHA256  $TMP/jdk.tar.gz" | sha256sum -c -
    tar xzf "$TMP/jdk.tar.gz" -C "$TMP"
    mv "$TMP/$ZULU" jre
fi

cp "libs/$MYSQL_JAR" jre/jre/lib/ext/
jre/bin/java -version

for cmd in xpra Xvfb xauth; do
    command -v "$cmd" >/dev/null || MISSING=1
done
[ -n "${MISSING:-}" ] && echo "Falta instalar: sudo pacman -S xpra xorg-server-xvfb xorg-xauth"
echo "Listo. Ejecuta: $APPDIR/ireport-x11.sh"
