import QtQuick
import "../theme"

Item {
    implicitWidth: 24
    implicitHeight: 24
    // Two folded strokes: a small, code-native mark for Velum.
    Rectangle {
        width: 5; height: 19; radius: 2
        x: 6; y: 3; rotation: -25
        color: Theme.accent
    }
    Rectangle {
        width: 5; height: 24; radius: 2
        x: 15; y: 0; rotation: 25
        color: Theme.text
    }
}
