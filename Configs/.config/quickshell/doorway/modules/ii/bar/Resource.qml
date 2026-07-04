import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Shapes

/**
 * A single resource gauge — a Jarvis/HUD dial: the resource icon sits in a bright
 * softly-flickering core, ringed by two overlapping arcs that spin in opposition.
 *   - Outer arc  fills clockwise with usage (empty → full), spinning CW.
 *   - Inner ring is a near-full ring whose missing segment grows with usage, spinning CCW.
 * Load also drives light: heavier usage burns everything brighter and steadier; an idle
 * gauge drifts slowly and flickers dull.
 *
 * Public API is unchanged: iconName, percentage (0..1), accentColor, warningThreshold, shown.
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

    // Shrunk so the dial sits comfortably in the bar.
    property int diameter: Math.min(Appearance.sizes.barHeight - 8, 26)

    // --- Load → motion & light ---
    readonly property real spinSpeed: 20 + percentage * 150   // deg/s, CW outer
    readonly property real litLevel: 0.34 + percentage * 0.66
    // Outer fills with usage; inner is a full ring minus a usage-sized gap (≥25° so the
    // counter-rotation always reads).
    // Writable (not readonly) so the Behaviors below can ease their transitions — the
    // bindings set the target, the Behavior animates the change. A Behavior on a
    // readonly property fails to load and takes the whole shell down.
    property real outerSweep: percentage * 360
    readonly property real innerGap: 25 + percentage * 200
    property real innerSweep: 360 - innerGap

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
    Behavior on outerSweep { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    Behavior on innerSweep { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

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
        readonly property real outerR: root.diameter / 2 - 1.5
        readonly property real innerR: root.diameter / 2 - 4

        // --- Outer arc: fills with usage, spins clockwise ---
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            transformOrigin: Item.Center
            rotation: root.angle
            opacity: root.litLevel
            // Faint full-ring track so an idle (near-empty) dial still reads as a ring.
            ShapePath {
                strokeColor: ColorUtils.transparentize(root.activeColor, 0.82)
                strokeWidth: 2.5
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                PathAngleArc {
                    centerX: gauge.cx; centerY: gauge.cy
                    radiusX: gauge.outerR; radiusY: gauge.outerR
                    startAngle: -90; sweepAngle: 359.9
                }
            }
            ShapePath {
                strokeColor: root.activeColor
                strokeWidth: 2.5
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: gauge.cx; centerY: gauge.cy
                    radiusX: gauge.outerR; radiusY: gauge.outerR
                    startAngle: -90; sweepAngle: root.outerSweep
                }
            }
        }

        // --- Inner ring: full ring minus a usage-sized gap, spins counter-clockwise ---
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            transformOrigin: Item.Center
            rotation: -root.angle * 1.25
            opacity: root.litLevel * 0.9
            ShapePath {
                strokeColor: root.activeColor
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: gauge.cx; centerY: gauge.cy
                    radiusX: gauge.innerR; radiusY: gauge.innerR
                    startAngle: -90; sweepAngle: root.innerSweep
                }
            }
        }

        // --- Bright flickering core (the icon sits inside it) — a real radial bloom ---
        Shape {
            id: core
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: root.coreGlow
            readonly property real r: root.diameter * 0.26
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
            iconSize: Appearance.font.pixelSize.small
            fill: 1
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
            opacity: 0.7 + root.litLevel * 0.3
        }
    }
}
