pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs
import qs.modules.common

/**
 * DOORway Lock — state machine + shared choreography for the shader-screensaver
 * lock screen. The visual layer (modules/ii/lock) is per-monitor; everything a
 * surface renders is driven from here so all monitors mirror exactly.
 *
 * States: INACTIVE → INTRO (signal cutout) → SCREENSAVER → PROMPT → AUTHENTICATING.
 * PAM auth and the real WlSessionLock binding arrive in later phases; until then
 * lock()/unlock() drive the harness (DOORWAY_LOCK_TEST=1).
 *
 * IPC:  qs -c doorway ipc --any-display call lock lock|unlock|status|nextShader
 */
Singleton {
    id: root

    // Eager-touched from shell.qml — without this the IpcHandler of a lazy
    // singleton never registers (see ThemeMode/Hyprsunset).
    function load() {}

    // ── State machine ──
    readonly property int stateInactive: 0
    readonly property int stateIntro: 1
    readonly property int stateScreensaver: 2
    readonly property int statePrompt: 3
    readonly property int stateAuthenticating: 4
    property int state: stateInactive
    readonly property bool locked: state !== stateInactive

    onLockedChanged: GlobalStates.screenLocked = locked

    function lock() {
        if (locked) return;
        rollShader();
        state = Config.options.lock.intro.enable ? stateIntro : stateScreensaver;
    }

    // intro finished playing (or was skipped by a keypress)
    function introFinished() {
        if (state === stateIntro) state = stateScreensaver;
    }

    // any user activity while the screensaver plays
    function wake() {
        if (state === stateIntro) introFinished();
        else if (state === stateScreensaver) state = statePrompt;
    }

    // prompt idle timeout — drop back into the show, forget the buffer
    function sleep() {
        if (state === statePrompt) state = stateScreensaver;
    }

    function unlock() {
        state = stateInactive;
    }

    // ── Shader schedule (shared so every monitor shows the same frame) ──
    readonly property list<string> shaderNames: [
        "dungeon_entrance",
        "koholint_ocean",
        "lost_woods",
        "time_gate",
        "diagnostic_screen",
        "scroll_text",
        "castle_fireworks",
    ]
    property int currentShaderIndex: 0
    readonly property string currentShaderName: shaderNames[currentShaderIndex]

    function rollShader() {
        const pinned = shaderNames.indexOf(Config.options.lock.screensaver.shader);
        if (pinned >= 0) {
            currentShaderIndex = pinned;
            return;
        }
        // random, but never the one already playing
        let next = Math.floor(Math.random() * shaderNames.length);
        if (next === currentShaderIndex) next = (next + 1) % shaderNames.length;
        currentShaderIndex = next;
    }

    Timer {
        id: rotation
        interval: Math.max(1, Config.options.lock.screensaver.cycleIntervalSeconds) * 1000
        repeat: true
        // 0 = pinned for the whole lock; rotation keeps running behind the prompt
        running: root.locked && root.state !== root.stateIntro
            && Config.options.lock.screensaver.cycleIntervalSeconds > 0
            && Config.options.lock.screensaver.shader === "random"
        onTriggered: root.rollShader()
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
        function unlock(): void {
            root.unlock();
        }
        function nextShader(): void {
            root.rollShader();
        }
        function status(): string {
            return ["inactive", "intro", "screensaver", "prompt", "authenticating"][root.state];
        }
    }
}
