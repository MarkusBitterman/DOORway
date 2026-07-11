pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, CPU, and network usage.
 */
Singleton {
    id: root
	property real memoryTotal: 1
	property real memoryFree: 0
	property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
	property real swapFree: 0
	property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property var previousCpuStats

    // --- Network throughput (down = receive, up = transmit), summed over all
    // non-loopback interfaces. Rates are bytes/sec computed from /proc/net/dev deltas. ---
    property real netDownBytesPerSec: 0
    property real netUpBytesPerSec: 0
    property var previousNetStats

    // Network has no fixed ceiling like a memory total, so each direction is normalised
    // against a self-adapting peak: the reference grows instantly to any new burst and
    // decays slowly, so the gauge auto-gains to the machine's real throughput (wifi vs
    // gigabit) without a hardcoded bandwidth constant. The floor keeps idle blips small
    // and prevents divide-by-tiny spikes; down/up carry separate floors because uplink is
    // typically an order of magnitude smaller than downlink.
    readonly property real netDownFloor: 5 * 1024 * 1024   // 5 MB/s
    readonly property real netUpFloor: 1 * 1024 * 1024     // 1 MB/s
    readonly property real netDecay: 0.92                  // reference fade per tick
    property real netDownMax: netDownFloor
    property real netUpMax: netUpFloor
    property real netDownPercentage: Math.min(1, netDownBytesPerSec / netDownMax)
    property real netUpPercentage: Math.min(1, netUpBytesPerSec / netUpMax)

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift()
        }
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift()
        }
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift()
        }
    }
    function updateHistories() {
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
        updateCpuUsageHistory()
    }

    // Sum receive/transmit byte counters across every non-loopback interface, then
    // convert the delta since the previous sample into a bytes/sec rate.
    function updateNetworkUsage(dtSeconds) {
        const lines = fileNetdev.text().split("\n")
        let rx = 0, tx = 0
        for (const line of lines) {
            const m = line.match(/^\s*([^:]+):\s*(\d+)(?:\s+\d+){7}\s+(\d+)/)
            if (!m) continue
            if (m[1].trim() === "lo") continue
            rx += Number(m[2])   // field 1  = receive bytes
            tx += Number(m[3])   // field 9  = transmit bytes
        }

        if (previousNetStats && dtSeconds > 0) {
            root.netDownBytesPerSec = Math.max(0, (rx - previousNetStats.rx) / dtSeconds)
            root.netUpBytesPerSec = Math.max(0, (tx - previousNetStats.tx) / dtSeconds)
            // Grow the reference to any new peak, otherwise decay it toward the floor.
            root.netDownMax = Math.max(netDownFloor, netDownMax * netDecay, netDownBytesPerSec)
            root.netUpMax = Math.max(netUpFloor, netUpMax * netDecay, netUpBytesPerSec)
        }
        previousNetStats = { rx, tx }
    }

    // Human-readable rate for the popup (B/s → KB/s → MB/s).
    function bytesPerSecString(bps) {
        if (bps >= 1024 * 1024) return (bps / (1024 * 1024)).toFixed(1) + " MB/s"
        if (bps >= 1024) return (bps / 1024).toFixed(0) + " KB/s"
        return Math.round(bps) + " B/s"
    }

	Timer {
		interval: 1
        running: true 
        repeat: true
		onTriggered: {
            // Reload files
            fileMeminfo.reload()
            fileStat.reload()
            fileNetdev.reload()

            // Parse memory and swap usage
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            // Parse CPU usage
            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }

                previousCpuStats = { total, idle }
            }

            // Network rate needs real elapsed seconds, not the (dynamic) timer interval.
            const now = Date.now()
            root.updateNetworkUsage(previousSampleTime > 0 ? (now - previousSampleTime) / 1000 : 0)
            previousSampleTime = now

            root.updateHistories()
            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

    property double previousSampleTime: 0

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileNetdev; path: "/proc/net/dev" }

    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                root.maxAvailableCpuString = (parseFloat(outputCollector.text) / 1000).toFixed(0) + " GHz"
            }
        }
    }
}
