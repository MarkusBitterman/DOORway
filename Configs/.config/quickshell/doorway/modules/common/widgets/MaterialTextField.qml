import qs.modules.common
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls

/**
 * Material 3 styled TextField (filled style)
 * https://m3.material.io/components/text-fields/overview
 * Note: We don't use NativeRendering because it makes the small placeholder text look weird
 */
TextField {
    id: root
    // Only consumer is the boardroom Wi-Fi password field — fixed hud tokens keep
    // typed text legible over the dark dialog card in both cartridge modes.
    Material.theme: Material.Dark
    Material.accent: DoorwayPalette.skyHint
    Material.primary: DoorwayPalette.skyHint
    Material.background: DoorwayPalette.hudCard
    Material.foreground: DoorwayPalette.hudText
    Material.containerStyle: Material.Outlined
    renderType: Text.QtRendering

    color: DoorwayPalette.hudText
    selectedTextColor: DoorwayPalette.inkBlack
    selectionColor: DoorwayPalette.skyHint
    placeholderTextColor: DoorwayPalette.hudTextDim
    clip: true

    font {
        family: Appearance.font.family.main
        pixelSize: Appearance?.font.pixelSize.small ?? 15
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }
    wrapMode: TextEdit.Wrap

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
    }
}
