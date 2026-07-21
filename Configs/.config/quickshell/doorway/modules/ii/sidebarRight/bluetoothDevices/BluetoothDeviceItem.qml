import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

DialogListItem {
    id: root
    required property var device
    property bool expanded: false
    pointingHandCursor: !expanded

    onClicked: expanded = !expanded
    altAction: () => expanded = !expanded
    
    // Flat hairline text commands (DialogButton hud defaults); destructive/paired
    // variants recolor per instance below.
    component ActionButton: DialogButton {}

    contentItem: ColumnLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 0

        RowLayout {
            // Name
            spacing: 10

            MaterialSymbol {
                iconSize: Appearance.font.pixelSize.larger
                text: Icons.getBluetoothDeviceMaterialSymbol(root.device?.icon || "")
                color: DoorwayPalette.hudTextDim
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    color: DoorwayPalette.hudText
                    elide: Text.ElideRight
                    text: root.device?.name || Translation.tr("Unknown device")
                    textFormat: Text.PlainText
                }
                StyledText {
                    visible: (root.device?.connected || root.device?.paired) ?? false
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: DoorwayPalette.hudTextDim
                    elide: Text.ElideRight
                    text: {
                        if (!root.device?.paired) return "";
                        let statusText = root.device?.connected ? Translation.tr("Connected") : Translation.tr("Paired");
                        if (!root.device?.batteryAvailable) return statusText;
                        statusText += ` • ${Math.round(root.device?.battery * 100)}%`;
                        return statusText;
                    }
                }
            }

            MaterialSymbol {
                text: "keyboard_arrow_down"
                iconSize: Appearance.font.pixelSize.larger
                color: DoorwayPalette.hudTextDim
                rotation: root.expanded ? 180 : 0
                Behavior on rotation {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }

        RowLayout {
            visible: root.expanded
            Layout.topMargin: 8
            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                readonly property bool p: root.device?.paired ?? false
                // "Forget" is destructive → red text; "Always connect" is a normal command.
                colText: p ? DoorwayPalette.redBright : DoorwayPalette.hudText
                colBackgroundHover: p ? Qt.rgba(DoorwayPalette.redBright.r, DoorwayPalette.redBright.g, DoorwayPalette.redBright.b, 0.14) : DoorwayPalette.hudHover
                colRipple: p ? Qt.rgba(DoorwayPalette.redBright.r, DoorwayPalette.redBright.g, DoorwayPalette.redBright.b, 0.22) : DoorwayPalette.hudHoverStrong

                buttonText: p ? Translation.tr("Forget") : Translation.tr("Always connect")
                onClicked: {
                    if (root.device?.paired) {
                        root.device?.forget();
                    } else {
                        root.device?.pair();
                    }
                }
            }
            ActionButton {
                buttonText: root.device?.connected ? Translation.tr("Disconnect") : Translation.tr("Connect")

                onClicked: {
                    if (root.device?.connected) {
                        root.device.disconnect();
                    } else {
                        root.device.connect();
                    }
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
    }
}
