import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property string activeWindowAddress: `0x${activeWindow?.HyprlandToplevel?.address}`
    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    // Use this monitor's own active workspace id. HyprlandData.monitors is the raw
    // `hyprctl monitors -j` array in listing order, so indexing it by monitor id breaks
    // whenever array position != id (e.g. a HEADLESS-* monitor listed before HDMI-A-1) —
    // it would read the wrong workspace and fall back to "Desktop". monitor.activeWorkspace
    // is keyed correctly and already drives the fallback text below.
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(root.monitor?.activeWorkspace?.id)

    property string activeAppId: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow
        ? root.activeWindow?.appId ?? ""
        : root.biggestWindow?.class ?? ""

    // A "label" plate stuck to the top of the bar: background tinted from the app icon,
    // outlined on the sides and bottom (never the top), rounded only at the bottom corners,
    // with app/title text auto-contrasted to the tint. Pure styling — no graphics.
    readonly property color labelColor: IconColor.get(root.activeAppId)
    readonly property color borderColor: ColorUtils.mix(labelColor, "#000000", 0.45)
    readonly property bool darkLabel: ColorUtils.isDark(labelColor)
    readonly property color textPrimary: darkLabel ? DoorwayPalette.agedPaper : DoorwayPalette.inkBlack
    readonly property color textSecondary: ColorUtils.transparentize(textPrimary, 0.30)

    property int labelRadius: Appearance.rounding.small
    property int hpad: 10

    implicitWidth: rowLayout.implicitWidth + hpad * 2

    onActiveAppIdChanged: IconColor.request(root.activeAppId)
    Component.onCompleted: IconColor.request(root.activeAppId)

    // Soft shadow so the plate lifts off the wood even when the icon tint is close to it.
    StyledRectangularShadow { target: labelBorder }

    // Label plate — border colour behind, tinted fill inset on 3 sides (flush at top).
    Rectangle {
        id: labelBorder
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width
        color: root.borderColor
        radius: root.labelRadius       // base radius (shadow follows this)
        topLeftRadius: 0               // …but the top stays square (label hangs from the top edge)
        topRightRadius: 0
        Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }

        Rectangle {
            id: labelFill
            anchors.fill: parent
            anchors.topMargin: 0
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            anchors.bottomMargin: 1
            color: root.labelColor
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: Math.max(0, root.labelRadius - 1)
            bottomRightRadius: Math.max(0, root.labelRadius - 1)
            Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.hpad
        anchors.rightMargin: root.hpad
        spacing: 6

        CustomIcon {
            id: appIcon
            Layout.preferredWidth: Appearance.font.pixelSize.normal * 1.4
            Layout.preferredHeight: Appearance.font.pixelSize.normal * 1.4
            Layout.alignment: Qt.AlignVCenter
            source: root.activeAppId
            visible: valid
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: -4

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.textSecondary
                elide: Text.ElideRight
                text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ?
                    root.activeWindow?.appId :
                    (root.biggestWindow?.class) ?? Translation.tr("Desktop")
            }

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.textPrimary
                elide: Text.ElideRight
                text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ?
                    root.activeWindow?.title :
                    (root.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`
            }
        }
    }
}
