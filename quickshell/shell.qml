//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import Quickshell

ShellRoot {
    LazyLoader {
        active: true
        source: Quickshell.env("VELUM_MODE") === "bar" ? "Desktop.qml" : "Preview.qml"
    }
}
