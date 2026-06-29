pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

/**
 * Real audio-reactive spectrum service.
 *
 * Runs `cava` (console audio visualizer) with raw-ascii output and exposes the live
 * band magnitudes as `values` (and the `points` alias for WaveVisualizer). The cava
 * subprocess is started ONLY while something needs it (audio playing or the media
 * controls popup open) so there is zero cost at idle — see `shouldRun`.
 *
 * Mechanism mirrors the repo's IO idiom (Process + SplitParser, cf. Network.qml /
 * ResourceUsage.qml). A second, independent cava instance is intentional: it keeps the
 * lifecycle self-contained rather than coupling to the hyprlock-shared cava.py manager.
 */
Singleton {
    id: root

    // Band count fed to WaveVisualizer; the 20px Media icon down-samples this to 4 buckets.
    readonly property int bars: 32
    // Matches cava `ascii_max_range` AND WaveVisualizer.maxVisualizerValue's default (1000),
    // so the popup visualizer needs no rescaling. Keep these three in sync if changed.
    readonly property real maxValue: 1000
    readonly property int framerate: 60

    // True once `cava` is found on PATH (probe below). When false, consumers fall back.
    property bool available: false
    // Live spectrum: `bars` magnitudes in 0..maxValue. Empty when idle/unavailable.
    property list<var> values: []
    property alias points: root.values

    // Self-determining lifecycle: only run cava when there's something to visualize.
    readonly property bool shouldRun: (Config.options.bar?.cava?.enable ?? true)
        && root.available
        && ((MprisController.activePlayer?.playbackState === MprisPlaybackState.Playing)
            || GlobalStates.mediaControlsOpen)

    // One-shot availability probe.
    Process {
        running: true
        command: ["sh", "-c", "command -v cava"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0)
        }
    }

    // The cava process. Config is generated inline (raw ascii → stdout) so nothing is
    // written at build time. `running` is bound to shouldRun → auto start/stop.
    Process {
        id: cavaProc
        running: root.shouldRun
        command: ["sh", "-c",
            "cfg=$(mktemp) || exit 1\n" +
            "cat > \"$cfg\" <<'CAVACFG'\n" +
            "[general]\n" +
            "bars = " + root.bars + "\n" +
            "framerate = " + root.framerate + "\n" +
            "[input]\n" +
            "method = pulse\n" +
            "source = auto\n" +
            "[output]\n" +
            "method = raw\n" +
            "raw_target = /dev/stdout\n" +
            "data_format = ascii\n" +
            "ascii_max_range = " + root.maxValue + "\n" +
            "channels = mono\n" +
            "CAVACFG\n" +
            "exec cava -p \"$cfg\""
        ]
        stdout: SplitParser {
            // cava raw-ascii emits one frame per line: `v;v;...;v;` (trailing ';').
            onRead: line => {
                if (!line)
                    return
                const parts = line.split(";")
                if (parts.length < root.bars)
                    return // ignore partial / standby lines
                const out = new Array(root.bars)
                for (let i = 0; i < root.bars; i++) {
                    const v = Number(parts[i])
                    out[i] = isNaN(v) ? 0 : v
                }
                root.values = out
            }
        }
        onRunningChanged: {
            if (!cavaProc.running)
                root.values = [] // clear so consumers fall back / show idle
        }
    }
}
