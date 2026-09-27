# Estado del proyecto: Scarlett macOS Port

## Última actualización
2026-08-08 — Fase 2 y 3 completas: SET clock/rate reales, empaquetado .app, validado con hardware

## Estado global
| Fase | Estado | % |
|------|--------|---|
| 1 — Daemon USB | **Completa** | 100% |
| 2 — GUI nativa | **Completa** | 100% |
| 3 — Features 6i6 | **Completa** | 100% |

## Log (resumen reciente)

- [x] Fase 1 completa: daemon USB con todos los GET/SET verificados (ver abajo)
- [x] GUI SwiftUI nativa (`fase-2-gui/scarlett-app`, paquete swift, 600+ líneas)
- [x] Rediseño UI oscuro (rojo/granate, estilos ScarlettUI, meter bars, faders)
- [x] Estudio del repo de referencia `Nas3nmann/scarlett-mixcontrol-1stgen` (MixControl CE, 1ª gen)
  - Patrón portado: snapshots JSON (modelo + panel + export/import ⌘S/⌘O), held peaks (~4 dB/s),
    auto-reconnect de estado, save-to-hardware (flash)
  - No aplica: byte tables de 1ª gen, acceso USB directo `IOUSBDeviceInterface` (1ª gen)
- [x] Presets: `ScarlettPreset` Codable, guardado en UserDefaults + fichero `.6i6.json`, carga empuja routing+64 gains matrix+preamp+master al hardware
- [x] Held-peak meters: `meterHold` decae 4 dB/s; línea blanca en `MeterBar`
- [x] Auto-reconnect: tras 25 fails de polling (2.5s) → disconnected + retry cada 1s con `lastError` visible
- [x] TopBar con estado de conexión, botón Presets (sheet) y Save to hardware
- [x] `SET save` raw en el cliente (`saveToHardwareAsync`)
- [x] **Daemon v0.2.0 robusto** (fase-1-daemon/src/main.c):
  - SIGPIPE ignorado — clientes que mueren a mitad respuesta ya no matan el daemon
  - Watchdog thread: reintenta `scarlett_usb_open` cada 1s si no hay device; con 5+ fallos USB seguidos cierra y reabre el handle
  - `cmd_handler` con mutex `g_dev_lock` + contador de fallos (`ERR ctl` / `ERR no device`)
- [x] **Daemon embebido en la app** (DaemonManager.swift): la app lanza el daemon como subproceso si el socket no responde
  - Búsqueda: env `SCARLETT_DAEMON` → ruta relativa al ejecutable (dev) → bundle Resources → `~/.scarlett/`
  - Respawn automático si muere (máx 3, cooldown 2s); mensaje diferenciado "binary not found" vs "keeps crashing"
  - Quit limpio: `applicationWillTerminate` + cerrar ventana termina la app (`applicationShouldTerminateAfterLastWindowClosed`) → `daemon.shutdown()`
- [x] Verificado sin hardware: spawn al lanzar app (pid 98654→99530), respawn tras `kill -9`, daemon sobrevive a clientes descorteses (SIGPIPE)
- [x] **SET clock + SET rate** (daemon `cmd_set_clock`/`cmd_set_rate`): `SET clock internal|spdif|adat` (wValue 0x0100 wIdx 0x2800), `SET rate 44100|48000|88200|96000` (0x2900 LE32). **Probado con hardware real**: 44100→48000→44100 ✓ + LIST actualizado
- [x] **UI en ClockPanelView**: pickers para Rate (44.1/48/88.2/96 kHz) y Clock (Internal/S/PDIF/ADAT) con refresh
- [x] **Reset de hold por doble-clic** en MeterBar (channel + master)
- [x] **Empaquetado `.app`**: `fase-2-gui/package.sh` → `dist/Scarlett 6i6 Mixer.app` (Info.plist, daemon en Resources, codesign ad-hoc). DaemonManager ya busca en bundle Resources
- [x] **Hardware reconectado durante la sesión**: watchdog del daemon lo abrió solo, la app se reconectó sola

## Fase 1 — Comandos verificados contra Scarlett 6i6 real

### GET
- `clock` → S/PDIF ✓ · `rate` → 44100 Hz ✓ · `sync` → Locked ✓
- `meters` → 4 canales activos ✓ · `volume` → dB ✓ · `mute` ✓
- `impedance:N` ✓ · `pad:N` ✓ · `gain:N` ✓ · `matrix:N` ✓ · `matrix:N.M` ✓
- `output:N` ✓ · `capture:N` ✓

