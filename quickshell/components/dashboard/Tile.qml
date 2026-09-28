import QtQuick
import "../../theme"

Rectangle {
    id: root
    default property alias content: body.data
    implicitHeight: body.childrenRect.height + 36
    color: Theme.raised
    radius: 18
    Item {
        id: body
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
    }
}
