import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * LiteratureClock — the DOORway right-sidebar "literary readout". Surfaces a
 * literary quote whose text contains the current time (the time phrase is
 * exposed separately as `timestring` so the widget can emphasize it), à la
 * github.com/JohsEnevoldsen/literature-clock.
 *
 * The quote corpus is baked into ~/.local/share/doorway/litclock/quotes.json by
 * gen-litclock.sh (keyed "HH:MM" → [{q,t,a,b}]). Loaded once into an in-memory
 * map; each minute we index by "HH:MM" — no re-parsing. ~31 of 1440 minutes have
 * no quote, so lookup() falls back to the nearest covered minute.
 */
Singleton {
    id: root

    // Directories.home carries a file:// prefix; FileView wants a plain path.
    readonly property string dataPath: FileUtils.trimFileProtocol(
        `${Directories.home}/.local/share/doorway/litclock/quotes.json`)

    property var byMinute: ({})
    property bool loaded: false

    property string quote: ""
    property string timestring: ""
    property string title: ""
    property string author: ""
    property bool valid: false

    property int _lastStamp: -1

    function pad(n) { return (n < 10 ? "0" : "") + n }

    // Exact minute, else the nearest covered minute within ±5 (earlier preferred).
    function lookup(h, m) {
        for (let d = 0; d <= 5; d++) {
            const signs = d === 0 ? [0] : [-1, 1];
            for (const s of signs) {
                const tm = ((h * 60 + m) + s * d + 1440) % 1440;
                const key = root.pad(Math.floor(tm / 60)) + ":" + root.pad(tm % 60);
                const arr = root.byMinute[key];
                if (arr && arr.length > 0)
                    return arr[Math.floor(Math.random() * arr.length)];
            }
        }
        return null;
    }

    function tick() {
        if (!root.loaded) return;
        const now = new Date();
        const stamp = now.getHours() * 60 + now.getMinutes();
        if (stamp === root._lastStamp) return;   // same minute — keep current quote
        root._lastStamp = stamp;

        const entry = root.lookup(now.getHours(), now.getMinutes());
        if (entry) {
            root.quote = entry.q;
            root.timestring = entry.t;
            root.title = entry.b;
            root.author = entry.a;
            root.valid = true;
        } else {
            root.quote = "";
            root.timestring = "";
            root.title = "";
            root.author = "";
            root.valid = false;
        }
    }

    FileView {
        id: file
        path: root.dataPath
        watchChanges: false   // static committed corpus
        onLoaded: {
            try {
                root.byMinute = JSON.parse(file.text());
                root.loaded = true;
                root._lastStamp = -1;   // force a fresh pick
                root.tick();
            } catch (e) {
                console.log("[LiteratureClock] parse failed:", e);
            }
        }
        onLoadFailed: err => console.log("[LiteratureClock] load failed:", root.dataPath, err)
    }

    // Poll a few times a minute; tick() no-ops until the wall-clock minute changes,
    // so the displayed quote lags the real minute by at most this interval.
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }
}
