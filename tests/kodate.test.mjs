import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

// Node does not parse QML directives; strip only the library directive.
const source = fs.readFileSync(new URL('../ClockText.js', import.meta.url), 'utf8').replace(/^\.pragma library\s*\n/, '');
const context = { module: { exports: {} } };
vm.runInNewContext(source, context);
const k = context.module.exports;
let count = 0;
function eq(actual, expected) { assert.deepEqual(JSON.parse(JSON.stringify(actual)), expected); count++; }
eq(k.barLabel(new Date(2026, 9, 7, 0, 5), 'ko'), '10월 7일(수) 오전 12:05');
eq(k.barLabel(new Date(2026, 9, 7, 12, 0), 'ko'), '10월 7일(수) 오후 12:00');
eq(k.barLabel(new Date(2026, 9, 7, 23, 59), 'ko'), '10월 7일(수) 오후 11:59');
eq(k.barLabel(new Date(2026, 9, 7, 13, 56), 'ko'), '10월 7일(수) 오후 1:56');
eq(k.monthTitle(2026, 9, 'ko'), '2026년 10월');
eq(k.dayHeader('2026-10-07', true, 'ko'), '10월 7일(수) · 오늘');
eq(k.timeLabel('15:00', 'ko'), '오후 3:00');
eq(k.shortDate('2026-10-05'), '10/5');
eq(k.ymd(new Date(2026, 0, 1)), '2026-01-01');
eq(k.verticalLabel(new Date(2026, 9, 7, 0, 5)), '00\n—\n05');
eq(k.weekdayLabels('monday', 'ko'), ['월', '화', '수', '목', '금', '토', '일']);
eq(k.weekdayLabels('sunday', 'ko'), ['일', '월', '화', '수', '목', '금', '토']);
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
console.log(`PASS ${count} / FAIL 0 — ClockText (existing ko cases)`);
const koCount = count;

