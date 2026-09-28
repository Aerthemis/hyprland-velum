pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "components"
import "theme"

Scope {
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            property var monitor: Hyprland.monitorFor(screen)
            property bool appearanceOpen: false
            property bool dashboardOpen: false
            anchors { top: true; left: true; right: true }
            margins { top: 0; left: 0; right: 0 }
            implicitHeight: Theme.barHeight
            color: "transparent"
            Bar {
                anchors.fill: parent
                activeWorkspace: panel.monitor?.activeWorkspace?.id ?? 1
                occupiedWorkspaces: Hyprland.workspaces.values.filter(w => w.id > 0).map(w => w.id)
                workspaceIds: {
                    const active = panel.monitor?.activeWorkspace?.id ?? 1;
                    const start = active > 0 ? Math.floor((active - 1) / 5) * 5 + 1 : 1;
                    return [start, start + 1, start + 2, start + 3, start + 4];
                }
                windowTitle: Hyprland.activeToplevel?.title ?? ""
                timeText: Qt.formatDateTime(clock.date, "HH:mm")
                dateText: Qt.formatDateTime(clock.date, "ddd, d MMM")
                appearanceOpen: panel.appearanceOpen
                dashboardOpen: panel.dashboardOpen
                onWorkspaceRequested: workspace => {
                    Hyprland.dispatch("focusmonitor " + panel.screen.name);
                    Hyprland.dispatch("workspace " + workspace);
                }
                onAppearanceRequested: { panel.dashboardOpen = false; panel.appearanceOpen = !panel.appearanceOpen; }
                onDashboardRequested: { panel.appearanceOpen = false; panel.dashboardOpen = !panel.dashboardOpen; }
            }
            PanelWindow {
                id: dashboardWindow
                screen: panel.screen
                visible: panel.dashboardOpen
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: 0
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: panel.dashboardOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                DashboardOverlay {
                    anchors.fill: parent
                    open: panel.dashboardOpen
                    onCloseRequested: panel.dashboardOpen = false
                }
            }
            PopupWindow {
                anchor.window: panel
                anchor.rect.x: Math.max(0, panel.width - width)
                anchor.rect.y: panel.height + 10
                implicitWidth: 310
                implicitHeight: appearance.implicitHeight
                visible: panel.appearanceOpen
                color: "transparent"
                AppearanceCard {
                    id: appearance
                    anchors.fill: parent
                    onCloseRequested: panel.appearanceOpen = false
                }
            }
        }
    }
}
