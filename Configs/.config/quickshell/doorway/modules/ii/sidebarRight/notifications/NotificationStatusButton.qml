import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

// Boardroom footer control for the notification log — hairline hud language,
// with the silence toggle lit in gold when engaged.
HudKey {
    id: button
    property string buttonIcon: ""
    property string buttonText: ""

    baseHeight: 36
    baseWidth: content.implicitWidth + 46
    clickedWidth: baseWidth + 6

    showLed: buttonIcon !== "" && enabled
    property color colText: toggled ? DoorwayPalette.hudText : DoorwayPalette.hudTextDim

    contentItem: Item {
        id: content
        anchors.fill: parent
        implicitWidth: contentRowLayout.implicitWidth
        implicitHeight: contentRowLayout.implicitHeight
        RowLayout {
            id: contentRowLayout
            anchors.centerIn: parent
            spacing: 5
            MaterialSymbol {
                visible: buttonIcon !== ""
                text: buttonIcon
                iconSize: Appearance.font.pixelSize.huge
                color: button.colText
            }
            StyledText {
                visible: buttonText !== ""
                text: buttonText
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.family: Appearance.font.family.monospace
                color: button.colText
            }
        }
    }

}
