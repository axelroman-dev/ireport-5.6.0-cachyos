#!/bin/bash
# Ejecuta iReport en su propio servidor X11 aislado mediante Xpra (modo seamless):
# cada ventana de iReport aparece como una ventana normal del escritorio Wayland.
# Requiere: xpra xorg-server-xvfb xorg-xauth
# IREPORT_DEBUG=1 muestra el log de Xpra en la terminal.

APPDIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# Proceso hijo dentro de Xpra: arrancar iReport desde el home del usuario
if [ "$1" = "--child" ]; then
    shift
    cd "$HOME" || exit 1
    exec "$APPDIR/bin/ireport" --jdkhome "$APPDIR/jre" "$@"
fi
USERDIR="$HOME/.ireport/5.6.0"
WIN_W=1920
WIN_H=1080

for cmd in xpra Xvfb xauth; do
    command -v "$cmd" >/dev/null || { echo "Falta '$cmd': sudo pacman -S xpra xorg-server-xvfb xorg-xauth" >&2; exit 1; }
done

# Tamaño inicial de la ventana principal: 1920x1080 centrada
WSMGR="$USERDIR/config/Windows2Local/WindowManager.wswmgr"
if [ -f "$WSMGR" ]; then
    read -r SW SH < <(xdpyinfo 2>/dev/null | awk '/dimensions:/ { split($2, d, "x"); print d[1], d[2] }')
    X=$(( (${SW:-$WIN_W} - WIN_W) / 2 )); [ $X -lt 0 ] && X=0
    Y=$(( (${SH:-$WIN_H} - WIN_H) / 2 )); [ $Y -lt 0 ] && Y=0
    # Solo el primer bloque (joined-properties de main-window)
    sed -i "0,/^\/>/{
        s/^   x=\"[0-9-]*\"/   x=\"$X\"/
        s/^   y=\"[0-9-]*\"/   y=\"$Y\"/
        s/^   width=\"[0-9]*\"/   width=\"$WIN_W\"/
        s/^   height=\"[0-9]*\"/   height=\"$WIN_H\"/
        s/^   frame-state=\"[0-9]*\"/   frame-state=\"0\"/
    }" "$WSMGR"
fi

# Buscar un número de display libre
D=10
while [ -e "/tmp/.X11-unix/X$D" ] || [ -e "/tmp/.X$D-lock" ]; do D=$((D + 1)); done

LOG="$USERDIR/var/log/xpra.log"
mkdir -p "$(dirname "$LOG")"
[ -z "$IREPORT_DEBUG" ] && exec >"$LOG" 2>&1

exec xpra start ":$D" \
    --start-child="$(printf '%q ' "$APPDIR/ireport-x11.sh" --child "$@")" \
    --xvfb="Xvfb +extension Composite +extension RANDR +extension RENDER -screen 0 5120x2880x24+32 -nolisten tcp -noreset -dpi 96" \
    --exit-with-children=yes \
    --ssh-upgrade=no \
    --attach=yes \
    --daemon=no \
    --splash=no \
    --tray=no \
    --notifications=no \
    --mdns=no \
    --html=off \
    --webcam=no \
    --speaker=no \
    --microphone=no \
    --printing=no \
    --systemd-run=no
