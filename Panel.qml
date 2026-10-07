import QtQuick
import Quickshell
import qs.Commons
import qs.Ui as Ui
import "ClockText.js" as ClockText

Ui.Panel {
  id: root
  moduleName: "omarchy.clock"
  ipcTarget: "omarchy.clock"
  manageIpc: false
  property var anchorItem: null
  property var hostWidget: null
  property var store: null
  readonly property string language: hostWidget ? hostWidget.resolvedLanguage : ClockText.resolveLanguage("auto", Qt.locale())
  readonly property var strings: ClockText.strings(language)
  function tr(key, values) { return ClockText.format(strings[key], values) }
  function offlineLabel() {
    if (!store) return ""
    var date = new Date(store.lastSync)
    var detail = store.lastSync ? tr("lastSyncDetail", {
      date: ClockText.dayHeader(ClockText.ymd(date), false, language),
      time: ClockText.timeLabel(date.getHours() + ":" + date.getMinutes(), language)
    }) : strings.noSyncData
    return tr("offlineStatus", {detail: detail})
  }
  property bool settingsView: false
  // On today's page: "all" shows overdue as a collapsible group above today's tasks.
  property string taskFilter: "all"
  property bool overdueOpen: false
  readonly property bool viewingToday: selectedDate === todayKey
  property date today: hostWidget ? hostWidget.displayDate : new Date()
  readonly property string todayKey: ClockText.ymd(today)
  property date viewDate: new Date(today.getFullYear(), today.getMonth(), 1, 12)
  property string selectedDate: todayKey
  readonly property string monthKey: ClockText.ymd(viewDate).slice(0, 7)
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
      result.push({heading: (overdueOpen ? "▾ " : "▸ ") + root.tr("overdueHeading", {count: overdue.length}), overdue: true, toggle: true})
      if (overdueOpen) overdue.forEach(function(t) { result.push({task: t, overdue: true}) })
      result.push({heading: root.strings.today, overdue: false})
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
    selectedDate = ClockText.ymd(viewDate)
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
    if (selectedDate === ClockText.ymd(new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1, 12))) goToToday()
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
  component AppLinks: Column {
    width: parent ? parent.width : 0
    spacing: Style.space(6)
    property bool centered: false
    Label { width: parent.width; horizontalAlignment: parent.centered ? Text.AlignHCenter : Text.AlignLeft; text: root.strings.syncNote; opacity: 0.65; font.pixelSize: Style.font.bodySmall }
    Flow {
      width: parent.width
      spacing: Style.space(6)
      layoutDirection: Qt.LeftToRight
      Repeater {
        model: ClockText.APP_LINKS
        Action { required property var modelData; text: root.strings[modelData.key] + " ↗"; onClicked: Quickshell.execDetached(["xdg-open", modelData.url]) }
      }
    }
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
                  text: ClockText.monthTitle(root.viewDate.getFullYear(), root.viewDate.getMonth(), root.language)
                  font.pixelSize: Style.font.heading
                  font.bold: true
                }
                Row {
                  id: navigation
                  spacing: Style.space(3)
                  Action { text: "‹"; onClicked: root.moveMonth(-1) }
                  Action { text: root.strings.today; onClicked: root.goToToday() }
                  Action { text: "›"; onClicked: root.moveMonth(1) }
                }
              }
              Grid {
                width: parent.width
                columns: 7
                Repeater {
                  model: ClockText.weekdayLabels(root.weekStart, root.language)
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
                  model: ClockText.monthGrid(root.viewDate.getFullYear(), root.viewDate.getMonth(), root.weekStart)
                  Item {
                    id: dayCell
                    required property var modelData
                    width: calendar.width / 7
                    height: Style.space(40)
                    readonly property bool selected: modelData.date === root.selectedDate
                    readonly property bool isToday: modelData.date === root.todayKey
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: ClockText.dayHeader(modelData.date, isToday, root.language)
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
                  ? root.offlineLabel()
                  : root.store.errorMessage(root.store.errorCode)
              }
              Action { visible: root.store && root.store.connectionState === "offline"; text: root.strings.retry; enabled: root.store && !root.store.refreshing; onClicked: root.store.checkStatus() }
              Column {
                visible: root.store && root.store.connectionState === "waiting"
                width: parent.width
                spacing: Style.space(12)
                Label { width: parent.width; text: root.strings.approvalInstructions; horizontalAlignment: Text.AlignHCenter }
                Label { width: parent.width; text: root.store ? root.store.userCode : ""; horizontalAlignment: Text.AlignHCenter; font.pixelSize: Style.font.displayLarge; font.bold: true }
                Row {
                  anchors.horizontalCenter: parent.horizontalCenter; spacing: Style.space(8)
                  Action { text: root.strings.openBrowser; onClicked: root.store.openBrowser() }
                  Action { text: root.strings.cancel; enabled: root.store && !root.store.cancelRequested; onClicked: root.store.cancelLogin() }
                }
                Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: root.tr("waitingApproval", {countdown: root.store ? root.store.countdown : ""}) }
              }
              Column {
                visible: root.store && !root.store.loggedIn && root.store.connectionState !== "waiting"
                width: parent.width; spacing: Style.space(12)
                Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: root.store && root.store.connectionState === "auth_expired" ? root.strings.error_auth_expired : root.strings.loginIntro }
                Action {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: root.store && root.store.connectionState === "auth_expired" ? root.strings.reconnect : root.strings.login
                  enabled: root.store && !root.store.authBusy && !root.store.mutating && !root.store.refreshing
                  onClicked: root.store.startLogin()
                }
                Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: root.strings.noLoginNeeded; opacity: 0.65 }
                AppLinks { centered: true }
              }
              Column {
                visible: root.store && root.store.loggedIn && root.store.connectionState !== "waiting"
                width: parent.width; spacing: Style.space(10)
                Row {
                  width: parent.width
                  Label { width: parent.width - remainingLabel.implicitWidth; text: ClockText.dayHeader(root.selectedDate, root.selectedDate === root.todayKey, root.language); font.bold: true; font.pixelSize: Style.font.title }
                  Label { id: remainingLabel; text: root.tr("remainingCount", {count: root.dayTasks.filter(function(t) { return !t.completed }).length}); opacity: 0.6; font.pixelSize: Style.font.bodySmall }
                }
                Flow {
                  visible: root.viewingToday
                  width: parent.width; spacing: Style.space(6)
                  Action { text: root.strings.all; selected: root.taskFilter === "all"; onClicked: root.taskFilter = "all" }
                  Action { text: root.tr("todayCount", {count: root.dayTasks.filter(function(t) { return !t.completed }).length}); selected: root.taskFilter === "today"; onClicked: root.taskFilter = "today" }
                  Action { text: root.tr("overdueCount", {count: root.overdue.length}); selected: root.taskFilter === "overdue"; onClicked: root.taskFilter = "overdue" }
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
                      text: !taskRow.modelData.task ? "" : taskRow.modelData.overdue ? ClockText.shortDate(taskRow.modelData.task.date) : taskRow.modelData.task.time ? ClockText.timeLabel(taskRow.modelData.task.time, root.language) : ""
                      font.pixelSize: Style.font.bodySmall
                      color: taskRow.modelData.overdue ? root.sundayColor : root.contentForeground
                      opacity: 0.7
                    }
                  }
                }
                Label {
                  visible: root.viewingToday && root.taskFilter === "overdue" ? root.overdue.length === 0 : root.dayTasks.length === 0
                  width: parent.width; opacity: 0.6
                  text: root.store && root.store.refreshing ? root.strings.loadingTasks
                    : root.viewingToday && root.taskFilter === "overdue" ? root.strings.emptyOverdue
                    : root.viewingToday ? root.strings.emptyToday : root.strings.emptyDay
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
                      text: ClockText.addPlaceholder(root.selectedDate, root.language)
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
              Label { width: parent.width - backButton.width; text: root.strings.settings; font.pixelSize: Style.font.heading; font.bold: true }
              Action { id: backButton; text: root.strings.backCalendar; onClicked: root.settingsView = false }
            }
            Repeater {
              model: [
                {key: "language", title: root.strings.languageTitle, options: [{value: "auto", title: root.strings.languageAuto, description: root.strings.languageAutoDescription}, {value: "en", title: root.strings.languageEn, description: ""}, {value: "ko", title: root.strings.languageKo, description: ""}, {value: "zh-Hans", title: root.strings.languageZhHans, description: ""}, {value: "zh-Hant", title: root.strings.languageZhHant, description: ""}]},
                {key: "taskIndicator", title: root.strings.indicatorTitle, options: [{value: "none", title: root.strings.indicatorNone, description: root.strings.indicatorNoneDescription}, {value: "split", title: root.strings.indicatorSplit, description: root.strings.indicatorSplitDescription}, {value: "total", title: root.strings.indicatorTotal, description: root.strings.indicatorTotalDescription}]},
                {key: "panelLayout", title: root.strings.layoutTitle, options: [{value: "vertical", title: root.strings.layoutVertical, description: root.strings.layoutVerticalDescription}, {value: "horizontal", title: root.strings.layoutHorizontal, description: root.strings.layoutHorizontalDescription}]},
                {key: "weekStart", title: root.strings.weekStartTitle, options: [{value: "sunday", title: root.strings.sunday, description: root.strings.defaultDescription}, {value: "monday", title: root.strings.monday, description: ""}]}
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
            Label { text: root.strings.product; topPadding: Style.space(10); font.bold: true }
            Row {
              width: parent.width
              Label { width: parent.width - logoutButton.width; text: root.store && root.store.loggedIn ? root.store.email : root.strings.disconnected }
              Action { id: logoutButton; visible: root.store && root.store.loggedIn; text: root.strings.logout; enabled: root.store && !root.store.authBusy && !root.store.mutating && !root.store.refreshing; onClicked: root.store.logout() }
            }
            AppLinks {}
            Label { width: parent.width; text: root.strings.savedImmediately; opacity: 0.6; font.pixelSize: Style.font.bodySmall }
          }
          Rectangle { width: parent.width; height: 1; color: Util.alpha(root.contentForeground, 0.12) }
          Flow {
            width: parent.width
            spacing: Style.space(8)
            Label { text: root.tr("footer", {sync: root.store ? root.store.syncLabel : root.strings.notSynced}); height: Style.space(30); verticalAlignment: Text.AlignVCenter; font.pixelSize: Style.font.bodySmall; opacity: 0.6 }
            Action { text: root.settingsView ? root.strings.calendar : root.strings.settings; onClicked: root.settingsView = !root.settingsView }
            Action { text: root.strings.openAINote; onClicked: Quickshell.execDetached(["xdg-open", "https://app.ainote.dev"]) }
          }
        }
      }
    }
  }
}
