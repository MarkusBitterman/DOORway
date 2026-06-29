import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property string iconName
    required property double percentage
    property color accentColor: Appearance.colors.colOnSecondaryContainer
    property int warningThreshold: 100
    property bool shown: true

    // Segmented LED meter (NES block vocabulary) — discrete blocks lit by usage. Legible
    // and unmistakably retro, in this resource's own accent hue (error red over threshold).
    property int segments: 5
    readonly property color _dim: ColorUtils.transparentize(accentColor, 0.8)
    readonly property color _litColor: warning ? Appearance.colors.colError : accentColor
    clip: true
    visible: width > 0 && height > 0
    implicitWidth: resourceRowLayout.x < 0 ? 0 : resourceRowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
    property bool warning: percentage * 100 >= warningThreshold

    RowLayout {
        id: resourceRowLayout
        spacing: 2
        x: shown ? 0 : -resourceRowLayout.width
        anchors {
            verticalCenter: parent.verticalCenter
        }

        // Icon — legible, carrying the resource's accent hue (no obscuring ring).
        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 3
            font.weight: Font.DemiBold
            fill: 1
            text: iconName
            iconSize: Appearance.font.pixelSize.larger
            color: root._litColor
        }

        // Segmented LED meter — blocks light up left→right with usage.
        RowLayout {
            id: meter
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            Repeater {
                model: root.segments
                delegate: Rectangle {
                    required property int index
                    implicitWidth: 3
                    implicitHeight: 12
                    radius: 1
                    color: (index < Math.round(root.percentage * root.segments)) ? root._litColor : root._dim
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: fullPercentageTextMetrics.width
            implicitHeight: percentageText.implicitHeight

            TextMetrics {
                id: fullPercentageTextMetrics
                text: "100"
                font.pixelSize: Appearance.font.pixelSize.small
            }

            StyledText {
                id: percentageText
                anchors.centerIn: parent
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                text: `${Math.round(percentage * 100).toString()}`
            }
        }

        Behavior on x {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: resourceRowLayout.x >= 0 && root.width > 0 && root.visible
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
}
