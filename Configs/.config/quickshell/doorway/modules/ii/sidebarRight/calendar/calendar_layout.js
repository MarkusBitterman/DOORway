// Which day starts the week is locale-dependent — Sunday across the Americas and much of
// Asia, Monday across most of Europe, Saturday across much of the Middle East. Upstream
// hardcoded Monday; the caller now passes the locale's answer instead.
//
// `firstDay` is a weekday index on the 0 = Sunday … 6 = Saturday scale, which is what both
// JS `Date.getDay()` and QML `Locale.firstDayOfWeek` use — so the value can be handed
// straight from one to the other with no remapping.

function checkLeapYear(year) {
    return (
        year % 400 == 0 ||
        (year % 4 == 0 && year % 100 != 0));
}

function getMonthDays(month, year) {
    const leapYear = checkLeapYear(year);
    if ((month <= 7 && month % 2 == 1) || (month >= 8 && month % 2 == 0)) return 31;
    if (month == 2 && leapYear) return 29;
    if (month == 2 && !leapYear) return 28;
    return 30;
}

// These used to re-derive the month-length parity rule shifted by one, and both got it
// wrong at the July/August seam — where the 31-day run breaks the alternation. getPrevMonthDays
// claimed July had 30 days, so every August drew its greyed-out leading days off by one
// (Jul 25-30 instead of 26-31). Delegating to getMonthDays with the month stepped is the
// same answer without a second copy of the rule to get wrong.

function getNextMonthDays(month, year) { // month is 1-based
    return month === 12 ? getMonthDays(1, year + 1) : getMonthDays(month + 1, year);
}

function getPrevMonthDays(month, year) { // month is 1-based
    return month === 1 ? getMonthDays(12, year - 1) : getMonthDays(month - 1, year);
}

function getDateInXMonthsTime(x) {
    var currentDate = new Date(); // Get the current date
    if (x == 0) return currentDate; // If x is 0, return the current date

    var targetMonth = currentDate.getMonth() + x; // Calculate the target month
    var targetYear = currentDate.getFullYear(); // Get the current year

    // Adjust the year and month if necessary
    targetYear += Math.floor(targetMonth / 12);
    targetMonth = (targetMonth % 12 + 12) % 12;

    // Create a new date object with the target year and month
    var targetDate = new Date(targetYear, targetMonth, 1);

    // Set the day to the last day of the month to get the desired date
    // targetDate.setDate(0);

    return targetDate;
}

function getCalendarLayout(dateObject, highlight, firstDay) {
    if (!dateObject) dateObject = new Date();
    if (firstDay === undefined) firstDay = 1; // Monday, the historical default
    // Column index of this date, counted from whichever day the locale starts the week on.
    const weekday = (dateObject.getDay() - firstDay + 7) % 7;
    const day = dateObject.getDate();
    const month = dateObject.getMonth() + 1;
    const year = dateObject.getFullYear();
    const weekdayOfMonthFirst = (weekday + 35 - (day - 1)) % 7;
    const daysInMonth = getMonthDays(month, year);
    const daysInNextMonth = getNextMonthDays(month, year);
    const daysInPrevMonth = getPrevMonthDays(month, year);

    // Fill
    var monthDiff = (weekdayOfMonthFirst == 0 ? 0 : -1);
    var toFill, dim;
    if (weekdayOfMonthFirst == 0) {
        toFill = 1;
        dim = daysInMonth;
    }
    else {
        toFill = (daysInPrevMonth - (weekdayOfMonthFirst - 1));
        dim = daysInPrevMonth;
    }
    var calendar = [...Array(6)].map(() => Array(7));
    var i = 0, j = 0;
    while (i < 6 && j < 7) {
        calendar[i][j] = {
            "day": toFill,
            "today": ((toFill == day && monthDiff == 0 && highlight) ? 1 : (
                monthDiff == 0 ? 0 : -1
            ))
        };
        // Increment
        toFill++;
        if (toFill > dim) { // Next month?
            monthDiff++;
            if (monthDiff == 0)
                dim = daysInMonth;
            else if (monthDiff == 1)
                dim = daysInNextMonth;
            toFill = 1;
        }
        // Next tile
        j++;
        if (j == 7) {
            j = 0;
            i++;
        }

    }
    return calendar;
}
