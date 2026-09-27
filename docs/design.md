# First stone

Velum starts with a familiar horizontal bar and its own visual language. The
goal is a desktop we can understand and maintain one component at a time.

## Visual vocabulary

- **Folded mark:** two strokes forming a small V.
- **Iris, Sage, Clay:** three restrained accent options on warm neutral surfaces.
- **Moonlight and Daybreak:** dark and light palettes with readable text.
- **Space Grotesk + Google Sans Flex:** distinctive display type, quieter controls.
- **Rounded surfaces:** 20–24 px panels, 12 px buttons, thin borders.
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

Automatic display profiles and the independent Python rollback watchdog should
remain separate from the shell's visuals. A UI failure must not prevent restoring
a usable display layout.
