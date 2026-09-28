.pragma library

function firstCell(year, month) {
    const first = new Date(year, month, 1, 12);
    return new Date(year, month, 1 - (first.getDay() + 6) % 7, 12);
}
function cell(year, month, index) {
    const first = firstCell(year, month);
    return new Date(first.getFullYear(), first.getMonth(), first.getDate() + index, 12);
}
function sameDay(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}
