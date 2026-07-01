import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: button
    property string day
    property int isToday
    property bool bold

    Layout.fillWidth: false
    Layout.fillHeight: false
    implicitWidth: 38; 
    implicitHeight: 38;

    toggled: (isToday == 1)
    rippleEnabled: false  // mechanical, not Material
    buttonRadius: Appearance.rounding.verysmall
    buttonRadiusPressed: Math.max(2, Appearance.rounding.verysmall - 2)
    // Today is a single lit gold key; other days are flat cells with a faint hover.
    colBackground: "transparent"
    colBackgroundHover: Qt.rgba(1, 1, 1, 0.07)
    colBackgroundToggled: DoorwayPalette.powerGold
    colBackgroundToggledHover: Qt.lighter(DoorwayPalette.powerGold, 1.1)

    contentItem: StyledText {
        anchors.fill: parent
        text: day
        horizontalAlignment: Text.AlignHCenter
        font.weight: bold ? Font.DemiBold : Font.Normal
        color: (isToday == 1) ? DoorwayPalette.inkBlack :
            (isToday == 0) ? Appearance.colors.colOnLayer1 :
            Appearance.colors.colOutlineVariant

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }
}

