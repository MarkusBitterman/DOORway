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
    buttonRadius: Appearance.rounding.verysmall
    buttonRadiusPressed: Math.max(2, Appearance.rounding.verysmall - 2)
    colBackground: DoorwayPalette.plasticPanelTop   // recessed plastic key
    colBackgroundHover: Qt.lighter(DoorwayPalette.plasticPanelTop, 1.18)

    contentItem: StyledText {
        text: buttonText
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance.font.pixelSize.larger
        color: DoorwayPalette.agedPaper
    }

    StyledToolTip {
        text: tooltipText
        extraVisibleCondition: tooltipText.length > 0
    }
}