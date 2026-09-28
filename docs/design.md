# First stone

Velum starts with a familiar horizontal bar and its own visual language. The
goal is a desktop we can understand and maintain one component at a time.

## Visual vocabulary

- **Pixel mark:** a two-tone V on a 9×9 grid, with Nerd Font day/night and theme controls.
- **Iris, Sage, Clay:** three restrained accent options on warm neutral surfaces.
- **Moonlight and Daybreak:** dark and light palettes with readable text.
- **Space Grotesk + Google Sans Flex:** distinctive display type, quieter controls.
- **Compact bar:** 34 px, edge-to-edge, JetBrains Mono Nerd Font labels, left-aligned workspaces
  with accent underlines and a clock pinned to screen center. Inspired by
  [Omarchy](https://omarchy.org/manual/the-top-bar/), with Velum’s own mark and palette.
- **Rounded panels:** 20–24 px panels, 12 px buttons, thin borders.
- **Brief motion:** 180 ms transitions for selection, surfaces and panels.
- **Contour wallpaper:** original curves drawn in QML; no bundled photo or artwork.

The preview deliberately shares its actual bar and appearance components with
live mode. It can evolve without changing the daily desktop.

## Architecture

Keep compositor integration in Desktop.qml and future service adapters.
Components receive values and emit intent signals. They should not execute
shell commands or import another dotfiles project's modules.

Theme.qml is the single source of visual tokens. Theme persistence will be added
as a separate user-state concern, outside tracked source files.

## Next milestones

1. Refine the bar together: spacing, workspace behavior and accent palette.
2. Add live battery and audio controls, then tray and a keyboard-first launcher.
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

Bar controls use Omarchy’s Nerd Font glyph mappings: `󰔎` for day/night and
`󰸌` for appearance, rendered by JetBrainsMono Nerd Font. The V remains Velum’s
own mark. Reference: [Omarchy’s menu](https://github.com/omacom/omarchy/blob/v3.0.0/bin/omarchy-menu).
