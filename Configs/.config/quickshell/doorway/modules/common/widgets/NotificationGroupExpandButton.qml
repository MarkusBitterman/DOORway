import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

RippleButton { // Expand button
    id: root
    required property int count
    required property bool expanded
    // Boardroom (sidebar) styling — fixed hud tokens, not the mode scheme.
    property bool hud: false
    property real fontSize: Appearance?.font.pixelSize.small ?? 12
    property real iconSize: Appearance?.font.pixelSize.normal ?? 16
    implicitHeight: fontSize + 4 * 2
    implicitWidth: Math.max(contentItem.implicitWidth + 5 * 2, 30)
    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: false

    buttonRadius: hud ? 3 : Appearance.rounding.full
    colBackground: hud ? Qt.rgba(1, 1, 1, 0.06) : ColorUtils.mix(Appearance?.colors.colLayer2, Appearance?.colors.colLayer2Hover, 0.5)
    colBackgroundHover: hud ? Qt.rgba(1, 1, 1, 0.10) : (Appearance?.colors.colLayer2Hover ?? "#E5DFED")
    colRipple: hud ? Qt.rgba(1, 1, 1, 0.14) : (Appearance?.colors.colLayer2Active ?? "#D6CEE2")

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: contentRow.implicitWidth
        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 3
            StyledText {
                Layout.leftMargin: 4
                visible: root.count > 1
                text: root.count
                font.pixelSize: root.fontSize
                color: root.hud ? DoorwayPalette.hudTextDim : Appearance.colors.colOnLayer1
            }
            MaterialSymbol {
                text: "keyboard_arrow_down"
                iconSize: root.iconSize
                color: root.hud ? DoorwayPalette.hudTextDim : Appearance.colors.colOnLayer2
                rotation: expanded ? 180 : 0
                Behavior on rotation {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}
