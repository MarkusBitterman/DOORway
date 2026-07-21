import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

/**
 * Material 3 dialog button. See https://m3.material.io/components/dialogs/overview
 */
RippleButton {
    id: root

    property string buttonText
    padding: 14
    implicitHeight: 36
    implicitWidth: buttonTextWidget.implicitWidth + padding * 2
    // Squared corners — a flat text command in the boardroom hairline language,
    // not a Material pill. Fixed hud tokens (mode-independent over the dialog card).
    buttonRadius: 3

    property color colEnabled: DoorwayPalette.hudText
    property color colDisabled: DoorwayPalette.hudTextDim
    colBackground: "transparent"
    colBackgroundHover: DoorwayPalette.hudHover
    colRipple: DoorwayPalette.hudHoverStrong
    property alias colText: buttonTextWidget.color

    contentItem: StyledText {
        id: buttonTextWidget
        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        text: buttonText
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance?.font.pixelSize.small ?? 12
        color: root.enabled ? root.colEnabled : root.colDisabled

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

}
