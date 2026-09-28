pragma ComponentBehavior: Bound
import QtQuick
import "../theme"

Item {
    id: root
    property string symbol: "velum"
    property color color: Theme.text
    property color accent: Theme.accent
    readonly property var patterns: ({
        velum: ["110000011", "110000011", "011000110", "011000110", "001101100", "001101100", "000111000", "000111000", "000010000"],
        moon: ["000111000", "001110000", "011100000", "111000000", "111000000", "111000001", "011100011", "001111110", "000111100"],
        sun: ["000010000", "010000010", "000111000", "001111100", "101111101", "001111100", "000111000", "010000010", "000010000"],
        palette: ["001111100", "011111110", "110101011", "111111111", "110111011", "111111111", "011110000", "001110000", "000110000"]
    })
    readonly property var rows: patterns[symbol] || patterns.velum
    readonly property int cellSize: Math.max(1, Math.floor(Math.min(width, height) / 9))
    implicitWidth: 18
    implicitHeight: 18
    Item {
        width: 9 * root.cellSize
        height: width
        anchors.centerIn: parent
        Repeater {
            model: 81
            Rectangle {
                required property int index
                readonly property int column: index % 9
                readonly property int row: Math.floor(index / 9)
                x: column * root.cellSize
                y: row * root.cellSize
                width: root.cellSize
                height: root.cellSize
                visible: root.rows[row][column] === "1"
                color: root.symbol === "velum" && column < 4 ? root.accent : root.color
                antialiasing: false
            }
        }
    }
}
