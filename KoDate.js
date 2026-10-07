.pragma library

var DAYS = ["일", "월", "화", "수", "목", "금", "토"]
function pad2(n) { return (n < 10 ? "0" : "") + n }
function ymd(date) { return date.getFullYear() + "-" + pad2(date.getMonth() + 1) + "-" + pad2(date.getDate()) }
function parseDate(value) {
  var parts = value.split("-").map(Number)
  return new Date(parts[0], parts[1] - 1, parts[2], 12)
}
function timeLabel(value) {
  var parts = value.split(":").map(Number)
  return (parts[0] < 12 ? "오전 " : "오후 ") + (parts[0] % 12 || 12) + ":" + pad2(parts[1])
}
function dayHeader(value, isToday) {
  var date = parseDate(value)
  return (date.getMonth() + 1) + "월 " + date.getDate() + "일(" + DAYS[date.getDay()] + ")" + (isToday ? " · 오늘" : "")
}
function barLabel(date) { return dayHeader(ymd(date), false) + " " + timeLabel(date.getHours() + ":" + date.getMinutes()) }
function verticalLabel(date) { return pad2(date.getHours()) + "\n—\n" + pad2(date.getMinutes()) }
// Months are zero-based, matching JavaScript Date and the built-in clock.
function monthTitle(year, month) { return year + "년 " + (month + 1) + "월" }
function shortDate(value) { var date = parseDate(value); return (date.getMonth() + 1) + "/" + date.getDate() }
function weekdayLabels(weekStart) { return weekStart === "monday" ? DAYS.slice(1).concat(DAYS[0]) : DAYS.slice() }
function monthGrid(year, month, weekStart) {
  var first = new Date(year, month, 1, 12)
  var offset = (first.getDay() - (weekStart === "monday" ? 1 : 0) + 7) % 7
  var cells = []
  for (var i = 0; i < 42; i++) {
    var date = new Date(year, month, 1 - offset + i, 12)
    cells.push({ date: ymd(date), day: date.getDate(), inMonth: date.getMonth() === month, dow: date.getDay() })
  }
  return cells
}
if (typeof module !== "undefined") module.exports = { barLabel: barLabel, monthTitle: monthTitle, dayHeader: dayHeader, timeLabel: timeLabel, shortDate: shortDate, monthGrid: monthGrid, weekdayLabels: weekdayLabels, ymd: ymd, verticalLabel: verticalLabel }
