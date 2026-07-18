import qs.modules.common
import qs.modules.common.widgets
import QtQuick

RippleButton {
    id: button
    property string buttonText: ""
    property string tooltipText: ""
    property bool forceCircle: false

    implicitHeight: 30
    implicitWidth: forceCircle ? implicitHeight : (contentItem.implicitWidth + 10 * 2)
    Behavior on implicitWidth {
        SmoothedAnimation {
            velocity: Appearance.animation.elementMove.velocity
        }
    }

    background.anchors.fill: button
    rippleEnabled: false  // mechanical press, not Material ripple
    buttonRadius: 3
    buttonRadiusPressed: 2
    colBackground: "transparent"
    colBackgroundHover: Qt.rgba(1, 1, 1, 0.07)

    contentItem: StyledText {
        text: buttonText.toUpperCase()
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance.font.pixelSize.small
        font.family: Appearance.font.family.monospace
        font.letterSpacing: 1
        color: DoorwayPalette.hudText
    }

    StyledToolTip {
        text: tooltipText
        extraVisibleCondition: tooltipText.length > 0
    }
}
