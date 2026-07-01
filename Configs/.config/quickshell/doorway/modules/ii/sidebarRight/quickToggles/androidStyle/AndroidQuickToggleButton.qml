import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.functions
import qs.modules.common.widgets

PlasticKey {
    id: root

    // Info to be passed to by repeater
    required property int buttonIndex
    required property var buttonData
    required property bool expandedSize
    required property real baseCellWidth
    required property real baseCellHeight
    required property real cellSpacing
    required property int cellSize

    // Signals
    signal openMenu()

    // Declared in specific toggles
    property QuickToggleModel toggleModel
    property string name: toggleModel?.name ?? ""
    property string statusText: (toggleModel?.hasStatusText) ? (toggleModel?.statusText || (toggled ? Translation.tr("On") : Translation.tr("Off"))) : ""
    property string tooltipText: toggleModel?.tooltipText ?? ""
    property string buttonIcon: toggleModel?.icon ?? "close"
    property bool available: toggleModel?.available ?? true
    toggled: toggleModel?.toggled ?? false
    property var mainAction: toggleModel?.mainAction ?? null
    altAction: toggleModel?.hasMenu ? (() => root.openMenu()) : (toggleModel?.altAction ?? null)

    ledColor: DoorwayPalette.ledGold

    // Edit mode state
    property bool editMode: false

    // Sizing shenanigans
    baseWidth: root.baseCellWidth * cellSize + cellSpacing * (cellSize - 1)
    baseHeight: root.baseCellHeight
    enableImplicitWidthAnimation: !editMode && root.mouseArea.containsMouse
    enableImplicitHeightAnimation: !editMode && root.mouseArea.containsMouse
    Behavior on baseWidth {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    Behavior on baseHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    opacity: 0
    Component.onCompleted: {
        opacity = 1
    }
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    enabled: available || editMode
    padding: 6
    horizontalPadding: padding
    verticalPadding: padding

    // Cream-bright when ON (the LED carries the accent), dimmed paper when OFF/disabled.
    property color colText: (toggled && enabled) ? DoorwayPalette.agedPaper
        : ColorUtils.transparentize(Appearance.colors.colOnLayer2, enabled ? 0.15 : 0.7)
    property color colIcon: colText

    onClicked: {
        if (root.expandedSize && root.altAction) root.altAction();
        else root.mainAction();
    }

    contentItem: RowLayout {
        id: contentItem
        spacing: 4
        anchors {
            centerIn: root.expandedSize ? undefined : parent
            fill: root.expandedSize ? parent : undefined
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }

        // Icon. When expanded *and* the body opens a menu, the icon is a separate hit target
        // (mainAction), so it gets a recessed plastic sub-plate to read as its own button.
        MouseArea {
            id: iconMouseArea
            hoverEnabled: true
            acceptedButtons: (root.expandedSize && root.altAction) ? Qt.LeftButton : Qt.NoButton
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.topMargin: root.verticalPadding
            Layout.bottomMargin: root.verticalPadding
            implicitHeight: iconBackground.implicitHeight
            implicitWidth: iconBackground.implicitWidth
            cursorShape: Qt.PointingHandCursor

            onClicked: root.mainAction()

            Rectangle {
                id: iconBackground
                anchors.fill: parent
                implicitWidth: height
                radius: Math.max(2, root.radius - root.verticalPadding)
                // Only the separate-hit-target case gets a visible recessed plate.
                property bool subTarget: (root.altAction && root.expandedSize)
                visible: subTarget  // when false the plate (and its gradient) simply don't render
                gradient: Gradient {
                    GradientStop { position: 0.0; color: DoorwayPalette.plasticPanelTop }
                    GradientStop { position: 1.0; color: DoorwayPalette.plasticPanelBottom }
                }
                border.width: subTarget ? 1 : 0
                border.color: DoorwayPalette.plasticEdge

                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: root.toggled ? 1 : 0
                    iconSize: root.expandedSize ? 22 : 24
                    color: root.colIcon
                    text: root.buttonIcon

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }

                // Press/hover state layer on the icon sub-plate.
                Loader {
                    anchors.fill: parent
                    active: iconBackground.subTarget
                    sourceComponent: Rectangle {
                        radius: iconBackground.radius
                        color: ColorUtils.transparentize(DoorwayPalette.agedPaper, iconMouseArea.containsPress ? 0.85 : iconMouseArea.containsMouse ? 0.93 : 1)
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }
                }
            }
        }

        // Text column for expanded size
        Loader {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            visible: root.expandedSize
            active: visible
            sourceComponent: Column {
                spacing: -2

                StyledText {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    font.weight: 600
                    color: root.colText
                    elide: Text.ElideRight
                    text: root.name
                }

                StyledText {
                    visible: root.statusText
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    font {
                        pixelSize: Appearance.font.pixelSize.smaller
                        weight: 100
                    }
                    color: root.colText
                    elide: Text.ElideRight
                    text: root.statusText
                }
            }
        }
    }

    MouseArea { // Blocking MouseArea for edit interactions
        id: editModeInteraction
        visible: root.editMode
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons

        function toggleEnabled() {
            const index = root.buttonIndex;
            const toggleList = Config.options.sidebar.quickToggles.android.toggles;
            const buttonType = root.buttonData.type;
            if (!toggleList.find(toggle => toggle.type === buttonType)) {
                toggleList.push({ type: buttonType, size: 1 });
            } else {
                toggleList.splice(index, 1);
            }
        }

        function toggleSize() {
            const index = root.buttonIndex;
            const toggleList = Config.options.sidebar.quickToggles.android.toggles;
            const buttonType = root.buttonData.type;
            if (!toggleList.find(toggle => toggle.type === buttonType)) return;
            toggleList[index].size = 3 - toggleList[index].size; // Alternate between 1 and 2
        }

        function movePositionBy(offset) {
            const index = root.buttonIndex;
            const toggleList = Config.options.sidebar.quickToggles.android.toggles;
            const buttonType = root.buttonData.type;
            const targetIndex = index + offset;
            if (!toggleList.find(toggle => toggle.type === buttonType)) return;
            if (targetIndex < 0 || targetIndex >= toggleList.length) return;
            const temp = toggleList[index];
            toggleList[index] = toggleList[targetIndex];
            toggleList[targetIndex] = temp;
        }

        onReleased: (event) => {
            if (event.button === Qt.LeftButton)
                toggleEnabled();
        }
        onPressed: (event) => {
            if (event.button === Qt.RightButton) toggleSize();
        }
        onPressAndHold: (event) => { // Also toggle size
            toggleSize();
        }
        onWheel: (event) => {
            const index = root.buttonIndex;
            const toggleList = Config.options.sidebar.quickToggles.android.toggles;
            const buttonType = root.buttonData.type;
            if (event.angleDelta.y < 0) { // Move to right
                movePositionBy(1);
            } else if (event.angleDelta.y > 0) { // Move to left
                movePositionBy(-1);
            }
            event.accepted = true;
        }
    }

    StyledToolTip {
        extraVisibleCondition: root.tooltipText !== ""
        text: root.tooltipText
    }
}
