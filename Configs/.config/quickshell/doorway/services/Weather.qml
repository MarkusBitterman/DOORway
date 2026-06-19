pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

/**
 * Weather data singleton — watches ~/.cache/doorway/weather.json produced
 * by the doorway-weather-fetch systemd service (doorway-pirateweather.py).
 *
 * `available` becomes true once a valid JSON payload has been loaded.
 * `getData()` fires the fetch process on demand (e.g. right-click refresh).
 */
Singleton {
    id: root

    property bool available: false

    property var data: ({
        icon: "",
        temp: "--°",
        city: "",
        tempFeelsLike: "--°",
        uv: "--",
        windDir: "--",
        wind: "--",
        precip: "--",
        humidity: "--",
        visib: "--",
        press: "--",
        sunrise: "--",
        sunset: "--",
        summary: "",
        lastRefresh: "--",
        hourly: []
    })

    function getData() {
        fetchProc.running = true
    }

    FileView {
        id: weatherFile
        // FileView expects a plain path (no file:// prefix)
        path: FileUtils.trimFileProtocol(`${Directories.genericCache}/doorway/weather.json`)
        watchChanges: true
        onLoaded: {
            try {
                const parsed = JSON.parse(weatherFile.text())
                root.data = parsed
                root.available = true
            } catch (e) {
                // Keep defaults — stale or corrupt file
            }
        }
    }

    Process {
        id: fetchProc
        command: [FileUtils.trimFileProtocol(Directories.home) + "/.local/lib/doorway/doorway-pirateweather.py"]
    }
}
