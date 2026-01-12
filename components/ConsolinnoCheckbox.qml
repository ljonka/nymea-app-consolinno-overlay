import QtQuick 2.5
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Nymea 1.0

CheckBox {
    id: root
    
    indicator: Rectangle {
        implicitWidth: 20
        implicitHeight: 20
        radius: 3
        border.color: root.checked ? Style.switchOnColor : Style.switchBagroundColor
        color: root.checked ? Style.switchOnColor : "transparent"

        Rectangle {
            width: 10
            height: 10
            x: 5
            y: 5
            radius: 2
            color: "white"
            visible: root.checked
        }
    }

    contentItem: Label {
        text: root.text
        font: root.font
        opacity: root.enabled ? 1.0 : 0.3
        color: Style.foregroundColor
        verticalAlignment: Text.AlignVCenter
        leftPadding: root.indicator.width + root.spacing
    }
}