// English dates, including midnight/noon and Sunday/Monday calendar headers.
eq(k.timeLabel('0:05', 'en'), '12:05 AM');
eq(k.timeLabel('12:00', 'en'), '12:00 PM');
eq(k.timeLabel('23:59', 'en'), '11:59 PM');
eq(k.timeLabel('15:00', 'en'), '3:00 PM');
eq(k.barLabel(new Date(2026, 9, 7, 0, 5), 'en'), 'Wed Oct 7 12:05 AM');
eq(k.barLabel(new Date(2026, 9, 7, 12, 0), 'en'), 'Wed Oct 7 12:00 PM');
eq(k.barLabel(new Date(2026, 9, 7, 23, 59), 'en'), 'Wed Oct 7 11:59 PM');
eq(k.barLabel(new Date(2026, 9, 7, 13, 56), 'en'), 'Wed Oct 7 1:56 PM');
eq(k.monthTitle(2026, 9, 'en'), 'October 2026');
eq(k.dayHeader('2026-10-07', false, 'en'), 'Wednesday, October 7');
eq(k.dayHeader('2026-10-07', true, 'en'), 'Wednesday, October 7 · Today');
eq(k.weekdayLabels('sunday', 'en'), ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']);
eq(k.weekdayLabels('monday', 'en'), ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
eq(k.shortDate('2026-10-05', 'en'), '10/5');
eq(k.verticalLabel(new Date(2026, 9, 7, 0, 5), 'en'), '00\n—\n05');
eq(k.addPlaceholder('2026-10-07', 'en'), 'Add a task for Oct 7');
eq(k.addPlaceholder('2026-10-07', 'ko'), '10월 7일에 할일 추가');

// Explicit language wins; absent UI-language APIs and invalid settings are safe.
eq(k.resolveLanguage('auto', {name: 'ko_KR'}), 'ko');
eq(k.resolveLanguage('auto', {name: 'en_US'}), 'en');
eq(k.resolveLanguage('auto', {name: 'en_US', uiLanguages: ['en-US', 'ko-KR']}), 'ko');
eq(k.resolveLanguage('auto', {name: 'en_US', uiLanguages: ['en-US']}), 'en');
eq(k.resolveLanguage('auto', {name: 'fr_FR', uiLanguages: []}), 'en');
eq(k.resolveLanguage('auto', undefined), 'en');
eq(k.resolveLanguage('en', {name: 'ko_KR', uiLanguages: ['ko-KR']}), 'en');
eq(k.resolveLanguage('ko', {name: 'en_US'}), 'ko');
eq(k.resolveLanguage('invalid', {name: 'ko_KR'}), 'ko');
eq(k.resolveLanguage('invalid', {name: 'en_US'}), 'en');
eq(k.languageSetting('auto'), 'auto');
eq(k.languageSetting('ko'), 'ko');
eq(k.languageSetting('en'), 'en');
eq(k.languageSetting('invalid'), 'auto');
eq(k.languageSetting(null), 'auto');

// Count interpolation, footer states, and templates preserve both languages.
eq(k.text('en', 'badgeToday', {count: 2}), 'Today 2');
eq(k.text('en', 'badgeOverdue', {count: 16}), 'Overdue 16');
eq(k.text('en', 'overdueHeading', {count: 16}), 'Overdue 16');
eq(k.text('ko', 'badgeToday', {count: 2}), '할일 2');
eq(k.text('ko', 'badgeOverdue', {count: 16}), '밀림 16');
eq(k.text('en', 'footer', {sync: k.text('en', 'syncedNow')}), 'AI Note · synced just now');
eq(k.text('en', 'footer', {sync: k.text('en', 'syncedMinutes', {count: 5})}), 'AI Note · synced 5 min ago');
eq(k.text('ko', 'syncedMinutes', {count: 5}), '5분 전 동기화');
eq(k.text('en', 'countdown', {time: '1:05'}), '1:05 left');
eq(k.text('ko', 'countdown', {time: '1:05'}), '1:05 남음');
eq(k.text('en', 'error_key_limit'), 'Delete a key in AI Note Settings > MCP.');
eq(k.text('ko', 'error_auth_expired'), '로그인이 만료됐어요. 다시 연결해 주세요.');
// A missing translation or mismatched placeholder must fail before shipping.
eq(Object.keys(k.strings('ko')).sort(), Object.keys(k.strings('en')).sort());
for (const key of Object.keys(k.strings('ko'))) {
  const placeholders = value => String(value).match(/\{\w+\}/g)?.sort() || [];
  // Date templates intentionally have different fields and word order.
  if (!['dayFormat', 'barFormat', 'monthFormat', 'addPlaceholder'].includes(key)) {
    eq(placeholders(k.strings('ko')[key]), placeholders(k.strings('en')[key]));
  }
}
console.log(`PASS ${count - koCount} / FAIL 0 — ClockText (en, locale, UI strings)`);
const enCount = count;

for (const [lang, week, auto, notification] of [
  ['zh-Hans', '周', '自动', 'AI Note 时钟'],
  ['zh-Hant', '週', '自動', 'AI Note 時鐘'],
]) {
  for (const [hour, minute, expected] of [[0, 5, '上午12:05'], [12, 0, '下午12:00'], [23, 59, '下午11:59'], [13, 56, '下午1:56']]) {
    eq(k.timeLabel(`${hour}:${minute}`, lang), expected);
    eq(k.barLabel(new Date(2026, 9, 7, hour, minute), lang), `10月7日 ${week}三 ${expected}`);
  }
  eq(k.timeLabel('15:00', lang), '下午3:00');
  eq(k.monthTitle(2026, 9, lang), '2026年10月');
  eq(k.dayHeader('2026-10-07', false, lang), '10月7日 星期三');
  eq(k.dayHeader('2026-10-07', true, lang), '10月7日 星期三 · 今天');
  eq(k.weekdayLabels('sunday', lang), ['日', '一', '二', '三', '四', '五', '六']);
  eq(k.weekdayLabels('monday', lang), ['一', '二', '三', '四', '五', '六', '日']);
  eq(k.shortDate('2026-10-05', lang), '10/5');
  eq(k.verticalLabel(new Date(2026, 9, 7, 0, 5), lang), '00\n—\n05');
  eq(k.languageSetting(lang), lang);
  eq(k.resolveLanguage(lang, {name: 'ko_KR', uiLanguages: ['ko-KR']}), lang);
  eq(k.text(lang, 'languageAuto'), auto);
  eq(k.text(lang, 'notificationTitle'), notification);
  eq(k.text(lang, 'badgeOverdue', {count: 16}), '逾期 16');
  eq(k.text(lang, 'footer', {sync: k.text(lang, 'notSynced')}), 'AI Note · 尚未同步');
}
eq(k.addPlaceholder('2026-10-07', 'zh-Hans'), '添加10月7日的待办');
eq(k.addPlaceholder('2026-10-07', 'zh-Hant'), '新增10月7日的待辦事項');
eq(k.text('zh-Hans', 'error_key_limit'), '请在 AI Note 设置 > MCP 中删除一个密钥。');
eq(k.text('zh-Hant', 'error_key_limit'), '請在 AI Note 設定 > MCP 中刪除一個金鑰。');

// Test both Qt locale sources, scripts, regions, case, and invalid settings.
for (const [tag, expected] of [
  ['zh_TW', 'zh-Hant'], ['zh_HK', 'zh-Hant'], ['zh_MO', 'zh-Hant'],
  ['zh-TW', 'zh-Hant'], ['ZH_hk', 'zh-Hant'], ['zh-Hans-TW', 'zh-Hant'],
  ['zh_CN', 'zh-Hans'], ['zh-SG', 'zh-Hans'], ['zh', 'zh-Hans'],
  ['zh-Hans', 'zh-Hans'], ['zh-Hans-CN', 'zh-Hans'],
  ['zh-Hant', 'zh-Hant'], ['zh_Hant_CN', 'zh-Hant'], ['zh-hant-CN', 'zh-Hant'],
  ['ko-KR', 'ko'], ['KO_kr', 'ko'], ['ja_JP', 'en'],
]) {
  eq(k.resolveLanguage('auto', {name: tag}), expected);
  eq(k.resolveLanguage('auto', {name: 'en_US', uiLanguages: ['en-US', tag]}), expected);
  eq(k.resolveLanguage('invalid', {name: tag}), expected);
}
eq(k.resolveLanguage('auto', {uiLanguages: ['zh-Hant']}), 'zh-Hant');
eq(k.resolveLanguage('auto', {name: 'zh_CN', uiLanguages: ['ko-KR']}), 'ko');
eq(k.resolveLanguage('auto', {name: 'zh_TW', uiLanguages: ['zh-CN']}), 'zh-Hant');
eq(k.resolveLanguage('auto', {name: 'en_US', uiLanguages: ['zh-Hant', 'zh-Hans']}), 'zh-Hant');
eq(k.resolveLanguage('en', {name: 'zh_TW'}), 'en');
eq(k.resolveLanguage('ko', {name: 'zh_CN'}), 'ko');
for (const invalid of ['zh', 'zh_CN', 'zh-hant', '', null, undefined, 'constructor']) {
  eq(k.languageSetting(invalid), 'auto');
  eq(k.resolveLanguage(invalid, {name: 'zh_HK'}), 'zh-Hant');
}

// Every table must be complete, with matching UI placeholders and language names.
const languages = ['en', 'ko', 'zh-Hans', 'zh-Hant'];
const keys = Object.keys(k.strings('en')).sort();
for (const lang of languages) {
  const table = k.strings(lang);
  eq(Object.keys(table).sort(), keys);
  eq(table.product, 'AI Note');
  eq([table.languageEn, table.languageKo, table.languageZhHans, table.languageZhHant], ['English', '한국어', '简体中文', '繁體中文']);
  for (const key of keys) {
    eq(typeof table[key], typeof k.strings('en')[key]);
    eq(String(table[key]).length > 0, true);
    if (!['dayFormat', 'barFormat', 'monthFormat', 'addPlaceholder'].includes(key)) {
      const placeholders = value => String(value).match(/\{\w+\}/g)?.sort() || [];
      eq(placeholders(table[key]), placeholders(k.strings('en')[key]));
    }
  }
}
console.log(`PASS ${count - enCount} / FAIL 0 — ClockText (Chinese, locale, four-language tables)`);
console.log(`PASS ${count} / FAIL 0 — ClockText (total)`);
