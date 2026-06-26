import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    // maskSource must be a visual-tree item with layer.enabled so MultiEffect
    // gets a real offscreen texture. Inline property objects have no scene graph
    // node and produce a transparent mask, hiding the entire listview.
    Rectangle {
        id: listviewMask
        width: listview.width
        height: listview.height
        radius: Appearance.rounding.normal
        visible: false
        layer.enabled: true
    }

    NotificationListView { // Scrollable window
        id: listview
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: statusRow.top
        anchors.bottomMargin: 5

        clip: true
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: listviewMask
        }

        popup: false
    }

    // Placeholder when list is empty
    PagePlaceholder {
        shown: Notifications.list.length === 0
        icon: "notifications_active"
        description: Translation.tr("Nothing")
        shape: MaterialShape.Shape.Ghostish
        descriptionHorizontalAlignment: Text.AlignHCenter
    }

    ButtonGroup {
        id: statusRow
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        NotificationStatusButton {
            Layout.fillWidth: false
            buttonIcon: "notifications_paused"
            toggled: Notifications.silent
            onClicked: () => {
                Notifications.silent = !Notifications.silent;
            }
        }
        NotificationStatusButton {
            enabled: false
            Layout.fillWidth: true
            buttonText: Translation.tr("%1 notifications").arg(Notifications.list.length)
        }
        NotificationStatusButton {
            Layout.fillWidth: false
            buttonIcon: "delete_sweep"
            onClicked: () => {
                Notifications.discardAllNotifications()
            }
        }
    }
}