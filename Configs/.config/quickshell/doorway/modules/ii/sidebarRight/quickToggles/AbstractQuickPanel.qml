import QtQuick
import qs.modules.common

Rectangle {
    id: root

    radius: Appearance.rounding.verysmall
    gradient: Gradient {
        GradientStop { position: 0.0; color: DoorwayPalette.plasticPanelTop }
        GradientStop { position: 1.0; color: DoorwayPalette.plasticPanelBottom }
    }
    border.width: 1
    border.color: DoorwayPalette.plasticEdge

    signal openAudioOutputDialog()
    signal openAudioInputDialog()
    signal openBluetoothDialog()
    signal openNightLightDialog()
    signal openWifiDialog()
}
