pragma Singleton
import QtQuick

QtObject {
    property bool light: false
    property int accentIndex: 0
    readonly property var accents: ["#c5aff1", "#b4d1be", "#efbea4"]
    readonly property color accent: accents[accentIndex]
    readonly property color background: light ? "#eee9f2" : "#15131c"
    readonly property color surface: light ? "#faf7fc" : "#25212f"
    readonly property color raised: light ? "#e8e0ef" : "#332d3f"
    readonly property color text: light ? "#30273d" : "#eee8f5"
    readonly property color muted: light ? "#776a85" : "#afa3bd"
    readonly property color line: light ? "#d9cfe2" : "#44394f"
    readonly property color ink: "#30223f"
    readonly property string font: "Google Sans Flex"
    readonly property string displayFont: "Space Grotesk"
    readonly property string barFont: "JetBrainsMono Nerd Font"
    readonly property int barHeight: 34
    readonly property int radius: 20
    readonly property int motion: 180
}
