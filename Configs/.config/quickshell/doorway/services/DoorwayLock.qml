pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

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
    function load() {
        relockCheck.running = true;
    }

    // ── Crash recovery ──
    // A marker in XDG_RUNTIME_DIR survives a shell crash (Restart=always
    // brings us back in ~1s); if it exists at startup, the previous instance
    // died while locked — re-assert the lock before anyone sees the desktop.
    // (The compositor held the dead client's lock the whole time; this puts
    // a live surface back on it.)
    readonly property string markerPath: Quickshell.env("XDG_RUNTIME_DIR") + "/doorway/locked"

    Process {
        id: relockCheck
        command: ["test", "-f", root.markerPath]
        onExited: exitCode => {
            if (exitCode === 0) {
                console.log("[DoorwayLock] relock marker found — re-asserting lock after restart");
                root.lock();
            }
        }
    }

    // integration-test escape hatch: DOORWAY_LOCK_AUTOUNLOCK_SECS=N force-
    // unlocks N seconds after locking. Unset in production, so inert.
    Timer {
        id: autoUnlock
        interval: (parseInt(Quickshell.env("DOORWAY_LOCK_AUTOUNLOCK_SECS") ?? "") || 0) * 1000
        running: root.locked && interval > 0
        onTriggered: {
            console.log("[DoorwayLock] auto-unlock escape hatch fired");
            root.unlock();
        }
    }

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
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "${0%/*}" && touch "$0"', markerPath]);
        setLockedHint(true);
        state = Config.options.lock.intro.enable ? stateIntro : stateScreensaver;
    }

    // logind's LockedHint lets loginctl/other tooling see the lock state;
    // hyprlock sets it too, so we match. "auto" = the caller's own session.
    function setLockedHint(locked) {
        Quickshell.execDetached(["busctl", "call", "org.freedesktop.login1",
            "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session",
            "SetLockedHint", "b", locked ? "true" : "false"]);
    }

    // intro finished playing (or was skipped by a keypress)
    function introFinished() {
        if (state === stateIntro) state = stateScreensaver;
    }

    // any user activity while the screensaver plays
    function wake() {
        if (state === stateIntro) introFinished();
        else if (state === stateScreensaver) state = statePrompt;
        else if (state === statePrompt) promptIdle.restart();
    }

    // prompt idle timeout — drop back into the show, forget the buffer
    function sleep() {
        if (state === statePrompt) {
            passwordBuffer = "";
            state = stateScreensaver;
        }
    }

    function unlock() {
        passwordBuffer = "";
        authFailed = false;
        Quickshell.execDetached(["rm", "-f", markerPath]);
        setLockedHint(false);
        state = stateInactive;
    }

    // ── Password buffer + PAM ──
    // The buffer lives here (not in a TextInput) so every monitor's panel
    // mirrors it and the surfaces stay display-only.
    property string passwordBuffer: ""
    property bool authFailed: false
    property string failMessage: ""

    onPasswordBufferChanged: {
        GlobalStates.screenLockContainsCharacters = passwordBuffer.length > 0;
        if (passwordBuffer.length > 0) promptIdle.restart();
    }

    // key routing from the surfaces: printable chars wake AND type
    function typeText(text) {
        if (!locked || text.length === 0) return;
        if (state === stateIntro) {
            introFinished();
            return;
        }
        if (state === stateScreensaver) state = statePrompt;
        if (state === statePrompt) {
            authFailed = false;
            passwordBuffer += text;
        }
    }

    function backspace() {
        if (state === statePrompt)
            passwordBuffer = passwordBuffer.slice(0, -1);
    }

    function submit() {
        if (state !== statePrompt || passwordBuffer.length === 0) return;
        state = stateAuthenticating;
        if (!pam.start()) {
            failMessage = "PAM UNAVAILABLE";
            authFail();
        }
    }

    function authFail() {
        GlobalStates.screenUnlockFailed = true;
        passwordBuffer = "";
        authFailed = true;
        if (locked) state = statePrompt;
    }

    PamContext {
        id: pam
        config: "login" // NixOS ships /etc/pam.d/login; there is no hyprlock entry
        user: Quickshell.env("USER")

        onPamMessage: {
            // the password prompt: answer with the buffer, never echo it
            if (this.responseRequired) this.respond(root.passwordBuffer);
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                GlobalStates.screenUnlockFailed = false;
                root.failMessage = "";
                root.unlock();
            } else {
                root.failMessage = result === PamResult.MaxTries
                    ? "TOO MANY TRIES" : "WRONG — TRY AGAIN";
                root.authFail();
            }
        }
        onError: () => {
            root.failMessage = "AUTH ERROR";
            root.authFail();
        }
    }

    Timer {
        id: promptIdle
        interval: Config.options.lock.prompt.returnToScreensaverSeconds * 1000
        running: root.state === root.statePrompt
        onTriggered: root.sleep()
    }

    // Controllers bypass Wayland, so the lock surface never sees them; this
    // watcher reads the joystick device directly while locked and emits
    // "wake" lines. An Atari console should wake to a joystick wiggle.
    Process {
        running: root.locked
        command: [Quickshell.env("HOME") + "/.local/lib/doorway/doorway-lock-controller-watch.sh"]
        stdout: SplitParser {
            onRead: root.wake()
        }
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
        // side-channel wake — this is what the controller watcher (evdev
        // events never reach the Wayland lock surface) calls on any input
        function wake(): void {
            root.wake();
        }
        function nextShader(): void {
            root.rollShader();
        }
        function status(): string {
            return ["inactive", "intro", "screensaver", "prompt", "authenticating"][root.state];
        }

        // dev-only (inert unless the instance runs as the test harness):
        // lets the harness be driven end-to-end from the CLI, PAM included
        function devType(text: string): void {
            if (Quickshell.env("DOORWAY_LOCK_TEST") === "1") root.typeText(text);
        }
        function devSubmit(): void {
            if (Quickshell.env("DOORWAY_LOCK_TEST") === "1") root.submit();
        }
    }
}
