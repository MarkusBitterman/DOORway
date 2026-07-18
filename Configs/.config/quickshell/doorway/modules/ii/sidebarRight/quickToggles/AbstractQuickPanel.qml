import QtQuick
import qs.modules.common

// Boardroom toggle zone — no plate. Each HudKey carries its own hairline frame,
// so the grid sits directly on the ink ground and negative space does the
// grouping (the plastic faceplate slab was the old cartridge language).
Rectangle {
    id: root

    radius: 0
    color: "transparent"

    signal openAudioOutputDialog()
    signal openAudioInputDialog()
    signal openBluetoothDialog()
    signal openNightLightDialog()
    signal openWifiDialog()
}
