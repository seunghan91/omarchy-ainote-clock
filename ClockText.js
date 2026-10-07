.pragma library

// All display strings live here; placeholders keep word order language-specific.
var STRINGS = {
  "ko": {
    "product": "AI Note",
    "notificationTitle": "AI Note Clock",
    "days": [
      "일",
      "월",
      "화",
      "수",
      "목",
      "금",
      "토"
    ],
    "fullDays": [
      "일",
      "월",
      "화",
      "수",
      "목",
      "금",
      "토"
    ],
    "months": [
      "1월",
      "2월",
      "3월",
      "4월",
      "5월",
      "6월",
      "7월",
      "8월",
      "9월",
      "10월",
      "11월",
      "12월"
    ],
    "shortMonths": [
      "1월",
      "2월",
      "3월",
      "4월",
      "5월",
      "6월",
      "7월",
      "8월",
      "9월",
      "10월",
      "11월",
      "12월"
    ],
    "am": "오전",
    "pm": "오후",
    "timeFormat": "{period} {hour}:{minute}",
    "dayFormat": "{month}월 {day}일({weekday})",
    "barFormat": "{header} {time}",
    "monthFormat": "{year}년 {month}월",
    "todaySuffix": " · 오늘",
    "addPlaceholder": "{month}월 {day}일에 할일 추가",
    "tooltip": "달력과 AI Note 할일",
    "badgeToday": "할일 {count}",
    "badgeOverdue": "밀림 {count}",
    "overdueHeading": "밀린 할일 {count}",
    "today": "오늘",
    "all": "전체",
    "todayCount": "오늘 {count}",
    "overdueCount": "밀린 {count}",
    "remainingCount": "남은 {count}",
    "offlineStatus": "오프라인 — {detail}\n완료·추가는 연결되면 다시 시도합니다.",
    "lastSyncDetail": "마지막 동기화 {date} {time} 기준.",
    "noSyncData": "아직 동기화한 데이터가 없어요.",
    "retry": "다시 시도",
    "approvalInstructions": "브라우저에서 아래 코드를 확인하고\n승인하면 할일이 여기에 뜹니다.",
    "openBrowser": "브라우저 열기",
    "cancel": "취소",
    "waitingApproval": "승인 기다리는 중… {countdown}",
    "loginIntro": "AI Note 할일을 달력에 함께 볼 수 있어요.",
    "reconnect": "다시 연결",
    "login": "AI Note 로그인",
    "noLoginNeeded": "연결하지 않아도 시계·달력은 그대로 씁니다.",
    "syncNote": "AI Note 웹·휴대폰 앱과 같은 계정으로 동기화됩니다.",
    "appWeb": "웹",
    "appIos": "iPhone",
    "appAndroid": "Android",
    "phoneSync": "휴대폰 연동",
    "phoneHint": "휴대폰 카메라로 QR을 찍으면 스토어가 열립니다.\n같은 AI Note 계정으로 로그인하면 할일이 동기화됩니다.",
    "openStore": "스토어 열기 ↗",
    "loadingTasks": "할일을 불러오는 중…",
    "emptyOverdue": "밀린 할일이 없습니다.",
    "emptyToday": "오늘 할일이 없습니다.",
    "emptyDay": "이날 할일이 없습니다.",
    "settings": "설정",
    "backCalendar": "← 달력",
    "calendar": "달력",
    "indicatorTitle": "바에 할일 표시",
    "indicatorNone": "표시 안 함",
    "indicatorNoneDescription": "시계만 (기본값)",
    "indicatorSplit": "남은 할일 · 밀린 할일",
    "indicatorSplitDescription": "할일 2 · 밀림 2 처럼 따로",
    "indicatorTotal": "합계 숫자 하나",
    "indicatorTotalDescription": "남은 것과 밀린 것을 합쳐서",
    "layoutTitle": "달력 패널 모양",
    "layoutVertical": "세로",
    "layoutVerticalDescription": "달력 위, 할일 아래 (기본값)",
    "layoutHorizontal": "가로 2단",
    "layoutHorizontalDescription": "달력 왼쪽, 할일 오른쪽",
    "weekStartTitle": "주 시작",
    "sunday": "일요일",
    "monday": "월요일",
    "defaultDescription": "기본값",
    "languageTitle": "언어",
    "languageAuto": "자동",
    "languageAutoDescription": "시스템 언어에 따라 선택 (기본값)",
    "languageKo": "한국어",
    "languageEn": "English",
    "languageZhHans": "简体中文",
    "languageZhHant": "繁體中文",
    "disconnected": "연결 안 됨",
    "logout": "로그아웃",
    "savedImmediately": "바뀐 값은 바로 적용·저장",
    "footer": "AI Note · {sync}",
    "openAINote": "AI Note 에서 열기 ↗",
    "countdown": "{time} 남음",
    "notSynced": "아직 동기화 전",
    "syncedNow": "방금 동기화",
    "syncedMinutes": "{count}분 전 동기화",
    "error_not_logged_in": "AI Note에 로그인해 주세요.",
    "error_auth_expired": "로그인이 만료됐어요. 다시 연결해 주세요.",
    "error_offline": "오프라인 — 연결되면 다시 시도해 주세요.",
    "error_key_limit": "AI Note 설정 > MCP 에서 키를 하나 지워 주세요.",
    "error_denied": "브라우저에서 연결이 거절됐어요.",
    "error_expired": "인증 시간이 끝났어요. 다시 연결해 주세요.",
    "error_bad_request": "입력한 할일을 확인해 주세요.",
    "error_server_error": "AI Note 요청을 처리하지 못했어요. 다시 시도해 주세요."
  },
  "en": {
    "product": "AI Note",
    "notificationTitle": "AI Note Clock",
    "days": [
      "Sun",
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat"
    ],
    "fullDays": [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday"
    ],
    "months": [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ],
    "shortMonths": [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ],
    "am": "AM",
    "pm": "PM",
    "timeFormat": "{hour}:{minute} {period}",
    "dayFormat": "{fullWeekday}, {monthName} {day}",
    "barFormat": "{weekday} {shortMonth} {day} {time}",
    "monthFormat": "{monthName} {year}",
    "todaySuffix": " · Today",
    "addPlaceholder": "Add a task for {shortMonth} {day}",
    "tooltip": "Calendar and AI Note tasks",
    "badgeToday": "Today {count}",
    "badgeOverdue": "Overdue {count}",
    "overdueHeading": "Overdue {count}",
    "today": "Today",
    "all": "All",
    "todayCount": "Today {count}",
    "overdueCount": "Overdue {count}",
    "remainingCount": "{count} left",
    "offlineStatus": "Offline — {detail}\nComplete or add tasks when connected.",
    "lastSyncDetail": "Last synced {date} at {time}.",
    "noSyncData": "No synced data yet.",
    "retry": "Retry",
    "approvalInstructions": "Confirm the code below in your browser.\nYour tasks will appear here after approval.",
    "openBrowser": "Open browser",
    "cancel": "Cancel",
    "waitingApproval": "Waiting for approval… {countdown}",
    "loginIntro": "See your AI Note tasks alongside the calendar.",
    "reconnect": "Reconnect",
    "login": "Sign in to AI Note",
    "noLoginNeeded": "The clock and calendar work without signing in.",
    "syncNote": "Syncs with the AI Note web and phone apps on the same account.",
    "appWeb": "Web",
    "appIos": "iPhone",
    "appAndroid": "Android",
    "phoneSync": "Phone apps",
    "phoneHint": "Scan with your phone camera to open the store.\nSign in with the same AI Note account to sync tasks.",
    "openStore": "Open store ↗",
    "loadingTasks": "Loading tasks…",
    "emptyOverdue": "No overdue tasks.",
    "emptyToday": "No tasks today.",
    "emptyDay": "No tasks for this day.",
    "settings": "Settings",
    "backCalendar": "← Calendar",
    "calendar": "Calendar",
    "indicatorTitle": "Tasks in the bar",
    "indicatorNone": "Hide tasks",
    "indicatorNoneDescription": "Clock only (default)",
    "indicatorSplit": "Today · Overdue",
    "indicatorSplitDescription": "Separate badges, e.g. Today 2 · Overdue 2",
    "indicatorTotal": "One total count",
    "indicatorTotalDescription": "Today and overdue tasks combined",
    "layoutTitle": "Calendar layout",
    "layoutVertical": "Vertical",
    "layoutVerticalDescription": "Calendar above tasks (default)",
    "layoutHorizontal": "Side by side",
    "layoutHorizontalDescription": "Calendar on the left, tasks on the right",
    "weekStartTitle": "Week starts on",
    "sunday": "Sunday",
    "monday": "Monday",
    "defaultDescription": "Default",
    "languageTitle": "Language",
    "languageAuto": "Auto",
    "languageAutoDescription": "Use the system language (default)",
    "languageKo": "한국어",
    "languageEn": "English",
    "languageZhHans": "简体中文",
    "languageZhHant": "繁體中文",
    "disconnected": "Not connected",
    "logout": "Sign out",
    "savedImmediately": "Changes apply and save immediately",
    "footer": "AI Note · {sync}",
    "openAINote": "Open AI Note ↗",
    "countdown": "{time} left",
    "notSynced": "not synced yet",
    "syncedNow": "synced just now",
    "syncedMinutes": "synced {count} min ago",
    "error_not_logged_in": "Please sign in to AI Note.",
    "error_auth_expired": "Your session has expired. Please reconnect.",
    "error_offline": "Offline — please try again when connected.",
    "error_key_limit": "Delete a key in AI Note Settings > MCP.",
    "error_denied": "The connection was denied in your browser.",
    "error_expired": "The sign-in code has expired. Please reconnect.",
    "error_bad_request": "Please check the task you entered.",
    "error_server_error": "AI Note could not process the request. Please try again."
  },
  "zh-Hans": {
    "product": "AI Note",
    "notificationTitle": "AI Note 时钟",
    "days": ["日", "一", "二", "三", "四", "五", "六"],
    "fullDays": ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"],
    "months": ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
    "shortMonths": ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
    "am": "上午",
    "pm": "下午",
    "timeFormat": "{period}{hour}:{minute}",
    "dayFormat": "{month}月{day}日 {fullWeekday}",
    "barFormat": "{month}月{day}日 周{weekday} {time}",
    "monthFormat": "{year}年{month}月",
    "todaySuffix": " · 今天",
    "addPlaceholder": "添加{month}月{day}日的待办",
    "tooltip": "日历和 AI Note 待办",
    "badgeToday": "待办 {count}",
    "badgeOverdue": "逾期 {count}",
    "overdueHeading": "逾期待办 {count}",
    "today": "今天",
    "all": "全部",
    "todayCount": "今天 {count}",
    "overdueCount": "逾期 {count}",
    "remainingCount": "剩余 {count} 项",
    "offlineStatus": "离线 — {detail}\n联网后可重试完成或添加待办。",
    "lastSyncDetail": "上次同步于{date} {time}。",
    "noSyncData": "暂无同步数据。",
    "retry": "重试",
    "approvalInstructions": "请在浏览器中确认以下验证码。\n授权后，待办将显示在这里。",
    "openBrowser": "打开浏览器",
    "cancel": "取消",
    "waitingApproval": "等待授权… {countdown}",
    "loginIntro": "在日历旁查看你的 AI Note 待办。",
    "reconnect": "重新连接",
    "login": "登录 AI Note",
    "noLoginNeeded": "无需登录即可使用时钟和日历。",
    "syncNote": "使用同一账号与 AI Note 网页版和手机 App 同步。",
    "appWeb": "网页版",
    "appIos": "iPhone",
    "appAndroid": "Android",
    "phoneSync": "手机 App",
    "phoneHint": "用手机相机扫描二维码打开应用商店。\n使用同一 AI Note 账号登录即可同步待办。",
    "openStore": "打开商店 ↗",
    "loadingTasks": "正在加载待办…",
    "emptyOverdue": "没有逾期待办。",
    "emptyToday": "今天没有待办。",
    "emptyDay": "当天没有待办。",
    "settings": "设置",
    "backCalendar": "← 日历",
    "calendar": "日历",
    "indicatorTitle": "在状态栏显示待办",
    "indicatorNone": "隐藏待办",
    "indicatorNoneDescription": "仅显示时钟（默认）",
    "indicatorSplit": "今日待办 · 逾期待办",
    "indicatorSplitDescription": "分别显示，如待办 2 · 逾期 2",
    "indicatorTotal": "显示总数",
    "indicatorTotalDescription": "合并今日待办和逾期待办的数量",
    "layoutTitle": "日历布局",
    "layoutVertical": "上下排列",
    "layoutVerticalDescription": "日历在上，待办在下（默认）",
    "layoutHorizontal": "左右排列",
    "layoutHorizontalDescription": "日历在左，待办在右",
    "weekStartTitle": "每周起始日",
    "sunday": "星期日",
    "monday": "星期一",
    "defaultDescription": "默认",
    "languageTitle": "语言",
    "languageAuto": "自动",
    "languageAutoDescription": "使用系统语言（默认）",
    "languageKo": "한국어",
    "languageEn": "English",
    "languageZhHans": "简体中文",
    "languageZhHant": "繁體中文",
    "disconnected": "未连接",
    "logout": "退出登录",
    "savedImmediately": "更改立即生效并保存",
    "footer": "AI Note · {sync}",
    "openAINote": "在 AI Note 中打开 ↗",
    "countdown": "剩余 {time}",
    "notSynced": "尚未同步",
    "syncedNow": "刚刚同步",
    "syncedMinutes": "{count} 分钟前同步",
    "error_not_logged_in": "请登录 AI Note。",
    "error_auth_expired": "登录已过期，请重新连接。",
    "error_offline": "离线 — 请在联网后重试。",
    "error_key_limit": "请在 AI Note 设置 > MCP 中删除一个密钥。",
    "error_denied": "连接请求已在浏览器中被拒绝。",
    "error_expired": "验证码已过期，请重新连接。",
    "error_bad_request": "请检查输入的待办内容。",
    "error_server_error": "AI Note 无法处理请求，请重试。"
  },
  "zh-Hant": {
    "product": "AI Note",
    "notificationTitle": "AI Note 時鐘",
    "days": ["日", "一", "二", "三", "四", "五", "六"],
    "fullDays": ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"],
    "months": ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
    "shortMonths": ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
    "am": "上午",
    "pm": "下午",
    "timeFormat": "{period}{hour}:{minute}",
    "dayFormat": "{month}月{day}日 {fullWeekday}",
    "barFormat": "{month}月{day}日 週{weekday} {time}",
    "monthFormat": "{year}年{month}月",
    "todaySuffix": " · 今天",
    "addPlaceholder": "新增{month}月{day}日的待辦事項",
    "tooltip": "行事曆與 AI Note 待辦事項",
    "badgeToday": "待辦 {count}",
    "badgeOverdue": "逾期 {count}",
    "overdueHeading": "逾期待辦事項 {count}",
    "today": "今天",
    "all": "全部",
    "todayCount": "今天 {count}",
    "overdueCount": "逾期 {count}",
    "remainingCount": "剩餘 {count} 項",
    "offlineStatus": "離線 — {detail}\n連線後可重試完成或新增待辦事項。",
    "lastSyncDetail": "上次同步於{date} {time}。",
    "noSyncData": "尚無同步資料。",
    "retry": "重試",
    "approvalInstructions": "請在瀏覽器中確認以下驗證碼。\n授權後，待辦事項將顯示在這裡。",
    "openBrowser": "開啟瀏覽器",
    "cancel": "取消",
    "waitingApproval": "等待授權… {countdown}",
    "loginIntro": "在行事曆旁查看你的 AI Note 待辦事項。",
    "reconnect": "重新連線",
    "login": "登入 AI Note",
    "noLoginNeeded": "無須登入即可使用時鐘和行事曆。",
    "syncNote": "使用同一帳號與 AI Note 網頁版和手機 App 同步。",
    "appWeb": "網頁版",
    "appIos": "iPhone",
    "appAndroid": "Android",
    "phoneSync": "手機 App",
    "phoneHint": "用手機相機掃描 QR 碼開啟商店。\n使用同一 AI Note 帳號登入即可同步待辦事項。",
    "openStore": "開啟商店 ↗",
    "loadingTasks": "正在載入待辦事項…",
    "emptyOverdue": "沒有逾期待辦事項。",
    "emptyToday": "今天沒有待辦事項。",
    "emptyDay": "當天沒有待辦事項。",
    "settings": "設定",
    "backCalendar": "← 行事曆",
    "calendar": "行事曆",
    "indicatorTitle": "在狀態列顯示待辦事項",
    "indicatorNone": "隱藏待辦事項",
    "indicatorNoneDescription": "僅顯示時鐘（預設）",
    "indicatorSplit": "今日待辦 · 逾期待辦",
    "indicatorSplitDescription": "分別顯示，如待辦 2 · 逾期 2",
    "indicatorTotal": "顯示總數",
    "indicatorTotalDescription": "合併今日待辦與逾期待辦的數量",
    "layoutTitle": "行事曆版面配置",
    "layoutVertical": "上下排列",
    "layoutVerticalDescription": "行事曆在上，待辦事項在下（預設）",
    "layoutHorizontal": "左右並排",
    "layoutHorizontalDescription": "行事曆在左，待辦事項在右",
    "weekStartTitle": "每週起始日",
    "sunday": "星期日",
    "monday": "星期一",
    "defaultDescription": "預設",
    "languageTitle": "語言",
    "languageAuto": "自動",
    "languageAutoDescription": "使用系統語言（預設）",
    "languageKo": "한국어",
    "languageEn": "English",
    "languageZhHans": "简体中文",
    "languageZhHant": "繁體中文",
    "disconnected": "未連線",
    "logout": "登出",
    "savedImmediately": "變更立即套用並儲存",
    "footer": "AI Note · {sync}",
    "openAINote": "在 AI Note 中開啟 ↗",
    "countdown": "剩餘 {time}",
    "notSynced": "尚未同步",
    "syncedNow": "剛剛同步",
    "syncedMinutes": "{count} 分鐘前同步",
    "error_not_logged_in": "請登入 AI Note。",
    "error_auth_expired": "登入已過期，請重新連線。",
    "error_offline": "離線 — 請在連線後重試。",
    "error_key_limit": "請在 AI Note 設定 > MCP 中刪除一個金鑰。",
    "error_denied": "連線要求已在瀏覽器中遭到拒絕。",
    "error_expired": "驗證碼已過期，請重新連線。",
    "error_bad_request": "請檢查輸入的待辦事項內容。",
    "error_server_error": "AI Note 無法處理要求，請重試。"
  }
}

