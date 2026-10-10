pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../theme"

RowLayout {
    id: root
    property var items: SystemTray.items.values
    spacing: 2
    implicitWidth: Math.max(0, root.items.length * 28 - root.spacing)
    implicitHeight: 28

    Repeater {
        model: root.items

        delegate: Item {
            id: trayCell
            required property SystemTrayItem modelData
            implicitWidth: 26
            implicitHeight: 28
            Accessible.name: modelData.tooltipTitle || modelData.title || modelData.id

            IconImage {
                anchors.centerIn: parent
                source: trayCell.modelData.icon
                implicitWidth: 18
                implicitHeight: 18
            }

            Rectangle {
                anchors.fill: parent
                z: -1
                radius: 3
                color: trayMouse.containsMouse || trayMouse.pressed ? Theme.raised : "transparent"
            }

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        trayCell.modelData.activate()
                    else if (mouse.button === Qt.RightButton && trayCell.modelData.hasMenu)
                        trayMenu.open()
                    else if (mouse.button === Qt.MiddleButton)
                        trayCell.modelData.secondaryActivate()
                }

                ToolTip.visible: containsMouse
                ToolTip.text: ([trayCell.modelData.tooltipTitle, trayCell.modelData.tooltipDescription].filter(Boolean).join(" — ")
                        || trayCell.modelData.title || trayCell.modelData.id)
                        + (trayCell.modelData.hasMenu ? " · Right-click for app menu" : " · No app menu")
                ToolTip.delay: 700
            }

            QsMenuAnchor {
                id: trayMenu
                menu: trayCell.modelData.menu
                anchor {
                    adjustment: PopupAdjustment.ResizeY | PopupAdjustment.SlideX
                    item: trayCell
                    gravity: Edges.Bottom
                    edges: Edges.Bottom
                }
            }
        }
    }
}
