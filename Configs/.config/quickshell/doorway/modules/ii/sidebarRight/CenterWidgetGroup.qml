import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.sidebarRight.notifications
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

HudPanel {
    id: root

    NotificationList {
        anchors.fill: parent
        anchors.margins: 5
    }
}
