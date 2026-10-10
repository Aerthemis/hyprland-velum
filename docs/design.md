# First stone

Velum starts with a familiar horizontal bar and its own visual language. The
goal is a desktop we can understand and maintain one component at a time.

## Visual vocabulary

- **System mark:** the detected Linux distribution logo from Nerd Font glyphs,
  with Velum's two-tone 9×9 V as the fallback; Nerd Font [includes Font Logos](https://github.com/ryanoasis/nerd-fonts#glyph-sets).
- **Iris, Sage, Clay:** three restrained accent options on warm neutral surfaces.
- **Moonlight and Daybreak:** dark and light palettes with readable text.
- **Space Grotesk + Google Sans Flex:** distinctive display type, quieter controls.
- **Compact bar:** 34 px, edge-to-edge, JetBrains Mono Nerd Font labels, a
  detected distribution logo, numbered workspace controls and a clock pinned to screen center. The
  right edge borrows Omarchy's system-control grouping while keeping Velum's own
  mark and palette. The clock opens the dashboard; each system icon opens its
  control panel. Registered tray apps appear as a dynamic icon strip beside the
  system controls. Reference: [Omarchy's top bar](https://omarchy.org/manual/the-top-bar/).
- **Rounded panels:** 20–24 px panels, 12 px buttons, thin borders.
- **Brief motion:** 180 ms transitions for selection, surfaces and panels.
- **Contour wallpaper:** original curves drawn in QML; no bundled photo or artwork.

The preview deliberately shares its actual bar, dashboard and system-control
components with live mode. It can evolve without changing the daily desktop.

## Architecture

Keep compositor integration in Desktop.qml and future service adapters.
Components receive values and emit intent signals. They should not execute
shell commands or import another dotfiles project's modules.

Theme.qml is the single source of visual tokens. Theme persistence will be added
as a separate user-state concern, outside tracked source files.

## Next milestones

1. Refine the bar together: spacing, workspace behavior and accent palette.
2. Add a keyboard-first launcher.
3. Bring the existing custom Screens backend into this project, with a Velum UI.
4. Add clipboard history and the clear-all action without importing private data.
5. Build explicit installation and per-machine configuration for the new laptop.

## Clock dashboard

Caelestia's dashboard informs the grouping of clock, calendar, media, weather and
resource cards. Velum implements its own Overview, Media, Performance and Weather
views, sharing one animated overlay between preview and live mode. The panel
stays centered beneath the clock, uses rounded theme surfaces, and stacks cards
on narrow screens. Keyboard focus stays in the live overlay until it closes.

MPRIS provides media metadata and controls. A Python standard-library helper
reads Linux metrics and retrieves opt-in Open-Meteo weather. Polling runs only
while open; an in-flight weather request may finish after closing. Location
settings belong to per-user XDG configuration, never tracked source files.
The month calendar is date navigation only; appointments are future work.

Automatic display profiles and the independent Python rollback watchdog should
remain separate from the shell's visuals. A UI failure must not prevent restoring
a usable display layout.

System controls use Nerd Font glyphs rendered by JetBrains Mono Nerd Font. A
Python standard-library adapter runs only explicit actions and reads status
from existing desktop services; absent services leave controls unavailable.
The network indicator reflects Wi-Fi signal or an Ethernet connection, and its
panel lists scanned networks. Wi-Fi activation is limited to saved
NetworkManager profiles, open networks, or protected personal networks after a
password prompt. Enterprise Wi-Fi needs an existing profile. Brightness and
power-profile actions depend on machine support and permissions.
