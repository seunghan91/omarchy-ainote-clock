import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui as Ui
import "ClockText.js" as ClockText

Ui.BarWidget {
  id: root
  moduleName: "omarchy.clock"
  property date displayDate: clock.date
  readonly property string language: ClockText.languageSetting(setting("language", "auto"))
  readonly property string resolvedLanguage: ClockText.resolveLanguage(language, Qt.locale())
  readonly property var strings: ClockText.strings(resolvedLanguage)
  function tr(key, values) { return ClockText.format(strings[key], values) }
  readonly property string taskIndicator: ["none", "split", "total"].indexOf(setting("taskIndicator", "none")) >= 0 ? setting("taskIndicator", "none") : "none"
  readonly property string panelLayout: setting("panelLayout", "vertical") === "horizontal" ? "horizontal" : "vertical"
  readonly property string weekStart: setting("weekStart", "sunday") === "monday" ? "monday" : "sunday"
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing : false
  readonly property real openPanelIndicatorWidth: vertical ? barSize : labelRow.implicitWidth
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))
  readonly property bool showBadge: store.badgeReady && taskIndicator !== "none"

  function refresh() { displayDate = new Date(); store.checkStatus() }
  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }
  function toggleWeekStart() { persistSettings({weekStart: weekStart === "sunday" ? "monday" : "sunday"}) }
  function persistSettings(values) {
    var entry = {id: root.moduleName}
    for (var key in root.settings) if (key !== "id") entry[key] = root.settings[key]
    for (var name in values) entry[name] = values[name]
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }
  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.settings = root.settings
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
    panelLoader.item.store = store
  }
  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: root.displayDate = date
  }
  TaskStore {
    id: store
    panelOpen: root.opened
    taskIndicator: root.taskIndicator
    language: root.resolvedLanguage
    today: ClockText.ymd(root.displayDate)
  }
  Loader {
    id: panelLoader
    active: true
    visible: false
    source: Qt.resolvedUrl("Panel.qml")
    onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) }
  }
  IpcHandler {
    target: "omarchy.clock"
    function refresh(): void { root.broadcast("refresh") }
    function toggleWeekStart(): void { root.toggleWeekStart() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
  }
  Ui.WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: root.vertical ? root.barSize : labelRow.implicitWidth + Style.space(18)
    fixedHeight: root.vertical ? Style.bar.iconSlot * 3 + (root.showBadge ? Style.bar.iconSlot : 0) : -1
    tooltipText: root.strings.tooltip
    onPressed: function(b) {
      if (b === Qt.LeftButton) root.togglePanel()
      else if (b === Qt.MiddleButton) Quickshell.execDetached(["omarchy-menu-timezone"])
    }
    Row {
      id: labelRow
      visible: !root.vertical
      anchors.centerIn: parent
      spacing: Style.space(7)
      Text {
        textFormat: Text.PlainText
        text: ClockText.barLabel(root.displayDate, root.resolvedLanguage)
        font.family: button.fontFamily
        font.pixelSize: button.fontSize
        color: button.foreground
        anchors.verticalCenter: parent.verticalCenter
      }
      Repeater {
        model: !root.showBadge ? [] : root.taskIndicator === "total" ? [String(store.todayPending + store.overdueCount)]
          : [root.tr("badgeToday", {count: store.todayPending})].concat(store.overdueCount > 0 ? [root.tr("badgeOverdue", {count: store.overdueCount})] : [])
        Rectangle {
          required property string modelData
          required property int index
          implicitWidth: badge.implicitWidth + Style.space(10)
          implicitHeight: badge.implicitHeight + Style.space(4)
          anchors.verticalCenter: parent.verticalCenter
          radius: Style.space(5)
          color: Util.alpha(index > 0 ? Color.urgent : button.foreground, 0.12)
          Text {
            id: badge
            textFormat: Text.PlainText
            anchors.centerIn: parent
            text: modelData
            font.family: button.fontFamily
            font.pixelSize: Style.font.bodySmall
            color: index > 0 ? Color.urgent : button.foreground
          }
        }
      }
    }
    Text {
      visible: root.vertical
      textFormat: Text.PlainText
      anchors.centerIn: parent
      horizontalAlignment: Text.AlignHCenter
      text: ClockText.verticalLabel(root.displayDate) + (root.showBadge ? "\n" + (store.todayPending + store.overdueCount) : "")
      font.family: button.fontFamily
      font.pixelSize: button.fontSize
      color: button.foreground
    }
  }
}
