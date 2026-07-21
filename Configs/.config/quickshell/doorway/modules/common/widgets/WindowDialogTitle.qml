import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

StyledText {
    text: "Dialog Title"
    // Tracked uppercase monospace — the boardroom's header voice (cf. SYSTEMS/LOG),
    // not the Material serif title. Fixed hud token, mode-independent.
    color: DoorwayPalette.hudText
    wrapMode: Text.Wrap
    font {
        family: Appearance.font.family.monospace
        pixelSize: Appearance.font.pixelSize.large
        letterSpacing: 2
    }
}
