import qs.modules.common
import qs.modules.common.widgets
import QtQuick

/**
 * A Material symbol rendered as if engraved INTO the surface: a dark symbolic face with a
 * light catch-light on its lower-right lip (groove lit from above). Used for the bar's
 * right-cluster status glyphs, which sit directly on the walnut. When `lit` they burn red
 * like an LED instead of reading as a dark engraving.
 */
Item {
    id: root
    property string text: ""
    property real iconSize: Appearance.font.pixelSize.larger
    property real fill: 0
    property bool lit: false

    // Engraved (idle) vs lit (LED) faces.
    property color faceColor: DoorwayPalette.inkBlack
    property color litColor: DoorwayPalette.ledRed
    property color highlightColor: Qt.rgba(1, 1, 1, 0.30) // lower-lip catch light
    property real depth: 1

    readonly property color _face: lit ? litColor : faceColor

    implicitWidth: main.implicitWidth
    implicitHeight: main.implicitHeight

    // Lower-right catch light — hidden when lit so the LED reads clean.
    MaterialSymbol {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.depth
        anchors.verticalCenterOffset: root.depth
        text: root.text
        iconSize: root.iconSize
        fill: root.fill
        color: root.highlightColor
        visible: !root.lit
    }

    MaterialSymbol {
        id: main
        anchors.centerIn: parent
        text: root.text
        iconSize: root.iconSize
        fill: root.fill
        color: root._face
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }
}
