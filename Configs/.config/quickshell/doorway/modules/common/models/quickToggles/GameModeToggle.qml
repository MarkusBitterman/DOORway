import QtQuick
import qs.services

/**
 * Right-sidebar quick toggle for game mode.
 *
 * Presentation only — behaviour and state live in services/GameMode.qml so this
 * button and the Super+ALT+G keybind cannot drift apart. `toggled` is a binding
 * on the service's derived state rather than a local flag, so the button also
 * follows changes made from the keybind or over IPC. (It previously assigned
 * `root.toggled` imperatively, which broke the binding and left the button
 * showing stale state after any external change.)
 */
QuickToggleModel {
    id: root
    name: Translation.tr("Game mode")
    toggled: GameMode.enabled
    icon: "gamepad"

    mainAction: () => GameMode.toggle()

    tooltipText: Translation.tr("Game mode")
}
