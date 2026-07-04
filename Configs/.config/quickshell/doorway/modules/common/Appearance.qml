import QtQuick
import Quickshell
import qs.modules.common.functions
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property QtObject m3colors
    property QtObject animation
    property QtObject animationCurves
    property QtObject colors
    property QtObject rounding
    property QtObject font
    property QtObject sizes
    property string syntaxHighlightingTheme

    // Transparency. The quadratic functions were derived from analysis of hand-picked transparency values.
    ColorQuantizer {
        id: wallColorQuant
        property string wallpaperPath: Config.options.background.wallpaperPath
        property bool wallpaperIsVideo: wallpaperPath.endsWith(".mp4") || wallpaperPath.endsWith(".webm") || wallpaperPath.endsWith(".mkv") || wallpaperPath.endsWith(".avi") || wallpaperPath.endsWith(".mov")
        source: Qt.resolvedUrl(wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath)
        depth: 0 // 2^0 = 1 color
        rescaleSize: 10
    }
    property real wallpaperVibrancy: (wallColorQuant.colors[0]?.hslSaturation + wallColorQuant.colors[0]?.hslLightness) / 2
    property real autoBackgroundTransparency: { // y = 0.5768x^2 - 0.759x + 0.2896
        let x = wallpaperVibrancy
        let y = 0.5768 * (x * x) - 0.759 * (x) + 0.2896
        return Math.max(0, Math.min(0.22, y)) - 0.12 * (m3colors.darkmode ? 0 : 1)
    }
    property real autoContentTransparency: 0.9
    property real backgroundTransparency: Config?.options.appearance.transparency.enable ? Config?.options.appearance.transparency.automatic ? autoBackgroundTransparency : Config?.options.appearance.transparency.backgroundTransparency : 0
    property real contentTransparency: Config?.options.appearance.transparency.automatic ? autoContentTransparency : Config?.options.appearance.transparency.contentTransparency

    // DOORway committed signature schemes, seeded from the Nintendo-Power tokens in
    // DoorwayPalette. Two Material mappings mirroring the website's cartridge modes:
    // gray cart (dark) and gold LoZ cart (light). ThemeMode flips the config option
    // that DoorwayPalette.goldCart reads; every consumer follows this one binding.
    m3colors: DoorwayPalette.goldCart ? goldScheme : darkScheme

    readonly property QtObject darkScheme: QtObject {
        property bool darkmode: true
        property bool transparent: false
        // Warm near-black surfaces (a hint of umber) with aged-paper text.
        property color m3background: "#161210"
        property color m3onBackground: DoorwayPalette.agedPaper
        property color m3surface: "#161210"
        property color m3surfaceDim: "#161210"
        property color m3surfaceBright: "#3A2E24"
        property color m3surfaceContainerLowest: "#100D0B"
        property color m3surfaceContainerLow: "#1C1713"
        property color m3surfaceContainer: "#221C17"
        property color m3surfaceContainerHigh: "#2D261F"
        property color m3surfaceContainerHighest: "#383029"
        property color m3onSurface: DoorwayPalette.agedPaper
        property color m3surfaceVariant: "#4A3D2E"
        property color m3onSurfaceVariant: "#DBC9A6"
        property color m3inverseSurface: DoorwayPalette.agedPaper
        property color m3inverseOnSurface: "#2B2620"
        property color m3outline: DoorwayPalette.parchmentSand
        property color m3outlineVariant: "#4A3D2E"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: DoorwayPalette.powerGold
        // Primary = the gold signature warmth.
        property color m3primary: DoorwayPalette.powerGold
        property color m3onPrimary: DoorwayPalette.inkBlack
        property color m3primaryContainer: DoorwayPalette.goldDim
        property color m3onPrimaryContainer: "#FFE08A"
        property color m3inversePrimary: DoorwayPalette.owlUmber
        // Secondary = hero/sky blue.
        property color m3secondary: DoorwayPalette.skyHint
        property color m3onSecondary: "#06203F"
        property color m3secondaryContainer: DoorwayPalette.heroBlue
        property color m3onSecondaryContainer: "#CFE0F6"
        // Tertiary = grassland green.
        property color m3tertiary: DoorwayPalette.grassBright
        property color m3onTertiary: "#0E2A06"
        property color m3tertiaryContainer: "#2E5A1C"
        property color m3onTertiaryContainer: "#C8EFB1"
        // Error = the power-red fire (lifted for legibility on near-black).
        property color m3error: DoorwayPalette.redBright
        property color m3onError: "#3A0002"
        property color m3errorContainer: "#93000A"
        property color m3onErrorContainer: "#FFDAD5"
        property color m3primaryFixed: "#FFE08A"
        property color m3primaryFixedDim: DoorwayPalette.powerGold
        property color m3onPrimaryFixed: "#251A00"
        property color m3onPrimaryFixedVariant: "#5A4A12"
        property color m3secondaryFixed: "#CFE0F6"
        property color m3secondaryFixedDim: DoorwayPalette.skyHint
        property color m3onSecondaryFixed: "#06203F"
        property color m3onSecondaryFixedVariant: "#1F3C88"
        property color m3tertiaryFixed: "#C8EFB1"
        property color m3tertiaryFixedDim: DoorwayPalette.grassBright
        property color m3onTertiaryFixed: "#0E2A06"
        property color m3onTertiaryFixedVariant: "#2E5A1C"
        property color m3success: DoorwayPalette.grassBright
        property color m3onSuccess: "#0E2A06"
        property color m3successContainer: "#2E5A1C"
        property color m3onSuccessContainer: "#C8EFB1"
        // Terminal palette — warm Nintendo set.
        property color term0: "#1C1C1C"
        property color term1: "#E60012"
        property color term2: "#5FAF3A"
        property color term3: "#FFC20E"
        property color term4: "#1F3C88"
        property color term5: "#C46A2D"
        property color term6: "#6FA3D9"
        property color term7: "#EFE3C5"
        property color term8: "#3A2A1E"
        property color term9: "#FF5C4A"
        property color term10: "#7FC95A"
        property color term11: "#FFD453"
        property color term12: "#6FA3D9"
        property color term13: "#C9A46A"
        property color term14: "#8FBCE0"
        property color term15: "#FFF6E0"
    }

    // Gold LoZ cartridge — light mode. Paper surfaces from the site's np-gold-cart
    // mixes (agedPaper toward white / parchmentSand), ink text, shared accent hues.
    readonly property QtObject goldScheme: QtObject {
        property bool darkmode: false
        property bool transparent: false
        // Aged-paper surfaces with ink text.
        property color m3background: "#F1E8CE"
        property color m3onBackground: DoorwayPalette.inkBlack
        property color m3surface: "#F1E8CE"
        property color m3surfaceDim: "#E4D1A9"
        property color m3surfaceBright: "#F8F2E0"
        property color m3surfaceContainerLowest: "#FBF6E8"
        property color m3surfaceContainerLow: "#EDE2C2"
        property color m3surfaceContainer: "#E6D8B4"
        property color m3surfaceContainerHigh: "#DECDA3"
        property color m3surfaceContainerHighest: "#D5C293"
        property color m3onSurface: DoorwayPalette.inkBlack
        property color m3surfaceVariant: "#E0D0A8"
        property color m3onSurfaceVariant: "#4A3D2E"
        property color m3inverseSurface: "#2B2620"
        property color m3inverseOnSurface: DoorwayPalette.agedPaper
        property color m3outline: "#6B5D3F"
        property color m3outlineVariant: "#CBC0A6"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: DoorwayPalette.powerGold
        // Primary = the gold signature warmth (ink on gold for contrast).
        property color m3primary: DoorwayPalette.powerGold
        property color m3onPrimary: DoorwayPalette.inkBlack
        property color m3primaryContainer: "#EAD98F"
        property color m3onPrimaryContainer: "#3A2E00"
        property color m3inversePrimary: "#FFE08A"
        // Secondary = hero blue (dark enough to carry text on paper).
        property color m3secondary: DoorwayPalette.heroBlue
        property color m3onSecondary: DoorwayPalette.agedPaper
        property color m3secondaryContainer: "#CFE0F6"
        property color m3onSecondaryContainer: "#0A2148"
        // Tertiary = grassland green, deepened for light surfaces.
        property color m3tertiary: "#3E7A24"
        property color m3onTertiary: "#F1E8CE"
        property color m3tertiaryContainer: "#C8EFB1"
        property color m3onTertiaryContainer: "#123A05"
        // Error = the power-red fire (full strength reads fine on paper).
        property color m3error: DoorwayPalette.powerRed
        property color m3onError: "#FFF6E0"
        property color m3errorContainer: "#FFDAD5"
        property color m3onErrorContainer: "#690005"
        // Fixed roles are mode-invariant by Material definition.
        property color m3primaryFixed: "#FFE08A"
        property color m3primaryFixedDim: DoorwayPalette.powerGold
        property color m3onPrimaryFixed: "#251A00"
        property color m3onPrimaryFixedVariant: "#5A4A12"
        property color m3secondaryFixed: "#CFE0F6"
        property color m3secondaryFixedDim: DoorwayPalette.skyHint
        property color m3onSecondaryFixed: "#06203F"
        property color m3onSecondaryFixedVariant: "#1F3C88"
        property color m3tertiaryFixed: "#C8EFB1"
        property color m3tertiaryFixedDim: DoorwayPalette.grassBright
        property color m3onTertiaryFixed: "#0E2A06"
        property color m3onTertiaryFixedVariant: "#2E5A1C"
        property color m3success: "#3E7A24"
        property color m3onSuccess: "#F1E8CE"
        property color m3successContainer: "#C8EFB1"
        property color m3onSuccessContainer: "#123A05"
        // Terminal palette — identical in both modes (terminals stay dark-tuned).
        property color term0: "#1C1C1C"
        property color term1: "#E60012"
        property color term2: "#5FAF3A"
        property color term3: "#FFC20E"
        property color term4: "#1F3C88"
        property color term5: "#C46A2D"
        property color term6: "#6FA3D9"
        property color term7: "#EFE3C5"
        property color term8: "#3A2A1E"
        property color term9: "#FF5C4A"
        property color term10: "#7FC95A"
        property color term11: "#FFD453"
        property color term12: "#6FA3D9"
        property color term13: "#C9A46A"
        property color term14: "#8FBCE0"
        property color term15: "#FFF6E0"
    }

    colors: QtObject {
        property color colSubtext: m3colors.m3outline
        // Layer 0
        property color colLayer0Base: ColorUtils.mix(m3colors.m3background, m3colors.m3primary, Config.options.appearance.extraBackgroundTint ? 0.99 : 1)
        property color colLayer0: ColorUtils.transparentize(colLayer0Base, root.backgroundTransparency)
        property color colOnLayer0: m3colors.m3onBackground
        property color colLayer0Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer0, colOnLayer0, 0.9, root.contentTransparency))
        property color colLayer0Active: ColorUtils.transparentize(ColorUtils.mix(colLayer0, colOnLayer0, 0.8, root.contentTransparency))
        property color colLayer0Border: ColorUtils.mix(root.m3colors.m3outlineVariant, colLayer0, 0.4)
        // Layer 1
        property color colLayer1Base: m3colors.m3surfaceContainerLow
        property color colLayer1: ColorUtils.solveOverlayColor(colLayer0Base, colLayer1Base, 1 - root.contentTransparency);
        property color colOnLayer1: m3colors.m3onSurfaceVariant;
        property color colOnLayer1Inactive: ColorUtils.mix(colOnLayer1, colLayer1, 0.45);
        property color colLayer1Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.92), root.contentTransparency)
        property color colLayer1Active: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.85), root.contentTransparency);
        // Layer 2
        property color colLayer2Base: m3colors.m3surfaceContainer
        property color colLayer2: ColorUtils.solveOverlayColor(colLayer1Base, colLayer2Base, 1 - root.contentTransparency)
        property color colLayer2Hover: ColorUtils.solveOverlayColor(colLayer1Base, ColorUtils.mix(colLayer2Base, colOnLayer2, 0.90), 1 - root.contentTransparency)
        property color colLayer2Active: ColorUtils.solveOverlayColor(colLayer1Base, ColorUtils.mix(colLayer2Base, colOnLayer2, 0.80), 1 - root.contentTransparency);
        property color colLayer2Disabled: ColorUtils.solveOverlayColor(colLayer1Base, ColorUtils.mix(colLayer2Base, m3colors.m3background, 0.8), 1 - root.contentTransparency);
        property color colOnLayer2: m3colors.m3onSurface;
        property color colOnLayer2Disabled: ColorUtils.mix(colOnLayer2, m3colors.m3background, 0.4);
        // Layer 3
        property color colLayer3Base: m3colors.m3surfaceContainerHigh
        property color colLayer3: ColorUtils.solveOverlayColor(colLayer2Base, colLayer3Base, 1 - root.contentTransparency)
        property color colLayer3Hover: ColorUtils.solveOverlayColor(colLayer2Base, ColorUtils.mix(colLayer3Base, colOnLayer3, 0.90), 1 - root.contentTransparency)
        property color colLayer3Active: ColorUtils.solveOverlayColor(colLayer2Base, ColorUtils.mix(colLayer3Base, colOnLayer3, 0.80), 1 - root.contentTransparency);
        property color colOnLayer3: m3colors.m3onSurface;
        // Layer 4
        property color colLayer4Base: m3colors.m3surfaceContainerHighest
        property color colLayer4: ColorUtils.solveOverlayColor(colLayer3Base, colLayer4Base, 1 - root.contentTransparency)
        property color colLayer4Hover: ColorUtils.solveOverlayColor(colLayer3Base, ColorUtils.mix(colLayer4Base, colOnLayer4, 0.90), 1 - root.contentTransparency)
        property color colLayer4Active: ColorUtils.solveOverlayColor(colLayer3Base, ColorUtils.mix(colLayer4Base, colOnLayer4, 0.80), 1 - root.contentTransparency);
        property color colOnLayer4: m3colors.m3onSurface;
        // Primary
        property color colPrimary: m3colors.m3primary
        property color colOnPrimary: m3colors.m3onPrimary
        property color colPrimaryHover: ColorUtils.mix(colors.colPrimary, colLayer1Hover, 0.87)
        property color colPrimaryActive: ColorUtils.mix(colors.colPrimary, colLayer1Active, 0.7)
        property color colPrimaryContainer: m3colors.m3primaryContainer
        property color colPrimaryContainerHover: ColorUtils.mix(colors.colPrimaryContainer, colors.colOnPrimaryContainer, 0.9)
        property color colPrimaryContainerActive: ColorUtils.mix(colors.colPrimaryContainer, colors.colOnPrimaryContainer, 0.8)
        property color colOnPrimaryContainer: m3colors.m3onPrimaryContainer
        // Secondary
        property color colSecondary: m3colors.m3secondary
        property color colSecondaryHover: ColorUtils.mix(m3colors.m3secondary, colLayer1Hover, 0.85)
        property color colSecondaryActive: ColorUtils.mix(m3colors.m3secondary, colLayer1Active, 0.4)
        property color colOnSecondary: m3colors.m3onSecondary
        property color colSecondaryContainer: m3colors.m3secondaryContainer
        property color colSecondaryContainerHover: ColorUtils.mix(m3colors.m3secondaryContainer, m3colors.m3onSecondaryContainer, 0.90)
        property color colSecondaryContainerActive: ColorUtils.mix(m3colors.m3secondaryContainer, m3colors.m3onSecondaryContainer, 0.54)
        property color colOnSecondaryContainer: m3colors.m3onSecondaryContainer
        // Tertiary
        property color colTertiary: m3colors.m3tertiary
        property color colTertiaryHover: ColorUtils.mix(m3colors.m3tertiary, colLayer1Hover, 0.85)
        property color colTertiaryActive: ColorUtils.mix(m3colors.m3tertiary, colLayer1Active, 0.4)
        property color colTertiaryContainer: m3colors.m3tertiaryContainer
        property color colTertiaryContainerHover: ColorUtils.mix(m3colors.m3tertiaryContainer, m3colors.m3onTertiaryContainer, 0.90)
        property color colTertiaryContainerActive: ColorUtils.mix(m3colors.m3tertiaryContainer, colLayer1Active, 0.54)
        property color colOnTertiary: m3colors.m3onTertiary
        property color colOnTertiaryContainer: m3colors.m3onTertiaryContainer
        // Surface
        property color colBackgroundSurfaceContainer: ColorUtils.transparentize(m3colors.m3surfaceContainer, root.backgroundTransparency)
        property color colSurfaceContainerLow: ColorUtils.solveOverlayColor(m3colors.m3background, m3colors.m3surfaceContainerLow, 1 - root.contentTransparency)
        property color colSurfaceContainer: ColorUtils.solveOverlayColor(m3colors.m3surfaceContainerLow, m3colors.m3surfaceContainer, 1 - root.contentTransparency)
        property color colSurfaceContainerHigh: ColorUtils.solveOverlayColor(m3colors.m3surfaceContainer, m3colors.m3surfaceContainerHigh, 1 - root.contentTransparency)
        property color colSurfaceContainerHighest: ColorUtils.solveOverlayColor(m3colors.m3surfaceContainerHigh, m3colors.m3surfaceContainerHighest, 1 - root.contentTransparency)
        property color colSurfaceContainerHighestHover: ColorUtils.mix(m3colors.m3surfaceContainerHighest, m3colors.m3onSurface, 0.95)
        property color colSurfaceContainerHighestActive: ColorUtils.mix(m3colors.m3surfaceContainerHighest, m3colors.m3onSurface, 0.85)
        property color colOnSurface: m3colors.m3onSurface
        property color colOnSurfaceVariant: m3colors.m3onSurfaceVariant
        // Misc
        property color colTooltip: m3colors.m3inverseSurface
        property color colOnTooltip: m3colors.m3inverseOnSurface
        property color colScrim: ColorUtils.transparentize(m3colors.m3scrim, 0.5)
        property color colShadow: ColorUtils.transparentize(m3colors.m3shadow, 0.7)
        property color colOutline: m3colors.m3outline
        property color colOutlineVariant: m3colors.m3outlineVariant
        property color colError: m3colors.m3error
        property color colErrorHover: ColorUtils.mix(m3colors.m3error, colLayer1Hover, 0.85)
        property color colErrorActive: ColorUtils.mix(m3colors.m3error, colLayer1Active, 0.7)
        property color colOnError: m3colors.m3onError
        property color colErrorContainer: m3colors.m3errorContainer
        property color colErrorContainerHover: ColorUtils.mix(m3colors.m3errorContainer, m3colors.m3onErrorContainer, 0.90)
        property color colErrorContainerActive: ColorUtils.mix(m3colors.m3errorContainer, m3colors.m3onErrorContainer, 0.70)
        property color colOnErrorContainer: m3colors.m3onErrorContainer
    }

    rounding: QtObject {
        property int unsharpen: 2
        property int unsharpenmore: 6
        property int verysmall: 8
        property int small: 12
        property int normal: 17
        property int large: 23
        property int verylarge: 30
        property int full: 9999
        property int screenRounding: large
        property int windowRounding: 18
    }

    font: QtObject {
        property QtObject family: QtObject {
            property string main: Config.options.appearance.fonts.main
            property string numbers: Config.options.appearance.fonts.numbers
            property string title: Config.options.appearance.fonts.title
            property string iconMaterial: "Material Symbols Rounded"
            property string iconNerd: Config.options.appearance.fonts.iconNerd
            property string monospace: Config.options.appearance.fonts.monospace
            property string reading: Config.options.appearance.fonts.reading
            property string expressive: Config.options.appearance.fonts.expressive
            property string display: Config.options.appearance.fonts.display
        }
        property QtObject variableAxes: QtObject {
            property var main: ({
                "wght": 450,
                "wdth": 100,
            })
            property var numbers: ({
                "wght": 450,
            })
            property var title: ({ // Slightly bold weight for title
                "wght": 550, // Weight (Lowered to compensate for increased grade)
            })
        }
        property QtObject pixelSize: QtObject {
            property int smallest: 10
            property int smaller: 12
            property int smallie: 13
            property int small: 15
            property int normal: 16
            property int large: 17
            property int larger: 19
            property int huge: 22
            property int hugeass: 23
            property int title: huge
        }
    }

    animationCurves: QtObject {
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1] // Default, 350ms
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1] // Default, 500ms
        readonly property list<real> expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1] // Default, 650ms
        readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1] // Default, 200ms
        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedFirstHalf: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82]
        readonly property list<real> emphasizedLastHalf: [5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property real expressiveFastSpatialDuration: 350
        readonly property real expressiveDefaultSpatialDuration: 500
        readonly property real expressiveSlowSpatialDuration: 650
        readonly property real expressiveEffectsDuration: 200
    }

    animation: QtObject {
        property QtObject elementMove: QtObject {
            property int duration: animationCurves.expressiveDefaultSpatialDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveDefaultSpatial
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMove.duration
                    easing.type: root.animation.elementMove.type
                    easing.bezierCurve: root.animation.elementMove.bezierCurve
                }
            }
        }

        property QtObject elementMoveSmall: QtObject {
            property int duration: animationCurves.expressiveFastSpatialDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveFastSpatial
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveSmall.duration
                    easing.type: root.animation.elementMoveSmall.type
                    easing.bezierCurve: root.animation.elementMoveSmall.bezierCurve
                }
            }
        }

        property QtObject elementMoveEnter: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedDecel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveEnter.duration
                    easing.type: root.animation.elementMoveEnter.type
                    easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        property QtObject elementMoveExit: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedAccel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveExit.duration
                    easing.type: root.animation.elementMoveExit.type
                    easing.bezierCurve: root.animation.elementMoveExit.bezierCurve
                }
            }
        }

        property QtObject elementMoveFast: QtObject {
            property int duration: animationCurves.expressiveEffectsDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveEffects
            property int velocity: 850
            property Component colorAnimation: Component { ColorAnimation {
                duration: root.animation.elementMoveFast.duration
                easing.type: root.animation.elementMoveFast.type
                easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
            }}
            property Component numberAnimation: Component { NumberAnimation {
                alwaysRunToEnd: true
                duration: root.animation.elementMoveFast.duration
                easing.type: root.animation.elementMoveFast.type
                easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
            }}
        }

        property QtObject elementResize: QtObject {
            property int duration: 300
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasized
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementResize.duration
                    easing.type: root.animation.elementResize.type
                    easing.bezierCurve: root.animation.elementResize.bezierCurve
                }
            }
        }

        property QtObject clickBounce: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveDefaultSpatial
            property int velocity: 850
            property Component numberAnimation: Component { NumberAnimation {
                alwaysRunToEnd: true
                duration: root.animation.clickBounce.duration
                easing.type: root.animation.clickBounce.type
                easing.bezierCurve: root.animation.clickBounce.bezierCurve
            }}
        }
        
        property QtObject scroll: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: root.animationCurves.standardDecel
        }

        property QtObject menuDecel: QtObject {
            property int duration: 350
            property int type: Easing.OutExpo
        }
    }

    sizes: QtObject {
        property real baseBarHeight: 40
        property real barHeight: Config.options.bar.cornerStyle === 1 ? 
            (baseBarHeight + root.sizes.hyprlandGapsOut * 2) : baseBarHeight
        property real barCenterSideModuleWidth: Config.options?.bar.verbose ? 360 : 140
        property real barCenterSideModuleWidthShortened: 280
        property real barCenterSideModuleWidthHellaShortened: 190
        property real barShortenScreenWidthThreshold: 1200 // Shorten if screen width is at most this value
        property real barHellaShortenScreenWidthThreshold: 1000 // Shorten even more...
        property real elevationMargin: 10
        property real fabShadowRadius: 5
        property real fabHoveredShadowRadius: 7
        property real hyprlandGapsOut: 5
        property real mediaControlsWidth: 440
        property real mediaControlsHeight: 160
        property real notificationPopupWidth: 410
        property real osdWidth: 180
        property real searchWidthCollapsed: 210
        property real searchWidth: 360
        property real sidebarWidth: 460
        property real sidebarWidthExtended: 750
        property real baseVerticalBarWidth: 46
        property real verticalBarWidth: Config.options.bar.cornerStyle === 1 ? 
            (baseVerticalBarWidth + root.sizes.hyprlandGapsOut * 2) : baseVerticalBarWidth
        property real wallpaperSelectorWidth: 1200
        property real wallpaperSelectorHeight: 690
        property real wallpaperSelectorItemMargins: 8
        property real wallpaperSelectorItemPadding: 6
    }

    syntaxHighlightingTheme: root.m3colors.darkmode ? "Monokai" : "ayu Light"
}
