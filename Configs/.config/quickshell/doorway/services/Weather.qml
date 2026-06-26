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
        sunriseHHMM: "06:30",
        sunsetHHMM: "19:00",
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

    // watchChanges fires on inotify IN_MODIFY which can arrive at truncation time
    // (before Python finishes writing). This timer polls the completed file every
    // minute as a reliable fallback so the UI always reflects the latest fetch.
    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: weatherFile.reload()
    }

    // Use systemctl to trigger the service so it inherits the API key EnvironmentFile
    // configured in flake.nix — running the script directly would miss PIRATE_WEATHER_API_KEY.
    Process {
        id: fetchProc
        command: ["systemctl", "--user", "start", "doorway-weather-fetch.service"]
    }
}
