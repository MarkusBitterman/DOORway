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

    // Bulb gradient colors — center brightens and edge rises from transparent as usage climbs
    readonly property color _gradCenter: Qt.rgba(
        accentColor.r * (0.3 + 0.7 * percentage),
        accentColor.g * (0.3 + 0.7 * percentage),
        accentColor.b * (0.3 + 0.7 * percentage),
        0.95
    )
    readonly property color _gradEdge: Qt.rgba(
        accentColor.r * 0.45 * percentage,
        accentColor.g * 0.45 * percentage,
        accentColor.b * 0.45 * percentage,
        percentage * 0.85
    )
    readonly property color _bgColor: Qt.rgba(
        accentColor.r * 0.08,
        accentColor.g * 0.08,
        accentColor.b * 0.08,
        0.45
    )
    readonly property bool glowGauges: (Config.options.bar?.glow?.enable ?? false)
        && (Config.options.bar?.glow?.applyToGauges ?? false)
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

        Item {
            id: gaugeContainer
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 20
            implicitHeight: 20

            // Neon glow ring behind the gauge, in this resource's own accent color
            // (or error red when over threshold). Sits behind the progress circle.
            Loader {
                active: root.glowGauges
                anchors.fill: parent
                sourceComponent: Item {
                    anchors.fill: parent
                    Rectangle {
                        id: glowRing
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: root.warning ? Appearance.colors.colError : root.accentColor
                    }
                    NeonGlow {
                        target: glowRing
                        glowColor: root.warning ? Appearance.colors.colError : root.accentColor
                    }
                }
            }

            ClippedFilledCircularProgress {
                id: resourceCircProg
                anchors.fill: parent
                value: percentage
                implicitSize: 20
                colPrimary:        root.accentColor
                colSecondary:      root._bgColor
                colGradientCenter: root.warning ? Appearance.colors.colError
                                                : root._gradCenter
                colGradientEdge:   root.warning ? ColorUtils.transparentize(Appearance.colors.colError, 0.6)
                                                : root._gradEdge
                enableAnimation: false

                Item {
                    anchors.centerIn: parent
                    width: resourceCircProg.implicitSize
                    height: resourceCircProg.implicitSize
                    layer.enabled: true

                    MaterialSymbol {
                        anchors.centerIn: parent
                        font.weight: Font.DemiBold
                        fill: 1
                        text: iconName
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
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
