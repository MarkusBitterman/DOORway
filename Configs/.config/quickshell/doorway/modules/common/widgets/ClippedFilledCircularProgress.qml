import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property int implicitSize: 18
    property int lineWidth: 2
    property real value: 0
    property color colPrimary: Appearance?.colors.colOnSecondaryContainer ?? "#685496"
    property color colSecondary: ColorUtils.transparentize(colPrimary, 0.5) ?? "#F1D3F9"
    property bool enableAnimation: true
    property int animationDuration: 800
    property var easingType: Easing.OutCubic
    default property Item textMask: Item {
        width: implicitSize
        height: implicitSize
        StyledText {
            anchors.centerIn: parent
            text: Math.round(root.value * 100)
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    property real degree: value * 360
    property real arcRadius: root.implicitSize / 2 - root.lineWidth / 2 - 0.5

    Behavior on degree {
        enabled: root.enableAnimation
        NumberAnimation {
            duration: root.animationDuration
            easing.type: root.easingType
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.colSecondary
            strokeWidth: root.lineWidth
            fillColor: "transparent"

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: -90
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: root.colPrimary
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: -90
                sweepAngle: root.degree
            }
        }
    }
}
