pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Per-app dominant colour, extracted from the app icon by the `doorway-icon-color` helper
 * (ImageMagick; disk-cached under $XDG_CACHE_HOME/doorway). Cached again in memory here.
 *
 * Usage: bind to IconColor.get(appId) (a pure read that returns the cached colour or the
 * fallback), and call IconColor.request(appId) when the appId changes to kick off the
 * async extraction. When a result lands, `colors` is reassigned so the get() bindings
 * re-evaluate. A single queued Process serialises extractions.
 */
Singleton {
    id: root

    readonly property color fallback: DoorwayPalette.parchmentSand
    property var colors: ({})   // appId -> "#RRGGBB"
    property var _queue: []

    function get(appId) {
        if (!appId || appId.length === 0)
            return fallback;
        const hex = colors[appId];
        return (hex !== undefined) ? hex : fallback;
    }

    function request(appId) {
        if (!appId || appId.length === 0)
            return;
        if (colors[appId] !== undefined)
            return;
        if (proc.currentId === appId || _queue.indexOf(appId) >= 0)
            return;
        _queue = [..._queue, appId];
        _pump();
    }

    function _pump() {
        if (proc.running || _queue.length === 0)
            return;
        proc.currentId = _queue[0];
        _queue = _queue.slice(1);
        proc.command = ["doorway-icon-color", proc.currentId];
        proc.running = true;
    }

    Process {
        id: proc
        property string currentId: ""
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                const hex = collector.text.trim();
                if (hex.length > 0)
                    root.colors = Object.assign({}, root.colors, { [proc.currentId]: hex });
            }
        }
        onRunningChanged: {
            if (!running)
                root._pump();
        }
    }
}
