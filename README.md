# iReport 5.6.0 en CachyOS / Arch (Wayland)

iReport 5.6.0 (Jaspersoft, 2014) adaptado para correr en un Linux moderno con sesión **Wayland** (KDE Plasma), sin instalar Java viejo en el sistema ni cambiar a una sesión X11.

## Uso rápido

```bash
sudo pacman -S xpra xorg-server-xvfb xorg-xauth
./setup.sh          # descarga el JDK 7 embebido en ./jre (una sola vez)
./ireport-x11.sh    # abre iReport
```

## AppImage

Un solo archivo con iReport + JDK 7 + lanzador. El sistema solo necesita `xpra xorg-server-xvfb xorg-xauth`.

Descargarlo de las Releases del repo:

```bash
gh release download -R axelroman-dev/ireport-5.6.0-cachyos -p '*.AppImage'
chmod +x iReport-5.6.0-x86_64.AppImage
./iReport-5.6.0-x86_64.AppImage
```

Construirlo (genera `dist/iReport-5.6.0-x86_64.AppImage`; `build/` y `dist/` no se versionan):

```bash
./build-appimage.sh
```

Publicar una versión nueva:

```bash
gh release create v5.6.0-N dist/iReport-5.6.0-x86_64.AppImage --title "iReport 5.6.0 (build N)" --notes "..."
```

## Problemas y soluciones

| Problema | Causa | Solución |
|---|---|---|
| No arranca con el Java del sistema | iReport (NetBeans 6.5) solo funciona con **Java 7** | JDK 7 propio en `jre/` (Azul Zulu 7u352), descargado por `setup.sh` con verificación SHA-256. `etc/ireport.conf` usa `jdkhome="jre"` |
| Ventana en blanco en Wayland (también pasaba en Kubuntu Wayland) | Java 7 + XWayland | Se ejecuta en un **servidor X11 propio y aislado** con **Xpra** en modo *seamless*: cada ventana de iReport aparece como ventana normal de KDE (redimensionable, maximizable) |
| Cuelgue/NPE al iniciar con un diálogo vacío | El módulo `heartbeat` busca actualizaciones en `ireport.sf.net` (ya no existe) y su diálogo falla | Módulo desactivado en `ireport/config/Modules/com-jaspersoft-ireport-heartbeat.xml` |
| Driver MySQL | Los conectores 8.x requieren Java 8+ | `setup.sh` copia `libs/mysql-connector-java-5.1.49.jar` a `jre/jre/lib/ext/` (siempre en el classpath, sin configurarlo en iReport). Funciona con MySQL 5.x y 8.0. Clase: `com.mysql.jdbc.Driver` |

Se probó y descartó **Xephyr + Openbox** (X11 anidado en una ventana): funciona, pero al redimensionar la ventana no se ajusta la pantalla interna (recorta o deja bordes negros).

## Archivos propios de este repo

- `setup.sh` — descarga/verifica el JDK 7 y coloca el driver MySQL.
- `build-appimage.sh` — arma el AppDir (archivos versionados + `jre/` + `AppRun` + `.desktop` + icono extraído de `core_ireport.jar`) y lo empaqueta con `appimagetool`.
- `ireport-x11.sh` — lanzador:
  - busca un display libre y arranca `xpra` con `Xvfb` (5120x2880 virtual) y iReport como proceso hijo; todo se cierra al cerrar iReport;
  - abre la ventana principal en **1920x1080 centrada** (ajusta `~/.ireport/5.6.0/config/Windows2Local/WindowManager.wswmgr`); se cambia con `WIN_W`/`WIN_H` en el script;
  - arranca iReport desde `$HOME` y con `--jdkhome` absoluto a `jre/`;
  - el log de Xpra va a `~/.ireport/5.6.0/var/log/xpra.log`; para verlo en la terminal: `IREPORT_DEBUG=1 ./ireport-x11.sh`.
- `etc/ireport.conf` — `jdkhome="jre"`, `-Xmx1024m`, suavizado de fuentes.

## Datos útiles

- Configuración del usuario y logs de iReport: `~/.ireport/5.6.0/` (`var/log/messages.log`).
- Si cambias módulos o algo no se aplica, borra la caché: `rm -rf ~/.ireport/5.6.0/var/cache`.
- Si los paneles quedan desordenados: *Window → Reset Windows*.
- Los avisos de `xkbcomp`, `dbus`, `pulseaudio`, `vp9` y `fgrep` en el log son normales.
- Portapapeles entre iReport y otras apps: lo sincroniza Xpra.

## Pendiente

- Lanzador `.desktop` para el menú de KDE.

## Licencias

iReport: ver `LICENSE_ireport.txt`, `notice.txt` y `Third-Party-Notices.pdf`. Azul Zulu (no incluido en el repo, se descarga): GPLv2 con Classpath Exception.
