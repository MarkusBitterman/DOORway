pragma Singleton
pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    id: root
    property var clock: SystemClock {
        id: clock
        precision: {
            if (Config.options.time.secondPrecision || GlobalStates.screenLocked)
                return SystemClock.Seconds;
            return SystemClock.Minutes;
        }
    }
    // Whether a clock reads 5:41 pm or 17:41 is a property of the locale, not a preference:
    // Qt's short time format answers it directly — "h:mm Ap" for en_US, "HH:mm" for
    // en_GB/de_DE/fr_FR, "H:mm" for ja_JP. The meridiem is lowercased because the bar has
    // always read "5:41 pm"; the locale decides 12-vs-24, the design decides capitalization.
    readonly property string localeTimeFormat: Qt.locale().timeFormat(Locale.ShortFormat).replace(/AP/gi, "ap")

    // "auto" follows the locale; anything else is an explicit override, matching the sentinel
    // that Config.options.language.ui already uses.
    readonly property string timeFormat: {
        const configured = Config.options?.time.format ?? "auto";
        return (configured === "auto" || configured === "") ? root.localeTimeFormat : configured;
    }

    property string time: Qt.locale().toString(clock.date, root.timeFormat)

    // shortDate ("dd/MM") and date ("dd/MM/yyyy") lived here with nothing reading them —
    // day-before-month strings that would have been wrong in the US the moment anything did.
    // longDate was dead too. Removed rather than left as a trap; longDateOrdinal below is
    // the one the bar actually renders.

    property string dayOrdinal: {
        // English-only suffix. Gluing "st"/"nd"/"th" onto a German or Japanese date is worse
        // than omitting it, so non-English locales get the bare date.
        if (!Qt.locale().name.startsWith("en")) return ""
        const day = clock.date.getDate()
        if (day >= 11 && day <= 13) return "th"
        switch (day % 10) {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
        }
    }
    property string longDateOrdinal: Qt.locale().toString(clock.date, Config.options?.time.dateFormat ?? "ddd, MMM d") + dayOrdinal
    property string collapsedCalendarFormat: Qt.locale().toString(clock.date, "dddd, MMMM dd")
    property string uptime: "0h, 0m"

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            fileUptime.reload();
            const textUptime = fileUptime.text();
            const uptimeSeconds = Number(textUptime.split(" ")[0] ?? 0);

            // Convert seconds to days, hours, and minutes
            const days = Math.floor(uptimeSeconds / 86400);
            const hours = Math.floor((uptimeSeconds % 86400) / 3600);
            const minutes = Math.floor((uptimeSeconds % 3600) / 60);

            // Build the formatted uptime string
            let formatted = "";
            if (days > 0)
                formatted += `${days}d`;
            if (hours > 0)
                formatted += `${formatted ? ", " : ""}${hours}h`;
            if (minutes > 0 || !formatted)
                formatted += `${formatted ? ", " : ""}${minutes}m`;
            uptime = formatted;
            interval = Config.options?.resources?.updateInterval ?? 3000;
        }
    }

    FileView {
        id: fileUptime

        path: "/proc/uptime"
    }
}
