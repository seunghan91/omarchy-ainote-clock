import QtQuick
import Quickshell
import qs.Commons
import qs.Ui as Ui
import "KoDate.js" as KoDate

Ui.Panel {
  id: root
  moduleName: "omarchy.clock"
  ipcTarget: "omarchy.clock"
  manageIpc: false
  property var anchorItem: null
  property var hostWidget: null
  property var store: null
  property bool settingsView: false
  // On today's page: "all" shows overdue as a collapsible group above today's tasks.
  property string taskFilter: "all"
  property bool overdueOpen: false
  readonly property bool viewingToday: selectedDate === todayKey
  property date today: hostWidget ? hostWidget.displayDate : new Date()
  readonly property string todayKey: KoDate.ymd(today)
  property date viewDate: new Date(today.getFullYear(), today.getMonth(), 1, 12)
  property string selectedDate: todayKey
  readonly property string monthKey: KoDate.ymd(viewDate).slice(0, 7)
  readonly property string weekStart: hostWidget ? hostWidget.weekStart : "sunday"
  readonly property bool horizontal: hostWidget && hostWidget.panelLayout === "horizontal" && !settingsView
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  // Use the palette red/blue: urgent is not red in every theme (monochrome themes map it to the foreground).
  readonly property color sundayColor: Color.flatColor(Color.pick("red", "#d1453b"), "#d1453b")
  readonly property color saturdayColor: Color.flatColor(Color.pick("blue", "#5891df"), "#5891df")
  readonly property var dayTasks: store ? store.tasks.filter(function(t) { return t.date === root.selectedDate }).slice().sort(taskOrder) : []
  readonly property var overdue: store && selectedDate === todayKey ? store.overdueTasks.filter(function(t) { return !t.completed && t.date < root.todayKey }).slice().sort(function(a, b) { return a.date.localeCompare(b.date) || root.taskOrder(a, b) }) : []
  readonly property var rows: {
    var result = []
    var filter = viewingToday ? taskFilter : "today"
    if (filter === "overdue") {
      overdue.forEach(function(t) { result.push({task: t, overdue: true}) })
      return result
    }
    if (filter === "all" && overdue.length) {
      result.push({heading: (overdueOpen ? "▾ " : "▸ ") + "밀린 할일 " + overdue.length, overdue: true, toggle: true})
      if (overdueOpen) overdue.forEach(function(t) { result.push({task: t, overdue: true}) })
      result.push({heading: "오늘", overdue: false})
    }
    dayTasks.forEach(function(t) { result.push({task: t, overdue: false}) })
    return result
  }
  function taskOrder(a, b) { return Number(a.completed) - Number(b.completed) || String(a.time || "99:99").localeCompare(String(b.time || "99:99")) || String(a.id).localeCompare(String(b.id)) }
  function weekendColor(dow) { return dow === 0 ? sundayColor : dow === 6 ? saturdayColor : contentForeground }
  function pendingCount(date) { return store ? store.tasks.filter(function(t) { return t.date === date && !t.completed }).length : 0 }
  function syncMonth() { if (store) store.month = monthKey }
  function open() {
    goToToday()
    settingsView = false
    root.controller.show()
    Qt.callLater(function() { if (root.opened) root.setHoverSuppressed(true) })
  }
  function close() { setHoverSuppressed(false); root.controller.hide() }
  function toggle() { if (opened) close(); else open() }
  function setHoverSuppressed(value) {
    if (bar && typeof bar.setCenterHoverRevealSuppressed === "function") bar.setCenterHoverRevealSuppressed(value)
  }
  function switchPanel(direction) { return bar && bar.switchPanelFrom ? bar.switchPanelFrom(hostWidget || root, direction) : false }
  function goToToday() { viewDate = new Date(today.getFullYear(), today.getMonth(), 1, 12); selectedDate = todayKey }
  function moveMonth(delta) {
    viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + delta, 1, 12)
    selectedDate = KoDate.ymd(viewDate)
  }
  function selectDay(date) {
    selectedDate = date
    var parts = date.split("-").map(Number)
    viewDate = new Date(parts[0], parts[1] - 1, 1, 12)
  }
  function save(key, value) { var values = {}; values[key] = value; if (hostWidget) hostWidget.persistSettings(values) }
  function submitTask() {
    if (!addInput.inputMethodComposing && store && addInput.text.trim()) store.addTask(selectedDate, addInput.text)
  }
  onMonthKeyChanged: syncMonth()
  onStoreChanged: syncMonth()
  onTodayKeyChanged: {
    if (selectedDate === KoDate.ymd(new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1, 12))) goToToday()
  }
  // clear() also drops any input-method pre-edit; assigning "" can leave fcitx5 composing.
  Connections { target: root.store; function onAdded() { addInput.clear() } }

  component Label: Text {
    textFormat: Text.PlainText
    color: root.contentForeground
    font.family: root.contentFontFamily
    font.pixelSize: Style.font.body
    wrapMode: Text.Wrap
  }
  component Action: Rectangle {
    id: action
    property string text: ""
    property bool selected: false
    signal clicked()
    implicitWidth: actionText.implicitWidth + Style.space(18)
    implicitHeight: Math.max(Style.space(30), actionText.implicitHeight + Style.space(10))
    radius: Style.space(6)
    color: Util.alpha(Color.accent, selected ? 0.24 : mouse.containsMouse || activeFocus ? 0.18 : 0.07)
    opacity: enabled ? 1 : 0.45
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: text
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    Label { id: actionText; anchors.centerIn: parent; text: action.text; color: Color.accent; font.bold: action.selected }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: action.clicked() }
  }
  component Choice: Rectangle {
    id: choice
    property string title: ""
    property string description: ""
    property bool selected: false
    signal clicked()
    implicitHeight: choiceText.implicitHeight + Style.space(14)
    radius: Style.space(6)
    color: Util.alpha(Color.accent, selected ? 0.12 : choiceMouse.containsMouse || activeFocus ? 0.06 : 0)
    activeFocusOnTab: true
    Accessible.role: Accessible.RadioButton
    Accessible.name: title
    Accessible.checked: selected
    Keys.onSpacePressed: clicked()
    Keys.onReturnPressed: clicked()
    Label { x: Style.space(10); anchors.verticalCenter: parent.verticalCenter; text: choice.selected ? "◉" : "○"; color: Color.accent }
    Column {
      id: choiceText
      x: Style.space(34); y: Style.space(7); width: parent.width - x - Style.space(10); spacing: Style.space(2)
      Label { width: parent.width; text: choice.title; font.bold: true }
      Label { width: parent.width; visible: text !== ""; text: choice.description; font.pixelSize: Style.font.bodySmall; opacity: 0.65 }
    }
    MouseArea { id: choiceMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: choice.clicked() }
  }

  Ui.KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(root.horizontal ? 760 : 400))
    contentHeight: panel.fittedContentHeight(Math.min(body.implicitHeight, Style.space(root.settingsView ? 650 : 700)))
    Ui.PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: addInput.activeFocus
      onMoveRequested: function(dx, dy) { if (!root.settingsView) root.moveMonth(dx || dy * 12) }
      onActivateRequested: if (!root.settingsView) root.goToToday()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: body.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        Column {
          id: body
          width: scroll.width
          spacing: Style.space(14)
          Grid {
            visible: !root.settingsView
            width: parent.width
            columns: root.horizontal ? 2 : 1
            columnSpacing: Style.space(24)
            rowSpacing: Style.space(16)
            Column {
              id: calendar
              width: root.horizontal ? (body.width - Style.space(24)) / 2 : body.width
              spacing: Style.space(10)
              Row {
                width: parent.width
                spacing: Style.space(6)
                Label {
                  width: parent.width - navigation.width - parent.spacing
                  anchors.verticalCenter: parent.verticalCenter
                  text: KoDate.monthTitle(root.viewDate.getFullYear(), root.viewDate.getMonth())
                  font.pixelSize: Style.font.heading
                  font.bold: true
                }
                Row {
                  id: navigation
                  spacing: Style.space(3)
                  Action { text: "‹"; onClicked: root.moveMonth(-1) }
                  Action { text: "오늘"; onClicked: root.goToToday() }
                  Action { text: "›"; onClicked: root.moveMonth(1) }
                }
              }
              Grid {
                width: parent.width
                columns: 7
                Repeater {
                  model: KoDate.weekdayLabels(root.weekStart)
                  Label {
                    required property string modelData
                    required property int index
                    width: calendar.width / 7
                    height: Style.space(28)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: root.weekendColor((index + (root.weekStart === "monday" ? 1 : 0)) % 7)
                    font.pixelSize: Style.font.bodySmall
                  }
                }
                Repeater {
                  model: KoDate.monthGrid(root.viewDate.getFullYear(), root.viewDate.getMonth(), root.weekStart)
                  Item {
                    id: dayCell
                    required property var modelData
                    width: calendar.width / 7
                    height: Style.space(40)
                    readonly property bool selected: modelData.date === root.selectedDate
                    readonly property bool isToday: modelData.date === root.todayKey
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: KoDate.dayHeader(modelData.date, isToday)
                    Keys.onReturnPressed: root.selectDay(modelData.date)
                    Keys.onSpacePressed: root.selectDay(modelData.date)
                    Rectangle {
                      anchors.centerIn: parent
                      width: Math.min(parent.width - Style.space(4), Style.space(36)); height: Style.space(36)
                      radius: Style.space(10)
                      color: dayCell.selected ? Color.accent : Util.alpha(Color.accent, dayMouse.containsMouse || dayCell.activeFocus ? 0.12 : 0)
                      border.width: dayCell.isToday ? Style.space(2) : 0
                      border.color: dayCell.selected ? root.contentForeground : Color.accent
                    }
                    Label {
                      anchors.horizontalCenter: parent.horizontalCenter
                      y: Style.space(5)
                      text: dayCell.modelData.day
                      color: dayCell.selected ? Color.background : root.weekendColor(dayCell.modelData.dow)
                      opacity: dayCell.modelData.inMonth ? 1 : 0.4
                    }
                    Row {
                      anchors.horizontalCenter: parent.horizontalCenter
                      y: Style.space(29)
                      spacing: Style.space(2)
                      Repeater {
                        model: Math.min(3, root.pendingCount(dayCell.modelData.date))
                        Rectangle {
                          width: Style.space(3); height: width; radius: width / 2
                          color: dayCell.modelData.date < root.todayKey ? root.sundayColor : dayCell.selected ? Color.background : Color.accent
                        }
                      }
                    }
                    MouseArea { id: dayMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectDay(dayCell.modelData.date) }
                  }
                }
              }
            }
            Column {
              width: calendar.width
              spacing: Style.space(10)
              Label {
                width: parent.width
                visible: root.store && (root.store.connectionState === "offline" || root.store.errorCode !== "")
                color: root.sundayColor
                text: !root.store ? "" : root.store.connectionState === "offline"
                  ? "오프라인 — " + (root.store.lastSync ? "마지막 동기화 " + KoDate.dayHeader(KoDate.ymd(new Date(root.store.lastSync)), false) + " " + KoDate.timeLabel(new Date(root.store.lastSync).getHours() + ":" + new Date(root.store.lastSync).getMinutes()) + " 기준." : "아직 동기화한 데이터가 없어요.") + "\n완료·추가는 연결되면 다시 시도합니다."
                  : root.store.errorMessage(root.store.errorCode)
              }
              Action { visible: root.store && root.store.connectionState === "offline"; text: "다시 시도"; enabled: root.store && !root.store.refreshing; onClicked: root.store.checkStatus() }
              Column {
                visible: root.store && root.store.connectionState === "waiting"
                width: parent.width
                spacing: Style.space(12)
                Label { width: parent.width; text: "브라우저에서 아래 코드를 확인하고\n승인하면 할일이 여기에 뜹니다."; horizontalAlignment: Text.AlignHCenter }
                Label { width: parent.width; text: root.store ? root.store.userCode : ""; horizontalAlignment: Text.AlignHCenter; font.pixelSize: Style.font.displayLarge; font.bold: true }
                Row {
                  anchors.horizontalCenter: parent.horizontalCenter; spacing: Style.space(8)
                  Action { text: "브라우저 열기"; onClicked: root.store.openBrowser() }
                  Action { text: "취소"; enabled: root.store && !root.store.cancelRequested; onClicked: root.store.cancelLogin() }
                }
                Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "승인 기다리는 중… " + (root.store ? root.store.countdown : "") }
              }
              Column {
                visible: root.store && !root.store.loggedIn && root.store.connectionState !== "waiting"
                width: parent.width; spacing: Style.space(12)
                Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: root.store && root.store.connectionState === "auth_expired" ? "로그인이 만료됐어요. 다시 연결해 주세요." : "ainote 할일을 달력에 함께 볼 수 있어요." }
                Action {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: root.store && root.store.connectionState === "auth_expired" ? "다시 연결" : "ainote 로그인"
                  enabled: root.store && !root.store.authBusy && !root.store.mutating && !root.store.refreshing
                  onClicked: root.store.startLogin()
                }
                Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "연결하지 않아도 시계·달력은 그대로 씁니다."; opacity: 0.65 }
              }
              Column {
                visible: root.store && root.store.loggedIn && root.store.connectionState !== "waiting"
                width: parent.width; spacing: Style.space(10)
                Row {
                  width: parent.width
                  Label { width: parent.width - remainingLabel.implicitWidth; text: KoDate.dayHeader(root.selectedDate, root.selectedDate === root.todayKey); font.bold: true; font.pixelSize: Style.font.title }
                  Label { id: remainingLabel; text: "남은 " + root.dayTasks.filter(function(t) { return !t.completed }).length; opacity: 0.6; font.pixelSize: Style.font.bodySmall }
                }
                Flow {
                  visible: root.viewingToday
                  width: parent.width; spacing: Style.space(6)
                  Action { text: "전체"; selected: root.taskFilter === "all"; onClicked: root.taskFilter = "all" }
                  Action { text: "오늘 " + root.dayTasks.filter(function(t) { return !t.completed }).length; selected: root.taskFilter === "today"; onClicked: root.taskFilter = "today" }
                  Action { text: "밀린 " + root.overdue.length; selected: root.taskFilter === "overdue"; onClicked: root.taskFilter = "overdue" }
                }
                Repeater {
                  model: root.rows
                  Item {
                    id: taskRow
                    required property var modelData
                    width: parent.width
                    implicitHeight: modelData.heading ? groupLabel.implicitHeight + Style.space(8) : Math.max(Style.space(32), taskTitle.implicitHeight + Style.space(10))
                    Label { id: groupLabel; visible: !!taskRow.modelData.heading; width: parent.width; text: taskRow.modelData.heading || ""; color: taskRow.modelData.overdue ? root.sundayColor : root.contentForeground; font.pixelSize: Style.font.bodySmall; font.bold: true }
                    MouseArea {
                      visible: !!taskRow.modelData.toggle
                      anchors.fill: groupLabel
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.overdueOpen = !root.overdueOpen
                    }
                    Rectangle {
                      id: checkbox
                      visible: !!taskRow.modelData.task
                      x: Style.space(2); y: Style.space(6); width: Style.space(20); height: width; radius: Style.space(5)
                      color: taskRow.modelData.task && taskRow.modelData.task.completed ? Color.accent : "transparent"
                      border.width: 1; border.color: Color.accent
                      enabled: root.store && root.store.online && !root.store.mutating && !root.store.authBusy
                      opacity: enabled ? 1 : 0.5
                      activeFocusOnTab: true
                      Accessible.role: Accessible.CheckBox
                      Accessible.name: taskRow.modelData.task ? taskRow.modelData.task.content : ""
                      Accessible.checked: taskRow.modelData.task ? taskRow.modelData.task.completed : false
                      Keys.onSpacePressed: root.store.toggleTask(taskRow.modelData.task)
                      Label { anchors.centerIn: parent; text: taskRow.modelData.task && taskRow.modelData.task.completed ? "✓" : ""; color: Color.background }
                      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.store.toggleTask(taskRow.modelData.task) }
                    }
                    Label {
                      id: taskTitle
                      visible: !!taskRow.modelData.task
                      x: Style.space(32); y: Style.space(5)
                      width: parent.width - x - taskMeta.width - Style.space(8)
                      text: taskRow.modelData.task ? (taskRow.modelData.task.important ? "★ " : "") + taskRow.modelData.task.content : ""
                      font.strikeout: taskRow.modelData.task ? taskRow.modelData.task.completed : false
                      opacity: font.strikeout ? 0.45 : 1
                    }
                    Label {
                      id: taskMeta
                      anchors.right: parent.right; y: Style.space(7)
                      text: !taskRow.modelData.task ? "" : taskRow.modelData.overdue ? KoDate.shortDate(taskRow.modelData.task.date) : taskRow.modelData.task.time ? KoDate.timeLabel(taskRow.modelData.task.time) : ""
                      font.pixelSize: Style.font.bodySmall
                      color: taskRow.modelData.overdue ? root.sundayColor : root.contentForeground
                      opacity: 0.7
                    }
                  }
                }
                Label {
                  visible: root.viewingToday && root.taskFilter === "overdue" ? root.overdue.length === 0 : root.dayTasks.length === 0
                  width: parent.width; opacity: 0.6
                  text: root.store && root.store.refreshing ? "할일을 불러오는 중…"
                    : root.viewingToday && root.taskFilter === "overdue" ? "밀린 할일이 없습니다."
                    : root.viewingToday ? "오늘 할일이 없습니다." : "이날 할일이 없습니다."
                }
                Rectangle {
                  width: parent.width; height: Style.space(42); radius: Style.space(7)
                  color: Util.alpha(root.contentForeground, 0.05)
                  border.width: addInput.activeFocus ? 1 : 0; border.color: Color.accent
                  TextInput {
                    id: addInput
                    anchors.fill: parent; anchors.margins: Style.space(10)
                    font.family: root.contentFontFamily; font.pixelSize: Style.font.body
                    color: root.contentForeground
                    selectionColor: Util.alpha(Color.accent, 0.35)
                    selectedTextColor: root.contentForeground
                    maximumLength: 500
                    clip: true
                    enabled: root.store && root.store.online && !root.store.mutating && !root.store.authBusy
                    // TextInput is inherently plain text (it has no textFormat property).
                    Keys.onReturnPressed: function(event) { if (!inputMethodComposing) { root.submitTask(); event.accepted = true } }
                    Keys.onEnterPressed: function(event) { if (!inputMethodComposing) { root.submitTask(); event.accepted = true } }
                    Keys.onEscapePressed: root.close()
                    Label {
                      anchors.fill: parent
                      visible: addInput.text === "" && addInput.preeditText === ""
                      text: Number(root.selectedDate.slice(5, 7)) + "월 " + Number(root.selectedDate.slice(8)) + "일에 할일 추가"
                      opacity: 0.5
                    }
                  }
                }
              }
            }
          }
          Column {
            visible: root.settingsView
            width: parent.width
            spacing: Style.space(6)
            Row {
              width: parent.width
              Label { width: parent.width - backButton.width; text: "설정"; font.pixelSize: Style.font.heading; font.bold: true }
              Action { id: backButton; text: "← 달력"; onClicked: root.settingsView = false }
            }
            Repeater {
              model: [
                {key: "taskIndicator", title: "바에 할일 표시", options: [{value: "none", title: "표시 안 함", description: "시계만 (기본값)"}, {value: "split", title: "남은 할일 · 밀린 할일", description: "할일 2 · 밀림 2 처럼 따로"}, {value: "total", title: "합계 숫자 하나", description: "남은 것과 밀린 것을 합쳐서"}]},
                {key: "panelLayout", title: "달력 패널 모양", options: [{value: "vertical", title: "세로", description: "달력 위, 할일 아래 (기본값)"}, {value: "horizontal", title: "가로 2단", description: "달력 왼쪽, 할일 오른쪽"}]},
                {key: "weekStart", title: "주 시작", options: [{value: "sunday", title: "일요일", description: "기본값"}, {value: "monday", title: "월요일", description: ""}]}
              ]
              Column {
                id: group
                required property var modelData
                width: parent.width; spacing: Style.space(3)
                Label { width: parent.width; topPadding: Style.space(10); bottomPadding: Style.space(4); text: group.modelData.title; font.bold: true }
                Repeater {
                  model: group.modelData.options
                  Choice {
                    required property var modelData
                    width: parent.width
                    title: modelData.title; description: modelData.description
                    selected: root.hostWidget && root.hostWidget[group.modelData.key] === modelData.value
                    onClicked: root.save(group.modelData.key, modelData.value)
                  }
                }
              }
            }
            Label { text: "ainote"; topPadding: Style.space(10); font.bold: true }
            Row {
              width: parent.width
              Label { width: parent.width - logoutButton.width; text: root.store && root.store.loggedIn ? root.store.email : "연결 안 됨" }
              Action { id: logoutButton; visible: root.store && root.store.loggedIn; text: "로그아웃"; enabled: root.store && !root.store.authBusy && !root.store.mutating && !root.store.refreshing; onClicked: root.store.logout() }
            }
            Label { width: parent.width; text: "바뀐 값은 바로 적용·저장"; opacity: 0.6; font.pixelSize: Style.font.bodySmall }
          }
          Rectangle { width: parent.width; height: 1; color: Util.alpha(root.contentForeground, 0.12) }
          Flow {
            width: parent.width
            spacing: Style.space(8)
            Label { text: "ainote · " + (root.store ? root.store.syncLabel : "아직 동기화 전"); height: Style.space(30); verticalAlignment: Text.AlignVCenter; font.pixelSize: Style.font.bodySmall; opacity: 0.6 }
            Action { text: root.settingsView ? "달력" : "설정"; onClicked: root.settingsView = !root.settingsView }
            Action { text: "ainote 에서 열기 ↗"; onClicked: Quickshell.execDetached(["xdg-open", "https://app.ainote.dev"]) }
          }
        }
      }
    }
  }
}
