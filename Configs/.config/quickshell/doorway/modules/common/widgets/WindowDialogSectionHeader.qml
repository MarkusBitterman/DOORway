import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

StyledText {
    text: "Section"
    // Sub-rule label in the boardroom voice — dim tracked mono, like a panel caption.
    color: DoorwayPalette.hudLabel
    font {
        family: Appearance.font.family.monospace
        pixelSize: Appearance.font.pixelSize.smaller
        letterSpacing: 1.5
    }
}
