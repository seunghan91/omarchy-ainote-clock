import QtQuick
import Quickshell
import Quickshell.Io
import "KoDate.js" as KoDate

Item {
  id: root
  visible: false
  property bool panelOpen: false
  property string taskIndicator: "none"
  property string month: KoDate.ymd(new Date()).slice(0, 7)
  property string today: KoDate.ymd(new Date())
  property bool loggedIn: false
  property string email: ""
  property string connectionState: "disconnected"
  property string errorCode: ""
  property var cache: ({})
  property var overdueTasks: []
  property double lastSync: 0
  property string syncedToday: ""
  property var busy: ({})
  property int generation: 0
  property bool refreshQueued: false
  property bool refreshing: false
  property bool mutating: false
  property bool authBusy: false
  property bool cancelRequested: false
  property string userCode: ""
  property string verificationUrl: ""
  property double loginDeadline: 0
  property int pollSeconds: 5
  property double now: Date.now()
  readonly property int remaining: Math.max(0, Math.ceil((loginDeadline - now) / 1000))
  readonly property string countdown: Math.floor(remaining / 60) + ":" + KoDate.pad2(remaining % 60) + " 남음"
  readonly property bool online: loggedIn && connectionState === "connected"
  readonly property bool badgeReady: online && syncedToday === today && cache[today.slice(0, 7)] !== undefined
  readonly property var tasks: cache[month] || []
  readonly property int todayPending: (cache[today.slice(0, 7)] || []).filter(function(t) { return t.date === root.today && !t.completed }).length
  readonly property int overdueCount: overdueTasks.filter(function(t) { return !t.completed && t.date < root.today }).length
  readonly property string syncLabel: !lastSync ? "아직 동기화 전" : now - lastSync < 60000 ? "방금 동기화" : Math.floor((now - lastSync) / 60000) + "분 전 동기화"
  readonly property string helperPath: decodeURIComponent(String(Qt.resolvedUrl("bin/ainote-clock")).replace(/^file:\/\//, ""))
  signal added()

  function markBusy(kind, value) {
    var next = Object.assign({}, busy)
    next[kind] = value
    busy = next
  }
  function call(kind, args, input, done) {
    if (busy[kind]) return false
    markBusy(kind, true)
    var request = requestComponent.createObject(root, { argv: [helperPath].concat(args), input: input, callback: function(result) {
      root.markBusy(kind, false)
      done(result)
    } })
    request.running = true
    return true
  }
  function errorMessage(code) {
    var messages = {
      not_logged_in: "ainote에 로그인해 주세요.", auth_expired: "로그인이 만료됐어요. 다시 연결해 주세요.",
      offline: "오프라인 — 연결되면 다시 시도해 주세요.", key_limit: "ainote 설정 > MCP 에서 키를 하나 지워 주세요.",
      denied: "브라우저에서 연결이 거절됐어요.", expired: "인증 시간이 끝났어요. 다시 연결해 주세요.",
      bad_request: "입력한 할일을 확인해 주세요.", server_error: "ainote 요청을 처리하지 못했어요. 다시 시도해 주세요."
    }
    return messages[code] || messages.server_error
  }
  function fail(result) {
    errorCode = result.error || "server_error"
    if (errorCode === "auth_expired" || errorCode === "not_logged_in") {
      loggedIn = false
      connectionState = errorCode === "auth_expired" ? "auth_expired" : "disconnected"
    } else if (errorCode === "offline" || errorCode === "server_error") {
      connectionState = "offline"
    }
  }
  function notifyFailure(result) {
    Quickshell.execDetached(["omarchy-notification-send", "ainote 시계", errorMessage(result.error)])
  }
  function checkStatus() {
    if (authBusy || connectionState === "waiting") return
    var epoch = generation
    call("status", ["status"], "", function(result) {
      if (epoch !== root.generation) return
      if (!result.ok) { root.fail(result); return }
      root.loggedIn = result.loggedIn === true
      root.email = result.email || ""
      if (root.loggedIn) root.refresh()
      else { root.connectionState = "disconnected"; root.cache = ({}); root.overdueTasks = []; root.lastSync = 0; root.syncedToday = "" }
    })
  }
  function requestRefresh() { generation++; refresh() }
  function refresh() {
    if (!loggedIn || authBusy) return
    if (refreshing || mutating) { refreshQueued = true; return }
    refreshing = true
    refreshQueued = false
    var epoch = generation
    var viewMonth = month
    var currentMonth = today.slice(0, 7)
    var months = viewMonth === currentMonth ? [viewMonth] : [viewMonth, currentMonth]
    var results = {}
    function finish(result) {
      root.refreshing = false
      if (epoch === root.generation) {
        if (result.ok) {
          var next = Object.assign({}, root.cache)
          for (var key in results) next[key] = results[key]
          root.cache = next
          root.overdueTasks = result.tasks || []
          root.lastSync = Date.now()
          root.syncedToday = root.today
          root.connectionState = "connected"
          root.errorCode = ""
        } else root.fail(result)
      }
      if (root.refreshQueued) Qt.callLater(root.refresh)
    }
    function nextMonth() {
      if (epoch !== root.generation) { finish({ok: false}); return }
      if (!months.length) {
        root.call("read", ["overdue", "--before", root.today], "", finish)
        return
      }
      var key = months.shift()
      var parts = key.split("-").map(Number)
      // Cover both Sunday/Monday 42-cell grids, including adjacent-month dots.
      var from = KoDate.ymd(new Date(parts[0], parts[1] - 1, -5, 12))
      var end = KoDate.ymd(new Date(parts[0], parts[1] - 1, 42, 12))
      root.call("read", ["list", "--from", from, "--to", end], "", function(result) {
        if (!result.ok) { finish(result); return }
        results[key] = result.tasks || []
        nextMonth()
      })
    }
    nextMonth()
  }
  function replaceCompleted(id, completed) {
    function replace(tasks) { return tasks.map(function(t) { return t.id === id ? Object.assign({}, t, {completed: completed}) : t }) }
    var next = {}
    for (var key in cache) next[key] = replace(cache[key])
    cache = next
    overdueTasks = replace(overdueTasks)
  }
  function toggleTask(task) {
    if (!online || mutating || authBusy) return
    mutating = true
    generation++
    replaceCompleted(task.id, !task.completed)
    call("mutation", [task.completed ? "undone" : "done", String(task.id)], "", function(result) {
      root.mutating = false
      if (!result.ok) {
        root.replaceCompleted(task.id, task.completed)
        root.fail(result)
        root.notifyFailure(result)
      }
      root.requestRefresh()
    })
  }
  function addTask(date, content) {
    if (!online || mutating || authBusy || !content.trim()) return
    mutating = true
    generation++
    // The fixed helper contract takes raw UTF-8 content, not a JSON wrapper.
    call("mutation", ["add", "--date", date], content.trim(), function(result) {
      root.mutating = false
      if (result.ok) root.added()
      else { root.fail(result); root.notifyFailure(result) }
      root.requestRefresh()
    })
  }
  function openBrowser() {
    if (/^https:\/\//.test(verificationUrl)) Quickshell.execDetached(["xdg-open", verificationUrl])
  }
  function startLogin() {
    if (authBusy || mutating || refreshing) return
    generation++
    authBusy = true
    errorCode = ""
    call("auth", ["login-start"], "", function(result) {
      root.authBusy = false
      if (root.cancelRequested) { root.cancelLogin(); return }
      if (!result.ok) { root.errorCode = result.error; return }
      root.userCode = result.userCode || ""
      root.verificationUrl = result.verificationUriComplete || result.verificationUri || ""
      root.pollSeconds = Math.max(1, Number(result.interval) || 5)
      root.now = Date.now()
      root.loginDeadline = root.now + Math.max(1, Number(result.expiresIn) || 600) * 1000
      root.connectionState = "waiting"
      root.openBrowser()
      pollTimer.restart()
    })
  }
  function pollLogin() {
    if (connectionState !== "waiting" || authBusy) return
    authBusy = true
    call("auth", ["login-poll"], "", function(result) {
      root.authBusy = false
      if (root.cancelRequested) { root.cancelLogin(); return }
      if (!result.ok) {
        root.errorCode = result.error
        if (result.error === "offline" || result.error === "server_error") { pollTimer.restart(); return }
        root.connectionState = "disconnected"
        return
      }
      root.errorCode = ""
      if (result.state === "complete") {
        root.connectionState = "disconnected"
        root.cache = ({})
        root.overdueTasks = []
        root.lastSync = 0
        root.syncedToday = ""
        root.checkStatus()
      } else {
        root.pollSeconds = result.state === "slow_down"
          ? Math.max(root.pollSeconds + 5, Number(result.interval) || 0)
          : Math.max(root.pollSeconds, Number(result.interval) || 0)
        pollTimer.restart()
      }
    })
  }
  function cancelLogin() {
    pollTimer.stop()
    cancelRequested = true
    if (authBusy) return
    generation++
    authBusy = true
    connectionState = "disconnected"
    call("auth", ["login-cancel"], "", function(result) {
      root.authBusy = false
      root.cancelRequested = false
      root.userCode = ""
      root.verificationUrl = ""
      root.checkStatus()
    })
  }
  function logout() {
    if (authBusy || mutating || refreshing) return
    generation++
    loggedIn = false
    connectionState = "disconnected"
    cache = ({})
    overdueTasks = []
    email = ""
    lastSync = 0
    syncedToday = ""
    errorCode = ""
    authBusy = true
    call("auth", ["logout"], "", function(result) {
      root.authBusy = false
      if (!result.ok) { root.errorCode = result.error; root.notifyFailure(result) }
    })
  }

  onMonthChanged: requestRefresh()
  onTodayChanged: requestRefresh()
  onPanelOpenChanged: if (panelOpen) checkStatus()
  onTaskIndicatorChanged: if (taskIndicator !== "none") checkStatus()
  Component.onCompleted: checkStatus()
  Timer { interval: 300000; repeat: true; running: root.loggedIn && (root.panelOpen || root.taskIndicator !== "none"); onTriggered: root.refresh() }
  Timer {
    interval: 1000; repeat: true; running: root.panelOpen || root.connectionState === "waiting"
    onTriggered: {
      root.now = Date.now()
      if (root.connectionState === "waiting" && root.remaining === 0) { root.errorCode = "expired"; root.cancelLogin() }
    }
  }
  Timer { id: pollTimer; interval: root.pollSeconds * 1000; onTriggered: root.pollLogin() }
  Component {
    id: requestComponent
    Process {
      id: request
      property var argv: []
      property string input: ""
      property var callback
      property bool finished: false
      command: argv
      stdinEnabled: true
      stdout: StdioCollector { id: output; waitForEnd: true }
      stderr: StdioCollector { waitForEnd: true }
      function finish(result) {
        if (finished) return
        finished = true
        watchdog.stop()
        callback(result)
        destroy()
      }
      onStarted: { write(input); stdinEnabled = false }
      onExited: function(exitCode) {
        Qt.callLater(function() {
          if (request.finished) return
          var result = {ok: false, error: "server_error"}
          try { result = JSON.parse(output.text.trim()) } catch (_) {}
          if (!result || typeof result !== "object") result = {ok: false, error: "server_error"}
          if (exitCode !== 0 && result.ok) result = {ok: false, error: "server_error"}
          request.finish(result)
        })
      }
      property Timer watchdog: Timer {
        interval: 180000; running: true
        onTriggered: { request.running = false; request.finish({ok: false, error: "offline"}) }
      }
    }
  }
}
