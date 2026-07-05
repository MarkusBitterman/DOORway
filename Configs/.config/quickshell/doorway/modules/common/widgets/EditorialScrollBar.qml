import QtQuick
import QtQuick.Controls
import qs.modules.common

/**
 * A slim ink scrollbar for the magazine page — the paper counterpart to
 * StyledScrollBar (which uses Material surface tones). Same proven structure,
 * only thinner and inked, so it reads as a pencil mark down the margin.
 */
ScrollBar {
    id: root

    policy: ScrollBar.AsNeeded
    topPadding: Appearance.rounding.normal
    bottomPadding: Appearance.rounding.normal
    active: hovered || pressed

    contentItem: Rectangle {
        implicitWidth: 3
        implicitHeight: root.visualSize
        radius: width / 2
        color: Editorial.inkMuted

        opacity: root.policy === ScrollBar.AlwaysOn || (root.active && root.size < 1.0) ? 0.55 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 350
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }
    }
}
