import QtQuick
import QtTest
import "../../quickshell/components"
import "../../quickshell/components/dashboard"
import "../../quickshell/components/dashboard/CalendarMath.js" as CalendarMath

Item {
    width: 1000; height: 700
    Bar { id: bar; width: 1000; height: 34; timeText: "12:30" }
    CalendarCard { id: calendar; y: 50; width: 350; today: new Date(2024, 1, 29, 12) }
    SignalSpy { id: clockSpy; target: bar; signalName: "dashboardRequested" }
    TestCase {
        name: "Dashboard"
        when: windowShown
        function test_clock_click_and_keyboard() {
            clockSpy.clear();
            mouseClick(bar, 500, 17);
            compare(clockSpy.count, 1);
            keyClick(Qt.Key_Space);
            compare(clockSpy.count, 2);
        }
        function test_leap_year_grid() {
            compare(CalendarMath.cell(2024, 1, 0).getDate(), 29);
            compare(CalendarMath.cell(2024, 1, 0).getMonth(), 0);
            const leapDay = CalendarMath.cell(2024, 1, 31);
            compare(leapDay.getDate(), 29);
            compare(leapDay.getMonth(), 1);
        }
        function test_monday_first_and_year_boundary() {
            compare(CalendarMath.firstCell(2026, 5).getDay(), 1);
            compare(CalendarMath.firstCell(2026, 5).getDate(), 1);
            calendar.year = 2025; calendar.month = 11;
            calendar.moveMonth(1);
            compare(calendar.year, 2026); compare(calendar.month, 0);
            calendar.moveMonth(-1);
            compare(calendar.year, 2025); compare(calendar.month, 11);
            calendar.reset();
            compare(calendar.month, 1); compare(calendar.year, 2024);
            verify(CalendarMath.sameDay(calendar.selectedDate, calendar.today));
        }
        function test_date_comparison_includes_year() {
            verify(!CalendarMath.sameDay(new Date(2024, 1, 29), new Date(2028, 1, 29)));
        }
    }
}
