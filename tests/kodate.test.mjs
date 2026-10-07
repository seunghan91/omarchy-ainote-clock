import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

// Node does not parse QML directives; strip only the library directive.
const source = fs.readFileSync(new URL('../KoDate.js', import.meta.url), 'utf8').replace(/^\.pragma library\s*\n/, '');
const context = { module: { exports: {} } };
vm.runInNewContext(source, context);
const k = context.module.exports;
let count = 0;
function eq(actual, expected) { assert.deepEqual(JSON.parse(JSON.stringify(actual)), expected); count++; }
eq(k.barLabel(new Date(2026, 9, 7, 0, 5)), '10월 7일(수) 오전 12:05');
eq(k.barLabel(new Date(2026, 9, 7, 12, 0)), '10월 7일(수) 오후 12:00');
eq(k.barLabel(new Date(2026, 9, 7, 23, 59)), '10월 7일(수) 오후 11:59');
eq(k.barLabel(new Date(2026, 9, 7, 13, 56)), '10월 7일(수) 오후 1:56');
eq(k.monthTitle(2026, 9), '2026년 10월');
eq(k.dayHeader('2026-10-07', true), '10월 7일(수) · 오늘');
eq(k.timeLabel('15:00'), '오후 3:00');
eq(k.shortDate('2026-10-05'), '10/5');
eq(k.ymd(new Date(2026, 0, 1)), '2026-01-01');
eq(k.verticalLabel(new Date(2026, 9, 7, 0, 5)), '00\n—\n05');
eq(k.weekdayLabels('monday'), ['월', '화', '수', '목', '금', '토', '일']);
eq(k.weekdayLabels('sunday'), ['일', '월', '화', '수', '목', '금', '토']);
for (const [year, month, days] of [[2026, 0, 31], [2026, 1, 28], [2026, 3, 30], [2028, 1, 29], [2026, 11, 31]]) {
  const grid = k.monthGrid(year, month, 'sunday');
  eq(grid.length, 42);
  eq(grid.filter(c => c.inMonth).length, days);
  eq(grid[0].dow, 0);
  eq(new Set(grid.map(c => c.date)).size, 42);
}
const monday = k.monthGrid(2026, 9, 'monday');
eq(monday[0], { date: '2026-09-28', day: 28, inMonth: false, dow: 1 });
eq(monday[41].date, '2026-11-08');
eq(k.monthGrid(2026, 0, 'sunday')[0].date, '2025-12-28');
eq(k.monthGrid(2026, 11, 'sunday')[41].date, '2027-01-09');
console.log(`PASS ${count} / FAIL 0 — KoDate`);
