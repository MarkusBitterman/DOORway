import QtQuick
import QtQuick.Effects
import qs.modules.common
import qs.modules.common.functions

/**
 * Cyberpunk neon glow — a colorized sibling of StyledRectangularShadow.
 *
 * Glows in `glowColor` (matugen primary by default, so it tracks the wallpaper) rather
 * than the shadow color, with blur/spread/alpha scaled by `intensity` (0..1). `cached`
 * because it only re-renders when the palette or geometry changes — no per-frame cost,
 * which is what makes the "bold" look affordable on a daily-driver bar.
 *
 * Usage mirrors StyledRectangularShadow: place behind a target and pass `target`.
 */
RectangularShadow {
    id: root
    required property var target
    property color glowColor: Appearance.colors.colPrimary
    property real intensity: Config.options.bar?.glow?.intensity ?? 0.5

    anchors.fill: target
    radius: target.radius
    offset: Qt.vector2d(0.0, 0.0) // symmetric halo, not a drop shadow
    blur: 0.9 * Appearance.sizes.elevationMargin * (1 + intensity)
    spread: 1 + 2 * intensity
    // intensity 0 → fully transparent (no glow); intensity 1 → ~70% alpha bloom.
    color: ColorUtils.transparentize(glowColor, 1 - 0.7 * intensity)
    cached: true
}
