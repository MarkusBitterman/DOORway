import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls

/**
 * A progress bar with both ends rounded and text acts as clipping like OneUI 7's battery indicator.
 */
ProgressBar {
    id: root
    property bool vertical: false
    property real valueBarWidth: 30
    property real valueBarHeight: 18
    property color highlightColor: Appearance?.colors.colOnSecondaryContainer ?? "#685496"
    property color trackColor: ColorUtils.transparentize(highlightColor, 0.5) ?? "#F1D3F9"
    property alias radius: contentItem.radius
    property string text
    default property Item textMask: Item {
        width: valueBarWidth
        height: valueBarHeight
        StyledText {
            anchors.centerIn: parent
            font: root.font
            text: root.text
        }
    }

    // Qt6: default property Item does not auto-set the visual parent.
    // OpacityMask (like the original) reads from layer.enabled texture without
    // redirecting the item's own visual rendering, so the mask stays visible.
    onTextMaskChanged: {
        if (textMask) {
            textMask.parent = root
            textMask.layer.enabled = true
        }
    }

    text: Math.round(value * 100)
    font {
        pixelSize: 13
        weight: text.length > 2 ? Font.Medium : Font.DemiBold
    }

    background: Item {
        implicitHeight: valueBarHeight
        implicitWidth: valueBarWidth
    }

    contentItem: Rectangle {
        id: contentItem
        anchors.fill: parent
        radius: 9999
        color: root.trackColor
        visible: false
        layer.enabled: true

        Rectangle {
            id: progressFill
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                right: undefined
            }
            width: parent.width * root.visualPosition
            height: parent.height

            states: State {
                name: "vertical"
                when: root.vertical
                AnchorChanges {
                    target: progressFill
                    anchors {
                        top: undefined
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                    }
                }
                PropertyChanges {
                    target: progressFill
                    width: parent.width
                    height: parent.height * root.visualPosition
                }
            }

            radius: Appearance.rounding.unsharpen
            color: root.highlightColor
        }
    }

    Rectangle {
        id: roundingShape
        visible: false
        layer.enabled: true
        width: contentItem.width
        height: contentItem.height
        radius: contentItem.radius
    }

    // Stage 1: clip contentItem to rounded ends
    OpacityMask {
        id: roundingMask
        anchors.fill: parent
        source: contentItem
        maskSource: roundingShape
        visible: false
        layer.enabled: true
    }

    // Stage 2: punch text-shaped cutout through the rounded bar
    OpacityMask {
        anchors.fill: parent
        source: roundingMask
        maskSource: root.textMask
        invert: true
    }
}
