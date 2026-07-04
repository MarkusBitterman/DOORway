pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick.Effects
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

MouseArea {
    id: root
    required property SystemTrayItem item
    property bool targetMenuOpen: false

    signal menuOpened(qsWindow: var)
    signal menuClosed()

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: 20
    implicitHeight: 20
    onPressed: (event) => {
        switch (event.button) {
        case Qt.LeftButton:
            item.activate();
            break;
        case Qt.RightButton:
            if (item.hasMenu)
                if (menu.active && menu.item && typeof menu.item.close === "function")
                    menu.item.close();
                else 
                    menu.open();
            break;
        }
        event.accepted = true;
    }
    onEntered: {
        tooltip.text = TrayService.getTooltipForItem(root.item);
    }

    Loader {
        id: menu
        function open() {
            menu.active = true;
        }
        active: false
        sourceComponent: SysTrayMenu {
            Component.onCompleted: this.open();
            trayItemMenuHandle: root.item.menu
            trayItemId: root.item.id
            anchor {
                window: root.QsWindow.window
                item: root
                gravity: Config.options.bar.vertical
                    ? (Config.options.bar.bottom ? Edges.Left : Edges.Right)
                    : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
                edges: Config.options.bar.vertical
                    ? (Config.options.bar.bottom ? Edges.Left : Edges.Right)
                    : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
            }
            onMenuOpened: (window) => root.menuOpened(window);
            onMenuClosed: {
                root.menuClosed();
                menu.active = false;
            }
        }
    }

    IconImage {
        id: trayIcon
        // opacity:0 keeps the item renderable so MultiEffect can use it as source.
        // visible:false would silently prevent MultiEffect from producing any output.
        opacity: Config.options.tray.monochromeIcons ? 0 : 1
        source: root.item.icon
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
    }

    // Symbolic tray icons, engraved into the wood: a light catch-light on the lower-right
    // lip under a dark symbolic face — matches the bar's InsetSymbol. Also flattens colourful
    // applets (nm-applet, blueman, …) into clean monochrome glyphs.
    MultiEffect { // lower-right catch light
        visible: Config.options.tray.monochromeIcons
        source: trayIcon
        width: trayIcon.width
        height: trayIcon.height
        x: trayIcon.x + 1
        y: trayIcon.y + 1
        saturation: -1.0
        colorization: 1.0
        colorizationColor: Qt.rgba(1, 1, 1, 0.32)
    }
    MultiEffect { // dark symbolic face
        anchors.fill: trayIcon
        visible: Config.options.tray.monochromeIcons
        source: trayIcon
        saturation: -1.0
        colorization: 1.0
        colorizationColor: DoorwayPalette.inkBlack
    }

    PopupToolTip {
        id: tooltip
        extraVisibleCondition: root.containsMouse
        alternativeVisibleCondition: extraVisibleCondition
        anchorEdges: (!Config.options.bar.bottom && !Config.options.bar.vertical) ? Edges.Bottom : Edges.Top
    }

}
