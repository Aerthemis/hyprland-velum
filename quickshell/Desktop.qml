pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "components"
import "components/system"
import "services"
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
            property bool dashboardOpen: false
            property string systemPage: ""
            SystemControls { id: controls; page: panel.systemPage }
            HyprlandFocusGrab {
                id: popupFocusGrab
                active: panel.dashboardOpen || panel.systemPage.length > 0
                windows: [panel, dashboardWindow, systemPopup]
                onCleared: {
                    panel.dashboardOpen = false;
                    panel.systemPage = "";
                }
            }
            Connections {
                target: Hyprland
                function onRawEvent(event) {
                    if ((panel.dashboardOpen || panel.systemPage.length > 0)
                            && (event.name === "activewindow" || event.name === "activewindowv2")) {
                        panel.dashboardOpen = false;
                        panel.systemPage = "";
                    }
                }
            }
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
                dashboardOpen: panel.dashboardOpen
                systemPage: panel.systemPage
                systemStatus: controls.view
                onWorkspaceRequested: workspace => {
                    Hyprland.dispatch("focusmonitor " + panel.screen.name);
                    Hyprland.dispatch("workspace " + workspace);
                }
                onDashboardRequested: { panel.dashboardOpen = !panel.dashboardOpen; }
                onSystemRequested: page => { panel.dashboardOpen = false; panel.systemPage = panel.systemPage === page ? "" : page; }
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
                id: systemPopup
                anchor.window: panel
                anchor.rect.x: Math.max(0, panel.width - width - 8)
                anchor.rect.y: panel.height + 10
                implicitWidth: 330
                implicitHeight: systemCard.implicitHeight
                visible: panel.systemPage.length > 0
                color: "transparent"
                SystemControlCard {
                    id: systemCard
                    anchors.fill: parent
                    page: panel.systemPage
                    status: controls.view
                    error: controls.error
                    busy: controls.busy
                    onActionRequested: (action, values) => action === "refresh" ? controls.refresh() : controls.act(action, values)
                    onCloseRequested: panel.systemPage = ""
                }
            }
        }
    }
}
