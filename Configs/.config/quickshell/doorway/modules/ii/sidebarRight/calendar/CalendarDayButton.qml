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
    // Compact cells — a tighter month grid so the notification log (the sidebar's
    // only fill-height zone) inherits the reclaimed vertical space.
    implicitWidth: 32;
    implicitHeight: 32;

    toggled: (isToday == 1)
    rippleEnabled: false  // mechanical, not Material
    buttonRadius: 3
    buttonRadiusPressed: 2
    // Today is the boardroom's single warm accent — a lit gold cell with ink
    // numerals; other days are flat readout cells with a faint hover.
    colBackground: "transparent"
    colBackgroundHover: Qt.rgba(1, 1, 1, 0.07)
    colBackgroundToggled: DoorwayPalette.powerGold
    colBackgroundToggledHover: Qt.lighter(DoorwayPalette.powerGold, 1.1)

    contentItem: StyledText {
        anchors.fill: parent
        text: bold ? day.toUpperCase() : day
        horizontalAlignment: Text.AlignHCenter
        font.weight: bold ? Font.DemiBold : Font.Normal
        font.family: bold ? Appearance.font.family.monospace : Appearance.font.family.numbers
        font.pixelSize: bold ? Appearance.font.pixelSize.smallest : Appearance.font.pixelSize.small
        // Weekday header row (bold) reads as tracked micro-labels; day numbers are
        // the readout. Out-of-month days recede to a faint hairline tone.
        color: (isToday == 1) ? DoorwayPalette.inkBlack :
            bold ? DoorwayPalette.hudLabel :
            (isToday == 0) ? DoorwayPalette.hudText :
            Qt.rgba(DoorwayPalette.skyHint.r, DoorwayPalette.skyHint.g, DoorwayPalette.skyHint.b, 0.30)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }
}

