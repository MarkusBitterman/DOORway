import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.sidebarRight.notifications
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    radius: Appearance.rounding.verysmall
    gradient: Gradient {
        GradientStop { position: 0.0; color: DoorwayPalette.plasticPanelTop }
        GradientStop { position: 1.0; color: DoorwayPalette.plasticPanelBottom }
    }
    border.width: 1
    border.color: DoorwayPalette.plasticEdge

    NotificationList {
        anchors.fill: parent
        anchors.margins: 5
    }
}
