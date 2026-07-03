import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Shapes

/**
 * A single resource gauge — a Jarvis/HUD ring: the resource icon sits in a bright
 * softly-flickering core, ringed by segmented arcs that swirl around it. Load drives
 * both motion and light: heavier usage spins the arcs faster and burns everything
 * brighter and steadier; an idle gauge drifts slowly and flickers dull.
 *
 * Public API is unchanged from the former LED-meter version so BarContent/Resources
 * wiring is untouched: iconName, percentage (0..1), accentColor, warningThreshold, shown.
 */
Item {
    id: root
    required property string iconName
    required property double percentage
    property color accentColor: Appearance.colors.colOnSecondaryContainer
    property int warningThreshold: 100
    property bool shown: true

    readonly property bool warning: percentage * 100 >= warningThreshold
    readonly property color activeColor: warning ? Appearance.colors.colError : accentColor

    property int diameter: Math.min(Appearance.sizes.barHeight - 4, 30)

    // --- Load → motion & light mappings ---
    // Spin: idle drifts (~22°/s), full load races (~200°/s). Inner ring counter-rotates.
    readonly property real spinSpeed: 22 + percentage * 178
    // Light: idle is dim (0.32), full load is solid (1.0).
    readonly property real litLevel: 0.32 + percentage * 0.68

    // Per-frame driven state (rotation + organic flicker).
    property real angle: 0
    property real flickerPhase: 0
    property real coreGlow: litLevel

    visible: shown && width > 0
    implicitWidth: shown ? diameter : 0
    implicitHeight: Appearance.sizes.barHeight
    clip: true

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }

    FrameAnimation {
        running: root.visible
        onTriggered: {
            root.angle = (root.angle + root.spinSpeed * frameTime) % 360
            root.flickerPhase += frameTime
            // Organic shimmer from two detuned sines; amplitude grows as load drops so
            // an idle core visibly flickers while a busy one holds bright and steady.
            const shimmer = (Math.sin(root.flickerPhase * 7.3) + Math.sin(root.flickerPhase * 12.9)) * 0.5
            const jitter = (1.0 - root.percentage) * 0.22
            root.coreGlow = Math.max(0.14, Math.min(1.0, root.litLevel + shimmer * jitter))
        }
    }

    Item {
        id: gauge
        width: root.diameter
        height: root.diameter
        anchors.centerIn: parent

        readonly property real cx: width / 2
        readonly property real cy: height / 2

        // --- Outer segmented ring (spins one way) ---
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            transformOrigin: Item.Center
            rotation: root.angle
            opacity: root.litLevel
            ShapePath {
                strokeColor: root.activeColor
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                strokeStyle: ShapePath.DashLine
                dashPattern: [1.6, 2.2] // short arc segments
                PathAngleArc {
                    centerX: gauge.cx; centerY: gauge.cy
                    radiusX: root.diameter / 2 - 1.5
                    radiusY: root.diameter / 2 - 1.5
                    startAngle: 0; sweepAngle: 359.9
                }
            }
        }

        // --- Inner segmented ring (counter-rotates, finer dashes) ---
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            transformOrigin: Item.Center
            rotation: -root.angle * 1.35
            opacity: root.litLevel * 0.85
            ShapePath {
                strokeColor: root.activeColor
                strokeWidth: 1.5
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                strokeStyle: ShapePath.DashLine
                dashPattern: [1, 3]
                PathAngleArc {
                    centerX: gauge.cx; centerY: gauge.cy
                    radiusX: root.diameter / 2 - 6
                    radiusY: root.diameter / 2 - 6
                    startAngle: 0; sweepAngle: 359.9
                }
            }
        }

        // --- Bright flickering core (the icon sits inside it) — a real radial bloom ---
        Shape {
            id: core
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: root.coreGlow
            readonly property real r: root.diameter * 0.30
            ShapePath {
                strokeColor: "transparent"
                fillColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: gauge.cx; centerY: gauge.cy
                    centerRadius: core.r
                    focalX: gauge.cx; focalY: gauge.cy
                    focalRadius: 0
                    GradientStop { position: 0.0; color: ColorUtils.transparentize(root.activeColor, 0.30) }
                    GradientStop { position: 0.65; color: ColorUtils.transparentize(root.activeColor, 0.68) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                startX: gauge.cx + core.r; startY: gauge.cy
                PathAngleArc {
                    centerX: gauge.cx; centerY: gauge.cy
                    radiusX: core.r; radiusY: core.r
                    startAngle: 0; sweepAngle: 360
                }
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: root.iconName
            iconSize: Appearance.font.pixelSize.normal
            fill: 1
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
            opacity: 0.7 + root.litLevel * 0.3
        }
    }
}
