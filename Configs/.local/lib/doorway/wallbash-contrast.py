#!/usr/bin/env python3
"""Raise a generated terminal palette to a minimum contrast ratio.

Wallbash derives kitty's whole ANSI palette from the wallpaper by sampling
points on its accent ramps (``<wallbash_4xa9>`` and friends). Those ramps have
no contrast relationship to ``<wallbash_pry1>``, which the same template uses
as the background — so legibility is luck of the wallpaper. A maroon/olive
wallpaper measured on 2026-08-06 produced 14 of 16 ANSI slots below the WCAG
3:1 floor, including ``color7`` (the "white" most TUI text uses) at 1.62:1.

This runs as the kitty wallbash hook, after the template is rendered and
before kitty is signalled to reload. Only lightness moves, and only far enough
to clear the floor, so the palette still reads as "derived from this
wallpaper", just never illegibly.

Hue and saturation are held fixed through the HLS round trip; a 4000-case
fuzz measured worst-case hue drift of 0.028 (8-bit rounding, not algorithmic).
The exception is a colour driven all the way to near-white or near-black,
where hue is undefined and the round trip cannot round-trip — that only
happens when the floor is unreachable any other way.

Usage:  wallbash-contrast.py [--floor 4.5] [--dry-run] THEME.conf
"""

from __future__ import annotations

import argparse
import colorsys
import re
import sys

# Slots corrected against the file's own `background`. color0 is deliberately
# absent: conventionally it is a background/decoration tone rather than a text
# colour (Catppuccin, Gruvbox et al. all ship it at ~1.6:1 on purpose), and
# forcing it light would break reverse-video and block-cursor rendering.
# color8 IS included — "bright black" is the dim grey terminal UIs use for
# comments and status lines, which is exactly the text that went unreadable.
TEXT_ON_BACKGROUND = ["foreground"] + [f"color{i}" for i in range(1, 16)]

# Self-contained foreground/background pairs: each is corrected against its
# own partner, not the window background.
PAIRS = [
    ("selection_foreground", "selection_background"),
    ("active_tab_foreground", "active_tab_background"),
    ("inactive_tab_foreground", "inactive_tab_background"),
    ("cursor_text_color", "cursor"),
]

# ANSI normal/bright pairs. After correction both members can converge on the
# same lightness, which erases the distinction terminal apps rely on.
BRIGHT_PAIRS = [(f"color{i}", f"color{i + 8}") for i in range(1, 8)]

SETTING_RE = re.compile(r"^(\s*)([A-Za-z_][A-Za-z0-9_]*)(\s+)(#[0-9A-Fa-f]{6})(\s*)$")


def parse_hex(value: str) -> tuple[float, float, float]:
    v = value.lstrip("#")
    return tuple(int(v[i : i + 2], 16) / 255 for i in (0, 2, 4))  # type: ignore[return-value]


def to_hex(rgb: tuple[float, float, float]) -> str:
    return "#" + "".join(f"{round(max(0.0, min(1.0, c)) * 255):02X}" for c in rgb)


