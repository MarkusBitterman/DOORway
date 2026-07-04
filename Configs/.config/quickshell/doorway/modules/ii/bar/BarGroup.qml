import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool vertical: false
    property real padding: 5
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (gridLayout.implicitWidth + padding * 2)
    implicitHeight: vertical ? (gridLayout.implicitHeight + padding * 2) : Appearance.sizes.baseBarHeight
    default property alias items: gridLayout.children

    Rectangle {
        id: background
        readonly property bool plastic: !(Config.options?.bar.borderless ?? false)
        anchors {
            fill: parent
            topMargin: root.vertical ? 0 : 4
            bottomMargin: root.vertical ? 0 : 4
            leftMargin: root.vertical ? 4 : 0
            rightMargin: root.vertical ? 4 : 0
        }
        radius: Appearance.rounding.verysmall // squarer molded block
        // Recessed plastic panel inset into the faceplate (tones follow DoorwayPalette's mode).
        gradient: Gradient {
            GradientStop { position: 0.0; color: background.plastic ? DoorwayPalette.plasticPanelTop : "transparent" }
            GradientStop { position: 1.0; color: background.plastic ? DoorwayPalette.plasticPanelBottom : "transparent" }
        }
        border.width: background.plastic ? 1 : 0
        border.color: DoorwayPalette.plasticEdge
        // Bevel INVERTED for an inset look — the well is recessed into the wood, so the
        // top inner edge is shadowed and the bottom inner edge catches light.
        Rectangle {
            visible: background.plastic
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
            height: 1
            color: DoorwayPalette.bevelShadow
        }
        Rectangle {
            visible: background.plastic
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 2 }
            height: 1
            color: DoorwayPalette.bevelHighlight
        }
    }

    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors {
            verticalCenter: root.vertical ? undefined : parent.verticalCenter
            horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            left: root.vertical ? undefined : parent.left
            right: root.vertical ? undefined : parent.right
            top: root.vertical ? parent.top : undefined
            bottom: root.vertical ? parent.bottom : undefined
            margins: root.padding
        }
        columnSpacing: 4
        rowSpacing: 12
    }
}