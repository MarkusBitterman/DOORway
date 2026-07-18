import qs.modules.common
import qs.modules.common.functions
import qs.services
import QtQuick
import Quickshell.Services.Notifications

RippleButton {
    id: button
    property string buttonText
    property string urgency
    // Boardroom (sidebar) styling: faint sky wash instead of raised plastic.
    property bool hud: false
    readonly property bool critical: urgency == NotificationUrgency.Critical

    implicitHeight: 34
    leftPadding: 15
    rightPadding: 15
    rippleEnabled: false  // mechanical key, not Material ripple
    buttonRadius: hud ? 3 : Appearance.rounding.verysmall
    buttonRadiusPressed: hud ? 2 : Math.max(2, Appearance.rounding.verysmall - 2)
    // Raised plastic keys sitting on the recessed card; critical actions glow red.
    colBackground: critical ? ColorUtils.transparentize(DoorwayPalette.redBright, 0.82) :
        hud ? Qt.rgba(DoorwayPalette.skyHint.r, DoorwayPalette.skyHint.g, DoorwayPalette.skyHint.b, 0.10) :
        DoorwayPalette.plasticShellTop
    colBackgroundHover: critical ? ColorUtils.transparentize(DoorwayPalette.redBright, 0.68) :
        hud ? Qt.rgba(DoorwayPalette.skyHint.r, DoorwayPalette.skyHint.g, DoorwayPalette.skyHint.b, 0.18) :
        Qt.lighter(DoorwayPalette.plasticShellTop, 1.18)

    contentItem: StyledText {
        horizontalAlignment: Text.AlignHCenter
        text: buttonText
        color: critical ? DoorwayPalette.redBright :
            button.hud ? DoorwayPalette.hudText : DoorwayPalette.agedPaper
    }
}