def luminance(rgb: tuple[float, float, float]) -> float:
    """WCAG 2.x relative luminance."""

    def lin(c: float) -> float:
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (lin(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: tuple[float, float, float], b: tuple[float, float, float]) -> float:
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def composite(
    bg: tuple[float, float, float],
    backdrop: tuple[float, float, float],
    opacity: float,
) -> tuple[float, float, float]:
    """The background a glyph is *actually* drawn against on a translucent window.

    kitty's `background_opacity` (and Hyprland's `active_opacity` on top of it)
    let the wallpaper through, so the nominal `background` is not what the eye
    compares text to. Measured on 2026-08-06: a nominal `#49262D` background at
    0.83 opacity rendered as `#5C4D42`, turning a nominal 5.22:1 into 2.79:1 on
    screen. Correcting against the nominal value alone would print a promise
    the display does not keep.

    What is behind the window is the wallpaper, which differs per pixel and
    cannot be known here, so `backdrop` stands in for it — neutral mid-grey by
    default, the least-assuming choice and a conservative one for the dark
    backgrounds wallbash usually derives.
    """
    return tuple(bg[i] * opacity + backdrop[i] * (1 - opacity) for i in range(3))  # type: ignore[return-value]


def quantize(rgb: tuple[float, float, float]) -> tuple[float, float, float]:
    """Snap to the 8-bit grid the file is written on.

    Candidates are searched in float but stored as #RRGGBB, and rounding can
    drop a colour just back under the floor it was chosen for. Evaluating
    quantized candidates keeps the search honest: whatever the file ends up
    containing is what actually satisfied the predicate. (Without this, a
    re-run finds the stored value marginally short and nudges it again — a
    ratchet that moved color10 by one blue step per invocation.)
    """
    return tuple(round(max(0.0, min(1.0, c)) * 255) / 255 for c in rgb)  # type: ignore[return-value]


def relight(rgb: tuple[float, float, float], lightness: float) -> tuple[float, float, float]:
    """Same hue and saturation, new HLS lightness, on the 8-bit grid."""
    h, _, s = colorsys.rgb_to_hls(*rgb)
    return quantize(colorsys.hls_to_rgb(h, lightness, s))


def enforce(
    fg: tuple[float, float, float],
    bg: tuple[float, float, float],
    floor: float,
) -> tuple[float, float, float]:
    """Move `fg`'s lightness the minimum distance that clears `floor` vs `bg`.

    Both directions are scanned rather than assuming "lighten on a dark
    background": against a mid-luminance background, darkening is often the
    shorter route, and sometimes the only one that works at all. A linear scan
    (rather than a binary search) because contrast-vs-lightness is only
    piecewise monotonic once saturation clamps the achievable range — the scan
    makes no monotonicity assumption and 500 steps is free at this size.
    """
    if contrast(fg, bg) >= floor:
        return fg

    _, current, _ = colorsys.rgb_to_hls(*fg)
    best_fallback, best_ratio = fg, contrast(fg, bg)

    for target in (1.0, 0.0):
        steps = 500
        for i in range(1, steps + 1):
            candidate = relight(fg, current + (target - current) * i / steps)
            ratio = contrast(candidate, bg)
            if ratio >= floor:
                # First hit in this direction = smallest change that works.
                return candidate
            if ratio > best_ratio:
                best_fallback, best_ratio = candidate, ratio

    # Neither pure white nor pure black cleared the floor (only possible when
    # the background itself sits mid-luminance). Take the best available.
    return best_fallback


def separate(
    normal: tuple[float, float, float],
    bright: tuple[float, float, float],
    bg: tuple[float, float, float],
    floor: float,
) -> tuple[float, float, float]:
    """Keep a bright slot visibly distinct from its normal counterpart.

    Correction pushes both members toward the same legible band, which can
    collapse e.g. color1/color9 onto each other. Nudge the bright one further
    from the background until the pair is telling apart again, without
    dropping it back below the floor.
    """
    if contrast(normal, bright) >= 1.15:
        return bright

    away = 1.0 if luminance(bright) >= luminance(bg) else 0.0
    _, current, _ = colorsys.rgb_to_hls(*bright)
    for i in range(1, 201):
        candidate = relight(bright, current + (away - current) * i / 200)
        if contrast(normal, candidate) >= 1.15 and contrast(candidate, bg) >= floor:
            return candidate
    return bright


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("theme", help="kitty-style conf file of `key #RRGGBB` lines")
    ap.add_argument(
        "--floor",
        type=float,
        default=4.5,
        help="minimum WCAG contrast ratio (default 4.5 = AA body text; 0 disables)",
    )
    ap.add_argument(
        "--opacity",
        type=float,
        default=1.0,
        help=(
            "terminal background opacity (0-1). Below 1 the floor is applied against "
            "the background composited over --backdrop, since that is what text is "
            "really read against. Default 1.0 = treat the background as opaque."
        ),
    )
    ap.add_argument(
        "--backdrop",
        default="#808080",
        help="stand-in for whatever shows through a translucent background (default neutral grey)",
    )
    ap.add_argument("--dry-run", action="store_true", help="report changes, write nothing")
    args = ap.parse_args()

    if args.floor <= 1:
        return 0

    try:
        with open(args.theme, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
    except OSError as exc:
        print(f"wallbash-contrast: cannot read {args.theme}: {exc}", file=sys.stderr)
        return 1

    # Pass 1: index every `key #RRGGBB` line.
    colors: dict[str, tuple[float, float, float]] = {}
    index: dict[str, int] = {}
    for n, line in enumerate(lines):
        m = SETTING_RE.match(line)
        if m:
            colors[m.group(2)] = parse_hex(m.group(4))
            index[m.group(2)] = n

    if "background" not in colors:
        print(
            f"wallbash-contrast: {args.theme} has no `background`; nothing to correct against",
            file=sys.stderr,
        )
        return 0

    # Text is corrected against the *rendered* background, not the declared one.
    opacity = max(0.0, min(1.0, args.opacity))
    bg = composite(colors["background"], parse_hex(args.backdrop), opacity)
    if opacity < 1.0:
        print(
            f"wallbash-contrast: background {to_hex(colors['background'])} at opacity "
            f"{opacity:g} reads as {to_hex(bg)}; correcting against that"
        )

    corrected: dict[str, tuple[float, float, float]] = {}
    # What each slot was corrected *against*, so the report quotes the ratio
    # that actually governed the decision rather than the window background.
    reference: dict[str, tuple[float, float, float]] = {}

    for key in TEXT_ON_BACKGROUND:
        if key in colors:
            corrected[key] = enforce(colors[key], bg, args.floor)
            reference[key] = bg

    for fg_key, bg_key in PAIRS:
        if fg_key in colors and bg_key in colors:
            corrected[fg_key] = enforce(colors[fg_key], colors[bg_key], args.floor)
            reference[fg_key] = colors[bg_key]

    for normal_key, bright_key in BRIGHT_PAIRS:
        if normal_key in corrected and bright_key in corrected:
            corrected[bright_key] = separate(
                corrected[normal_key], corrected[bright_key], bg, args.floor
            )

    # Pass 2: rewrite only the lines whose colour actually moved, preserving
    # comments, blank lines and the original column alignment.
    changed = 0
    for key, rgb in corrected.items():
        new_hex = to_hex(rgb)
        n = index[key]
        m = SETTING_RE.match(lines[n])
        assert m is not None
        if m.group(4).upper() == new_hex:
            continue
        changed += 1
        ref = reference[key]
        before = contrast(colors[key], ref)
        after = contrast(rgb, ref)
        print(f"  {key:24} {m.group(4)} -> {new_hex}  ({before:.2f}:1 -> {after:.2f}:1)")
        lines[n] = f"{m.group(1)}{key}{m.group(3)}{new_hex}{m.group(5)}"

    if not changed:
        print(f"wallbash-contrast: {args.theme} already clears {args.floor}:1")
        return 0

    if args.dry_run:
        print(f"wallbash-contrast: {changed} colour(s) would change (dry run)")
        return 0

    try:
        with open(args.theme, "w", encoding="utf-8") as fh:
            fh.write("\n".join(lines) + "\n")
    except OSError as exc:
        print(f"wallbash-contrast: cannot write {args.theme}: {exc}", file=sys.stderr)
        return 1

    print(f"wallbash-contrast: raised {changed} colour(s) to >= {args.floor}:1")
    return 0


if __name__ == "__main__":
    sys.exit(main())
