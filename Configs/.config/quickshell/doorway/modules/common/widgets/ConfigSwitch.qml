import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RippleButton {
    id: root
    property string buttonIcon
    property alias iconSize: iconWidget.iconSize

    Layout.fillWidth: true
    implicitHeight: contentItem.implicitHeight + 8 * 2
    font.pixelSize: Appearance.font.pixelSize.small
    
    onClicked: checked = !checked

    // Only consumer is the boardroom NightLightDialog — fixed hud tokens keep the
    // row legible over the dark card in both cartridge modes.
    buttonRadius: 3
    colBackgroundHover: DoorwayPalette.hudHover

    contentItem: RowLayout {
        spacing: 10
        OptionalMaterialSymbol {
            id: iconWidget
            icon: root.buttonIcon
            color: DoorwayPalette.hudTextDim
            opacity: root.enabled ? 1 : 0.4
            iconSize: Appearance.font.pixelSize.larger
        }
        StyledText {
            id: labelWidget
            Layout.fillWidth: true
            text: root.text
            font: root.font
            color: DoorwayPalette.hudText
            opacity: root.enabled ? 1 : 0.4
        }
        StyledSwitch {
            id: switchWidget
            down: root.down
            Layout.fillWidth: false
            checked: root.checked
            // Gold when enabled ("now"); recessed hud well when off.
            activeColor: DoorwayPalette.powerGold
            inactiveColor: DoorwayPalette.hudWell
            onClicked: root.clicked()
        }
    }
}

