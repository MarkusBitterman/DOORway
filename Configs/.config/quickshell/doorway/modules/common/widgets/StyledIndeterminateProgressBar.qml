import qs.modules.common
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls

ProgressBar {
    indeterminate: true
    // Cool scan accent — activity, not "now" (gold stays reserved for the current entry).
    Material.accent: DoorwayPalette.skyHint
}
