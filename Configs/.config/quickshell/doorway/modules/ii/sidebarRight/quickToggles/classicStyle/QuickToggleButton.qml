import qs.modules.common
import qs.modules.common.widgets
import QtQuick

PlasticKey {
    id: button
    property string buttonIcon
    baseWidth: 40
    baseHeight: 40
    toggled: false
    ledColor: DoorwayPalette.ledGold

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        iconSize: 22
        fill: toggled ? 1 : 0
        color: toggled ? DoorwayPalette.agedPaper : Appearance.colors.colOnLayer1
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: buttonIcon

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

}
