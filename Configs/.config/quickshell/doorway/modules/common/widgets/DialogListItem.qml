import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

RippleButton {
    id: root
    property bool active: false

    horizontalPadding: Appearance.rounding.large
    verticalPadding: 12

    clip: true
    pointingHandCursor: !active    
    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + verticalPadding * 2
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    // Boardroom data-table row: transparent ground, sky wash when the row is the
    // active/current entry or hovered, hairline divider below. Fixed hud tokens.
    colBackground: active ? DoorwayPalette.hudHover : "transparent"
    colBackgroundHover: DoorwayPalette.hudHover
    colRipple: DoorwayPalette.hudHoverStrong
    buttonRadius: 0

    Rectangle { // row divider
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: DoorwayPalette.hudLine
    }
}