// Keep the original helper default for callers; the UI always passes its resolved language.
function strings(lang) { return Object.prototype.hasOwnProperty.call(STRINGS, lang) ? STRINGS[lang] : STRINGS.ko }
function format(template, values) {
  // A missing key renders as "" instead of throwing and blanking the whole binding.
  if (typeof template !== "string") return ""
  return template.replace(/\{(\w+)\}/g, function(match, key) {
    return values && values[key] !== undefined ? String(values[key]) : match
  })
}
function text(lang, key, values) { return format(strings(lang)[key], values) }
// AI Note on the web and in the stores; the same account syncs everywhere.
// Store links never change, so their QR codes ship pre-rendered in assets/.
var WEB_URL = "https://app.ainote.dev"
var STORE_APPS = [
  { key: "appIos", glyph: "\uf179", url: "https://apps.apple.com/app/id6799343264", qr: "assets/qr-ios.png" },
  { key: "appAndroid", glyph: "\udb80\udebc", url: "https://play.google.com/store/apps/details?id=com.dcodelabs.ainote", qr: "assets/qr-android.png" }
]
function languageSetting(value) { return ["auto", "en", "ko", "zh-Hans", "zh-Hant"].indexOf(value) >= 0 ? value : "auto" }
function chineseLanguage(tag) {
  if (/Hant/i.test(tag)) return "zh-Hant"
  if (!/^zh/i.test(tag)) return ""
  return /(?:^|[-_])(TW|HK|MO)(?:$|[-_.@])/i.test(tag) ? "zh-Hant" : "zh-Hans"
}
function resolveLanguage(value, locale) {
  value = languageSetting(value)
  if (value !== "auto") return value
  if (locale && /^ko/i.test(locale.name || "")) return "ko"
  var languages = locale && locale.uiLanguages ? locale.uiLanguages : []
  for (var i = 0; i < languages.length; i++) if (/^ko/i.test(languages[i])) return "ko"
  // Preserve Korean detection; otherwise prefer the locale name, then UI-language order.
  var chinese = chineseLanguage(locale && locale.name || "")
  if (chinese) return chinese
  for (var j = 0; j < languages.length; j++) {
    chinese = chineseLanguage(languages[j])
    if (chinese) return chinese
  }
  return "en"
}
function pad2(n) { return (n < 10 ? "0" : "") + n }
function ymd(date) { return date.getFullYear() + "-" + pad2(date.getMonth() + 1) + "-" + pad2(date.getDate()) }
function parseDate(value) {
  var parts = value.split("-").map(Number)
  return new Date(parts[0], parts[1] - 1, parts[2], 12)
}
function dateValues(date, lang) {
  var s = strings(lang)
  return { year: date.getFullYear(), month: date.getMonth() + 1, day: date.getDate(),
    weekday: s.days[date.getDay()], fullWeekday: s.fullDays[date.getDay()],
    monthName: s.months[date.getMonth()], shortMonth: s.shortMonths[date.getMonth()] }
}
function timeLabel(value, lang) {
  var parts = value.split(":").map(Number)
  var s = strings(lang)
  return format(s.timeFormat, {period: parts[0] < 12 ? s.am : s.pm, hour: parts[0] % 12 || 12, minute: pad2(parts[1])})
}
function dayHeader(value, isToday, lang) {
  return text(lang, "dayFormat", dateValues(parseDate(value), lang)) + (isToday ? strings(lang).todaySuffix : "")
}
function barLabel(date, lang) {
  var values = dateValues(date, lang)
  values.header = dayHeader(ymd(date), false, lang)
  values.time = timeLabel(date.getHours() + ":" + date.getMinutes(), lang)
  return text(lang, "barFormat", values)
}
function verticalLabel(date) { return pad2(date.getHours()) + "\n—\n" + pad2(date.getMinutes()) }
// Months are zero-based, matching JavaScript Date and the built-in clock.
function monthTitle(year, month, lang) { return text(lang, "monthFormat", {year: year, month: month + 1, monthName: strings(lang).months[month]}) }
function shortDate(value) { var date = parseDate(value); return (date.getMonth() + 1) + "/" + date.getDate() }
function addPlaceholder(value, lang) { return text(lang, "addPlaceholder", dateValues(parseDate(value), lang)) }
function weekdayLabels(weekStart, lang) {
  var days = strings(lang).days
  return weekStart === "monday" ? days.slice(1).concat(days[0]) : days.slice()
}
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
if (typeof module !== "undefined") module.exports = { barLabel: barLabel, monthTitle: monthTitle, dayHeader: dayHeader, timeLabel: timeLabel, shortDate: shortDate, monthGrid: monthGrid, weekdayLabels: weekdayLabels, ymd: ymd, verticalLabel: verticalLabel, pad2: pad2, strings: strings, format: format, text: text, languageSetting: languageSetting, resolveLanguage: resolveLanguage, addPlaceholder: addPlaceholder }