### SET
- `volume dB` ✓ · `mute on|off` ✓ · `impedance:N line|hi-z` (LED) ✓ · `pad:N` (LED parpadea) ✓
- `gain:N lo|hi` ✓ · `matrix:N src` ✓ · `matrix:N.M gain` ✓ · `output:N src` ✓ · `capture:N src` ✓
- `save` → OK saved ✓

- [x] **Auto-recovery MIDIServer en daemon** (`usb-io.mm`): si `IOUSBHostDevice` falla al abrir con exclusive lock, mata `MIDIServer` automáticamente y reintenta de inmediato.
- [x] **Corrección de fórmula de nodos de matriz en daemon** (`main.c`): `(in << 3) | (mix & 7)` de acuerdo al hardware Scarlett 6i6 1ª Gen.
- [x] **Codificación de ganancia de matriz en 16-bit signed**: Scarlett Gen 1 requiere `(int16_t)(dB * 256)` (dB en byte alto, fracción en byte bajo). Corregido el bug donde se enviaba en el byte bajo y el hardware quedaba siempre a 0 dB sin mutear.
- [x] **Cache de estado en daemon para registros write-only**: El firmware de Scarlett Gen 1 devuelve 0 en `GET_CUR` para multiplexores de salida/captura y ganancias de matriz (comportamiento idéntico al driver ALSA Linux). El daemon mantiene ahora `g_output_mux_cache`, `g_capture_mux_cache` y `g_matrix_gain_cache`.
- [x] **Protección física contra bucles de feedback**: Multiplexores de captura bloqueados a entradas físicas analógicas y SPDIF (12..17). Imposible realimentar la salida del Mac/DAW en la entrada de grabación.
- [x] **Mute, Solo y Faders reales y funcionales**: Los botones `M`, `S`, y faders de cada canal (incluyendo Guitarra en Input 1 y Mac/Spotify en DAW 1/2) aplican silenciado (-128 dB) y headroom seguro (-12 dB por defecto) directamente en la matriz DSP del hardware.
- [x] **Selector rápido de monitorización en TopBar**: `DAW / GarageBand` (PCM 1-2), `Direct Guitar` (latencia cero), `Mix 1 (DSP)`.
- [x] **Strips de reproducción integrados**: Canal estéreo unificado **`DAW 1-2`** con vúmetros duales L/R independientes, fader sincronizado, perilla de balance estéreo, Mute, Solo y PFL para controlar la música/reproducción del Mac con un solo control.
- [x] **Menú de Routing con nombres amigables**: `DAW 1/2`, `Input 1..4`, `Mix 1..3 L/R` en lugar de índices crudos.

## Fase 1 — Comandos verificados contra Scarlett 6i6 real

### GET
- `clock` → S/PDIF ✓ · `rate` → 44100 Hz ✓ · `sync` → Locked ✓
- `meters` → 4 canales activos ✓ · `volume` → dB ✓ · `mute` ✓
- `impedance:N` ✓ · `pad:N` ✓ · `gain:N` ✓ · `matrix:N` ✓ · `matrix:N.M` ✓
- `output:N` ✓ · `capture:N` ✓

### SET
- `volume dB` ✓ · `mute on|off` ✓ · `impedance:N line|hi-z` (LED) ✓ · `pad:N` (LED parpadea) ✓
- `gain:N lo|hi` ✓ · `matrix:N src` ✓ · `matrix:N.M gain` ✓ · `output:N src` ✓ · `capture:N src` ✓
- `save` → OK saved ✓

## Pendiente / problemas conocidos

- **Bug resuelto: teclado no escribía en los TextField** — la app se lanzaba como binario desnudo (sin Info.plist) y macOS la trataba como `.accessory`: ventanas nunca key → ratón OK, teclado muerto. Fix: `setActivationPolicy(.regular)` en `applicationDidFinishLaunching` + `NSApp.activate(ignoringOtherApps:)`.
- **Panel Presets usa `NativeTextField`** (NSTextField vía NSViewRepresentable) + popover cacheado en @State del ContentView (los repaints 10 Hz del polling no recrean el panel ni roban el foco).
- **Bug resuelto: MIDIServer bloqueaba el dispositivo USB** — Ahora `usb-io.mm` mata `MIDIServer` automáticamente y reabre sin intervención manual.

## Cómo lanzar

- Daemon: `fase-1-daemon/build/scarlett-daemon` (socket `/tmp/scarlett-6i6.sock`)
- App: `open "/Applications/Scarlett 6i6 Mixer.app"`
- Log app: `/tmp/scarlett-app-crash.log`