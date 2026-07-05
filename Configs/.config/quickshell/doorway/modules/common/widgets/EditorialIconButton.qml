import qs.modules.common
import qs.modules.common.widgets
import QtQuick

/**
 * A bare ink glyph button for the magazine page — the paper counterpart to
 * ToolbarButton (a RippleButton). Renders a Material Symbol as plain ink Text
 * (ligature lookup), darkening on hover, with no ripple and no filled pill.
 */
Item {
    id: root
    property string symbol
    property string tooltip: ""
    property int glyphSize: 20
    signal clicked()

    implicitWidth: 28
    implicitHeight: 28

    StyledText {
        anchors.centerIn: parent
        text: root.symbol
        font.family: Appearance.font.family.iconMaterial
        font.pixelSize: root.glyphSize
        color: ma.containsMouse ? Editorial.ink : Editorial.inkMuted
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()

        StyledToolTip {
            text: root.tooltip
            extraVisibleCondition: root.tooltip.length > 0 && ma.containsMouse
        }
    }
}
