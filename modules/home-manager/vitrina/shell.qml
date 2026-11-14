import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Widgets
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "."

ShellRoot {
    id: shell

    readonly property var mainScreen: Quickshell.screens.find(s => s.name === "DP-4") ?? Quickshell.primaryScreen
    readonly property var sideScreens: Quickshell.screens.filter(s => s.name !== "DP-4")
    readonly property var mainWs: wsByOutput["DP-4"] ?? null

    property var wsByOutput: ({})

    Process {
        id: wsSeed
        command: ["sh", "-c", "NIRI_SOCKET=$(ls /run/user/1000/niri*.sock 2>/dev/null | head -1) exec niri msg --json workspaces"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let list = []
                try {
                    list = JSON.parse(this.text)
                } catch (e) {
                    return
                }
                applyWs(list)
            }
        }
    }

    Process {
        id: wsStream
        command: ["sh", "-c", "NIRI_SOCKET=$(ls /run/user/1000/niri*.sock 2>/dev/null | head -1) exec niri msg --json event-stream"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                let evt = null
                try {
                    evt = JSON.parse(data)
                } catch (e) {
                    return
                }
                if (evt.WorkspacesChanged) {
                    applyWs(evt.WorkspacesChanged.workspaces)
                } else if (evt.WorkspaceActivated) {
                    activateWs(evt.WorkspaceActivated.id, evt.WorkspaceActivated.focused)
                }
            }
        }
        onExited: (code) => wsRestart.restart()
    }

    function applyWs(list) {
        const byOutput = {}
        for (let i = 0; i < list.length; i++) {
            const w = list[i]
            if (!byOutput[w.output])
                byOutput[w.output] = []
            byOutput[w.output].push({
                id: w.id,
                idx: w.idx,
                name: w.name,
                focused: w.is_focused,
                urgent: w.is_urgent,
                active: w.is_active
            })
        }
        const state = {}
        for (const out in byOutput) {
            const wss = byOutput[out].sort((a, b) => a.idx - b.idx)
            const active = wss.find(w => w.active) ?? null
            const prev = wsByOutput[out]
            let changedAt = prev ? prev.changedAt : Date.now()
            if (prev && active && prev.activeId !== active.id)
                changedAt = Date.now()
            state[out] = {
                list: wss,
                activeId: active ? active.id : 0,
                changedAt: changedAt
            }
        }
        wsByOutput = state
    }

    function activateWs(id, focused) {
        const state = {}
        for (const out in wsByOutput) {
            const st = wsByOutput[out]
            if (!st.list.some(w => w.id === id)) {
                state[out] = st
                continue
            }
            const list = st.list.map(w => ({
                id: w.id,
                idx: w.idx,
                name: w.name,
                focused: w.id === id ? focused : false,
                urgent: w.urgent,
                active: w.id === id
            }))
            state[out] = {
                list: list,
                activeId: id,
                changedAt: st.activeId !== id ? Date.now() : st.changedAt
            }
        }
        wsByOutput = state
    }

    Timer {
        id: wsRestart
        interval: 1000
        onTriggered: {
            wsStream.running = false
            wsStream.running = true
        }
    }

    NotificationServer {
        id: ns
        bodySupported: true
        keepOnReload: true

        onNotification: (n) => {
            n.tracked = true
            shell.hasUnread = true
        }
    }

    property bool hasPlayer: false
    property bool isPlaying: false
    property string playerName: ""
    property string artistName: ""
    property string trackName: ""
    property var players: []
    property bool hasUnread: false
    property real lastMpris: 0
    property var visHeights: [0.7, 0.3, 0.9, 0.45, 0.8, 0.35]

    function clearAll() {
        const vals = []
        const live = ns.trackedNotifications.values
        for (let i = 0; i < live.length; i++)
            vals.push(live[i])
        for (let i = 0; i < vals.length; i++)
            vals[i].dismiss()
    }

    function pc(args, player) {
        const target = player ? ["-p", player] : (playerName.length > 0 ? ["-p", playerName] : [])
        if (args[0] === "play-pause")
            isPlaying = !isPlaying
        lastMpris = Date.now()
        pctlCmd.running = false
        pctlCmd.command = ["playerctl", ...target, ...args]
        pctlCmd.running = true
        mprisFast.restart()
    }

    function seek(player, sec) {
        if (!(sec >= 0))
            return
        lastMpris = Date.now()
        pctlCmd.running = false
        pctlCmd.command = ["playerctl", "-p", player, "position", String(Math.round(sec))]
        pctlCmd.running = true
        mprisFast.restart()
    }

    Timer {
        id: mprisFast
        interval: 350
        onTriggered: mprisPoll.running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: mprisPoll.running = true
    }

    Timer {
        id: visTimer
        interval: 130
        running: true
        repeat: true
        onTriggered: {
            if (!shell.isPlaying) {
                shell.visHeights = [0, 0, 0, 0, 0, 0]
                return
            }
            shell.visHeights = [
                0.15 + Math.random() * 0.85,
                0.15 + Math.random() * 0.85,
                0.15 + Math.random() * 0.85,
                0.15 + Math.random() * 0.85,
                0.15 + Math.random() * 0.85,
                0.15 + Math.random() * 0.85
            ]
        }
    }

    Process {
        id: mprisPoll
        command: ["playerctl", "-a", "metadata", "--format", "{{playerInstance}}|{{status}}|{{position}}|{{mpris:length}}|{{artist}}|{{album}}|{{mpris:artUrl}}|{{title}}"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.trim().length > 0)
                const players = []
                let playing = null
                let paused = null
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split("|")
                    const entry = {
                        name: parts[0] ?? "",
                        artist: parts[4] ?? "",
                        album: parts[5] ?? "",
                        art: parts[6] ?? "",
                        title: parts.slice(7).join("|"),
                        playing: parts[1] === "Playing",
                        position: (parseFloat(parts[2]) || 0) / 1e6,
                        length: (parseFloat(parts[3]) || 0) / 1e6
                    }
                    players.push(entry)
                    if (entry.playing && playing === null)
                        playing = entry
                    if (paused === null && parts[1] === "Paused")
                        paused = entry
                }
                shell.players = players.slice(0, 6)
                if (Date.now() - shell.lastMpris < 800)
                    return
                const chosen = playing ?? paused ?? (lines.length > 0 ? {
                    name: "",
                    artist: "",
                    title: "",
                    playing: false,
                    position: 0,
                    length: 0
                } : null)
                shell.hasPlayer = chosen !== null && chosen.title.length > 0
                shell.isPlaying = chosen ? chosen.playing : false
                shell.playerName = chosen ? chosen.name : ""
                shell.artistName = chosen ? chosen.artist : ""
                shell.trackName = chosen ? chosen.title : ""
            }
        }
    }

    Process {
        id: pctlCmd
    }

    function runPower(cmd) {
        powerCmd.running = false
        powerCmd.command = cmd
        powerCmd.running = true
    }

    Process {
        id: powerCmd
    }

    property bool wifiOn: true
    property bool btOn: false
    property string connDev: ""
    property string connAddr: ""
    property string tsIp: ""
    property var wifiNets: []
    property var btDevices: []
    property bool osdVisible: false
    property real osdValue: 0
    property bool osdMuted: false

    Connections {
        target: Wp
        function onSinkVolChanged() {
            shell.osdValue = Wp.sinkVol
            shell.osdMuted = Wp.sinkMuted
            shell.osdVisible = true
            osdTimer.restart()
        }
        function onSinkMutedChanged() {
            shell.osdValue = Wp.sinkVol
            shell.osdMuted = Wp.sinkMuted
            shell.osdVisible = true
            osdTimer.restart()
        }
    }

    Timer {
        id: osdTimer
        interval: 1600
        onTriggered: shell.osdVisible = false
    }

    function wifiConnect(ssid, pw) {
        wifiAct.running = false
        wifiAct.command = pw.length > 0 ? ["iwctl", "station", "wlan0", "connect", ssid, "--passphrase", pw] : ["iwctl", "station", "wlan0", "connect", ssid]
        wifiAct.running = true
    }

    function wifiDisconnect() {
        wifiAct.running = false
        wifiAct.command = ["iwctl", "station", "wlan0", "disconnect"]
        wifiAct.running = true
    }

    function btToggleDevice(mac, isConn) {
        btAct.running = false
        btAct.command = ["bluetoothctl", isConn ? "disconnect" : "connect", mac]
        btAct.running = true
    }

    function toggleWifiRadio() {
        wifiCmd.running = false
        wifiCmd.command = ["sh", "-c", "rfkill list wifi | grep -q 'Soft blocked: yes' && rfkill unblock wifi || rfkill block wifi"]
        wifiCmd.running = true
    }

    function toggleBtPower() {
        btCmd.running = false
        btCmd.command = ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on"]
        btCmd.running = true
    }

    Process {
        id: wifiCmd
        onExited: wifiStatusProc.running = true
    }

    Process {
        id: btCmd
        onExited: btStatusProc.running = true
    }

    Process {
        id: wifiStatusProc
        command: ["sh", "-c", "rfkill list wifi | grep -q 'Soft blocked: yes' && echo off || echo on"]
        stdout: StdioCollector {
            onStreamFinished: shell.wifiOn = this.text.trim() === "on"
        }
    }

    Process {
        id: btStatusProc
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: shell.btOn = this.text.trim() === "on"
        }
    }

    Process {
        id: connStatusProc
        command: ["sh", "-c", "ip route get 1.1.1.1 2>/dev/null | head -1; echo '===TS'; tailscale ip -4 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("===TS")
                const m = (parts[0] ?? "").match(/dev\s+(\S+).*src\s+(\S+)/)
                shell.connDev = m ? m[1] : ""
                shell.connAddr = m ? m[2] : ""
                shell.tsIp = (parts[1] ?? "").trim()
            }
        }
    }

    Process {
        id: wifiNetsProc
        command: ["sh", "-c", "iwctl station wlan0 get-networks 2>/dev/null; echo '===CONN'; iwctl station wlan0 show 2>/dev/null | grep -i 'connected network'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = this.text.replace(/\x1b\[[0-9;]*m/g, "")
                const parts = raw.split("===CONN")
                const table = parts[0] ?? ""
                const connPart = parts[1] ?? ""
                const cm = connPart.match(/connected network\s+(.+)$/im)
                const connectedSsid = cm ? cm[1].trim() : ""
                const nets = []
                const lines = table.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const t = lines[i].trim()
                    if (t.length === 0 || t.startsWith("---") || t.indexOf("Network name") >= 0 || t.indexOf("Available networks") >= 0)
                        continue
                    const cols = t.split(/\s{2,}/)
                    if (cols.length < 2)
                        continue
                    const ssid = cols[0]
                    const security = cols[1] ?? ""
                    nets.push({
                        ssid: ssid,
                        security: security,
                        secured: security.length > 0 && security !== "open",
                        signal: cols[2] ?? "",
                        connected: connectedSsid.length > 0 && ssid === connectedSsid
                    })
                }
                shell.wifiNets = nets
            }
        }
    }

    Process {
        id: btDevicesProc
        command: ["sh", "-c", "echo PAIRED; bluetoothctl devices Paired; echo CONNECTED; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const paired = {}
                const conn = {}
                let mode = ""
                const lines = this.text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim()
                    if (line === "PAIRED") {
                        mode = "p"
                        continue
                    }
                    if (line === "CONNECTED") {
                        mode = "c"
                        continue
                    }
                    const m = line.match(/^Device\s+(\S+)\s+(.*)$/)
                    if (!m)
                        continue
                    if (mode === "p")
                        paired[m[1]] = m[2]
                    else if (mode === "c")
                        conn[m[1]] = true
                }
                const out = []
                for (const mac in paired)
                    out.push({
                        mac: mac,
                        name: paired[mac],
                        connected: conn[mac] === true
                    })
                shell.btDevices = out
            }
        }
    }

    Process {
        id: wifiAct
        onExited: {
            wifiNetsProc.running = true
            wifiStatusProc.running = true
        }
    }

    Process {
        id: btAct
        onExited: btDevicesProc.running = true
    }

    Process {
        id: rfkillMonitor
        command: ["rfkill", "event"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                wifiStatusProc.running = true
            }
        }
        onExited: rfkillRestart.restart()
    }

    Timer {
        id: rfkillRestart
        interval: 2000
        onTriggered: rfkillMonitor.running = true
    }

    Process {
        id: btMonitor
        command: ["dbus-monitor", "--system", "type='signal',interface='org.freedesktop.DBus.Properties',path='/org/bluez/hci0'"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                if (line.indexOf("Powered") >= 0)
                    btStatusProc.running = true
            }
        }
        onExited: btRestart.restart()
    }

    Timer {
        id: btRestart
        interval: 2000
        onTriggered: btMonitor.running = true
    }

    Process {
        id: linkMonitor
        command: ["ip", "monitor", "link"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim().length > 0)
                    connStatusProc.running = true
            }
        }
        onExited: linkRestart.restart()
    }

    Timer {
        id: linkRestart
        interval: 2000
        onTriggered: linkMonitor.running = true
    }

    Component.onCompleted: {
        wifiStatusProc.running = true
        btStatusProc.running = true
        connStatusProc.running = true
        wifiNetsProc.running = true
        btDevicesProc.running = true
    }

    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-4")

        PanelWindow {
            id: island
            required property var modelData
            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: (island.expanded || island.powerOpen || island.trayOpen) ? modelData.height : (Math.max(morph.height, powerPill.height, trayPill.height) + 6)
            exclusiveZone: 30
            exclusionMode: ExclusionMode.Normal
            color: "transparent"
            WlrLayershell.keyboardFocus: (island.connView === "wifi" && island.pendingSsid.length > 0) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            mask: Region {
                item: (island.powerOpen || island.trayOpen || island.expanded) ? outsideCatcher : morph
                Region {
                    item: wsPill
                }
                Region {
                    item: powerPill
                }
                Region {
                    item: trayPill
                }
            }

            MouseArea {
                id: outsideCatcher
                anchors.fill: parent
                enabled: island.powerOpen || island.trayOpen || island.expanded
                onClicked: {
                    island.powerOpen = false
                    island.trayMenuHandle = null
                    island.trayMenuStack = []
                    island.trayOpen = false
                    island.expanded = false
                }
            }

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }

            SystemClock {
                id: clk
                precision: SystemClock.Minutes
            }

            property bool expanded: false
            property bool outOpen: false
            property bool inOpen: false
            property bool powerOpen: false
            property bool trayOpen: false
            property string tab: "music"
            readonly property int tabIndex: tab === "settings" ? 1 : 0
            readonly property int panelMaxH: Math.min(690, modelData.height - 80)
            property var trayMenuHandle: null
            property string trayMenuTitle: ""
            property var trayMenuStack: []

            function trayMenuOpen(item) {
                trayMenuStack = []
                trayMenuHandle = item.menu
                trayMenuTitle = item.title.length > 0 ? item.title : item.id
            }

            function trayMenuDrill(entry) {
                trayMenuStack = trayMenuStack.concat([{
                    menu: trayMenuHandle,
                    title: trayMenuTitle
                }])
                trayMenuHandle = entry
                trayMenuTitle = entry.text
            }

            function trayMenuBack() {
                if (trayMenuStack.length === 0) {
                    trayMenuHandle = null
                    trayMenuTitle = ""
                    return
                }
                const s = trayMenuStack[trayMenuStack.length - 1]
                trayMenuStack = trayMenuStack.slice(0, trayMenuStack.length - 1)
                trayMenuHandle = s.menu
                trayMenuTitle = s.title
            }

            function trayClose() {
                trayOpen = false
                trayMenuHandle = null
                trayMenuStack = []
            }
            property string pendingSsid: ""
            property string connView: ""
            property var players: shell.players
            property int playerIndex: 0
            property bool shuffleOn: false
            property int loopState: 0
            readonly property var currentPlayer: players.length > 0 ? players[Math.min(playerIndex, players.length - 1)] : null

            function toggleShuffle(name) {
                shuffleOn = !shuffleOn
                pc(["shuffle", shuffleOn ? "On" : "Off"], name)
            }

            function cycleLoop(name) {
                loopState = (loopState + 1) % 3
                pc(["loop", ["None", "Track", "Playlist"][loopState]], name)
            }

            function nextPlayer() {
                if (players.length > 0)
                    playerIndex = (playerIndex + 1) % players.length
            }

            function prevPlayer() {
                if (players.length > 0)
                    playerIndex = (playerIndex - 1 + players.length) % players.length
            }

            function fmtTime(sec) {
                const s = Math.max(0, Math.floor(sec || 0))
                const m = Math.floor(s / 60)
                const r = s % 60
                return m + ":" + (r < 10 ? "0" + r : r)
            }
            property bool hasPlayer: shell.hasPlayer
            property bool isPlaying: shell.isPlaying
            property bool hasUnread: shell.hasUnread
            property var visHeights: shell.visHeights

            function toggleExpand() {
                expanded = !expanded
                powerOpen = false
                if (expanded) {
                    shell.hasUnread = false
                    wifiNetsProc.running = true
                    btDevicesProc.running = true
                    connStatusProc.running = true
                }
            }

            function clearAll() {
                for (let i = 0; i < notifRepeater.count; i++) {
                    const it = notifRepeater.itemAt(i)
                    if (it)
                        it.vanish(i * 35)
                }
            }

            function pc(args, player) {
                shell.pc(args, player)
            }

            function seek(player, sec) {
                shell.seek(player, sec)
            }

        Rectangle {
                        id: morph
                        anchors.top: parent.top
                        anchors.topMargin: 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: island.expanded ? 740 : headRow.width + 24
                        height: island.expanded ? Math.min(cols.implicitHeight + cols.y + 22, island.panelMaxH) : 26
                        radius: island.expanded ? 22 : 13
                        color: Colors.bg
                        border.width: 1
                        border.color: Colors.alpha(Colors.accent, "3d")
                        clip: true



            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            }

            Behavior on width {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on radius {
                NumberAnimation {
                    duration: 200
                }
            }

            Row {
                id: headRow
                x: island.expanded ? (morph.width - headRow.width) / 2 : 12
                y: 0
                height: 26
                spacing: 8

                Behavior on x {
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                }

                Row {
                    height: parent.height
                    spacing: 2

                    Repeater {
                        model: 6

                        delegate: Rectangle {
                            required property int index
                            width: 3
                            radius: 1.5
                            anchors.verticalCenter: parent.verticalCenter
                            height: 3 + (island.hasPlayer ? island.visHeights[index] * 14 : 0)
                            color: island.isPlaying ? Colors.accent : Colors.muted
                            opacity: island.hasPlayer ? 1 : 0.35

                            Behavior on height {
                                NumberAnimation {
                                    duration: 90
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "|"
                    color: Colors.alpha(Colors.fg, "2e")
                    font.pixelSize: 12
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: island.expanded ? (Qt.formatDateTime(clk.date, "dddd d MMMM") + " \u00b7 " + Qt.formatDateTime(clk.date, "HH:mm")) : Qt.formatDateTime(clk.date, "HH:mm")
                    color: Colors.fg
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: Colors.accent
                    anchors.verticalCenter: parent.verticalCenter
                    visible: island.hasUnread && !island.expanded
                    scale: visible ? 1 : 0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutBack
                        }
                    }
                }
            }

            MouseArea {
                x: island.expanded ? (morph.width - headRow.width) / 2 : 0
                y: 0
                width: headRow.width
                height: 26
                onClicked: island.toggleExpand()

                Behavior on x {
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Rectangle {
                id: tabBar
                x: 13
                y: 34
                width: tabRow.implicitWidth + 8
                height: 26
                radius: 9
                color: Colors.alpha(Colors.fg, "08")
                border.width: 1
                border.color: Colors.alpha(Colors.fg, "12")
                visible: island.expanded
                opacity: island.expanded ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                    }
                }

                Rectangle {
                    id: tabPill
                    y: 3
                    height: parent.height - 6
                    width: tabRepeater.itemAt(island.tabIndex) ? tabRepeater.itemAt(island.tabIndex).width : 0
                    x: tabRepeater.itemAt(island.tabIndex) ? tabRepeater.itemAt(island.tabIndex).x + 3 : 0
                    radius: 7
                    color: Colors.alpha(Colors.accent, "2e")
                    border.width: 1
                    border.color: Colors.alpha(Colors.accent, "3d")

                    Behavior on x {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Row {
                    id: tabRow
                    x: 3
                    y: 3
                    height: parent.height - 6
                    spacing: 0

                    Repeater {
                        id: tabRepeater
                        model: [{
                            "id": "music",
                            "label": "music",
                            "icon": "\uf001"
                        }, {
                            "id": "settings",
                            "label": "settings",
                            "icon": "\uf013"
                        }]

                        delegate: Item {
                            required property var modelData
                            required property int index
                            height: tabRow.height
                            width: 34

                            Text {
                                id: tabIcon
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: "Maple Mono NF"
                                font.pixelSize: 12
                                color: island.tab === modelData.id ? Colors.accent : Colors.muted
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: island.tab = modelData.id
                            }
                        }
                    }
                }
            }

            Row {
                id: cols
                x: 13
                y: 70
                spacing: 14
                opacity: island.expanded ? 1 : 0
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                    }
                }

                    Column {
                        id: leftCol
                        width: 380
                        spacing: 0

                        Column {
                            id: musicTab
                            width: parent.width
                            spacing: 9
                            visible: island.tab === "music"

                            Item {
                                                    id: musicCard
                                                    width: parent.width
                                                    height: 262
                                                    visible: island.currentPlayer !== null
                                                    readonly property var cur: island.currentPlayer
                                                    readonly property real progress: cur && cur.length > 0 ? Math.min(1, cur.position / cur.length) : 0
                                                    readonly property bool playing: cur !== null && cur.playing
                                                    readonly property string art: cur !== null && cur.art ? cur.art : ""
                                                    readonly property string glyph: {
                                                        const n = cur ? cur.name.toLowerCase() : ""
                                                        if (n.includes("chromium") || n.includes("chrome") || n.includes("brave"))
                                                            return "\uf268"
                                                        if (n.includes("firefox"))
                                                            return "\uf269"
                                                        if (n.includes("spotify"))
                                                            return "\uf1bc"
                                                        if (n.includes("mpv") || n.includes("vlc"))
                                                            return "\uf008"
                                                        return "\uf001"
                                                    }

                                                    property real dragValue: 0
                                                    property bool dragging: false
                                                    property real wavePhase: 0
                                                    readonly property real shownProgress: dragging ? dragValue : progress

                                                    function arcPoints(startDeg, endDeg, phase, amp) {
                                                        const pts = []
                                                        const cx = discArea.width / 2
                                                        const cy = discArea.height / 2
                                                        const baseR = discArea.ringRadius
                                                        const step = 1.5
                                                        for (let d = startDeg; d <= endDeg; d += step) {
                                                            const rad = d * Math.PI / 180
                                                            const r = baseR + Math.sin(rad * 22 + phase) * amp
                                                            pts.push(Qt.point(cx + r * Math.cos(rad), cy + r * Math.sin(rad)))
                                                        }
                                                        return pts
                                                    }

                                                    NumberAnimation on wavePhase {
                                                        from: 0
                                                        to: Math.PI * 2
                                                        duration: 1400
                                                        loops: Animation.Infinite
                                                        running: musicCard.playing && musicCard.visible
                                                    }

                                                    ClippingRectangle {
                                                        anchors.fill: parent
                                                        radius: 14
                                                        color: Colors.alpha(Colors.fg, "06")

                                                        Image {
                                                            id: bgBlurSrc
                                                            anchors.fill: parent
                                                            source: musicCard.art
                                                            sourceSize: Qt.size(48, 48)
                                                            fillMode: Image.PreserveAspectCrop
                                                            visible: false
                                                            asynchronous: true
                                                        }

                                                        MultiEffect {
                                                            anchors.fill: parent
                                                            visible: bgBlurSrc.status === Image.Ready
                                                            source: bgBlurSrc
                                                            blurEnabled: true
                                                            blur: 1.0
                                                            blurMax: 64
                                                            saturation: 0.25
                                                            autoPaddingEnabled: false
                                                        }

                                                        Rectangle {
                                                            anchors.fill: parent
                                                            visible: bgBlurSrc.status === Image.Ready
                                                            color: Colors.alpha(Colors.bg, "55")
                                                        }
                                                    }

                                                    Item {
                                                        id: discArea
                                                        x: (parent.width - width) / 2
                                                        y: 10
                                                        width: 132
                                                        height: 132
                                                        readonly property real ringRadius: Math.min(width, height) / 2 - 9

                                                        Shape {
                                                            anchors.fill: parent
                                                            preferredRendererType: Shape.CurveRenderer

                                                            ShapePath {
                                                                strokeColor: Colors.alpha(Colors.fg, "30")
                                                                strokeWidth: 4
                                                                fillColor: "transparent"
                                                                capStyle: ShapePath.RoundCap
                                                                startX: trackPoly.path.length > 0 ? trackPoly.path[0].x : 0
                                                                startY: trackPoly.path.length > 0 ? trackPoly.path[0].y : 0

                                                                PathPolyline {
                                                                    id: trackPoly
                                                                    path: musicCard.arcPoints(180, 360, 0, 0)
                                                                }
                                                            }

                                                            ShapePath {
                                                                strokeColor: Colors.accent
                                                                strokeWidth: 4
                                                                fillColor: "transparent"
                                                                capStyle: ShapePath.RoundCap
                                                                startX: progPoly.path.length > 0 ? progPoly.path[0].x : 0
                                                                startY: progPoly.path.length > 0 ? progPoly.path[0].y : 0

                                                                PathPolyline {
                                                                    id: progPoly
                                                                    path: musicCard.arcPoints(180, 180 + Math.max(0.1, 180 * musicCard.shownProgress), musicCard.wavePhase, musicCard.playing ? 1.8 : 0)
                                                                }
                                                            }
                                                        }

                                                        Item {
                                                            id: discWrap
                                                            anchors.centerIn: parent
                                                            width: 94
                                                            height: 94

                                                            NumberAnimation on rotation {
                                                                from: 0
                                                                to: 360
                                                                duration: 12000
                                                                loops: Animation.Infinite
                                                                running: musicCard.playing && musicCard.visible
                                                            }

                                                            ClippingRectangle {
                                                                id: discClip
                                                                anchors.fill: parent
                                                                radius: width / 2
                                                                color: Colors.alpha(Colors.accent, "1f")

                                                                Image {
                                                                    id: discArt
                                                                    anchors.fill: parent
                                                                    source: musicCard.art
                                                                    sourceSize: Qt.size(256, 256)
                                                                    fillMode: Image.PreserveAspectCrop
                                                                    asynchronous: true
                                                                    visible: status === Image.Ready
                                                                }

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    visible: discArt.status !== Image.Ready
                                                                    text: "\uf001"
                                                                    font.family: "Maple Mono NF"
                                                                    font.pixelSize: 30
                                                                    color: Colors.alpha(Colors.accent, "cc")
                                                                }
                                                            }

                                                            Rectangle {
                                                                anchors.fill: parent
                                                                radius: width / 2
                                                                color: "transparent"
                                                                border.width: 1
                                                                border.color: Colors.alpha(Colors.accent, "59")
                                                            }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            enabled: musicCard.cur !== null && musicCard.cur.length > 0
                                                            preventStealing: true

                                                            function valueAt(mx, my) {
                                                                let ang = Math.atan2(my - height / 2, mx - width / 2)
                                                                if (ang < 0)
                                                                    ang += 2 * Math.PI
                                                                const startRad = Math.PI
                                                                let rel = ang - startRad
                                                                while (rel < 0)
                                                                    rel += 2 * Math.PI
                                                                if (rel <= Math.PI)
                                                                    return rel / Math.PI
                                                                return (rel - Math.PI < 2 * Math.PI - rel) ? 1 : 0
                                                            }

                                                            onPressed: (mouse) => {
                                                                musicCard.dragValue = musicCard.progress
                                                                musicCard.dragging = true
                                                                musicCard.dragValue = valueAt(mouse.x, mouse.y)
                                                            }
                                                            onPositionChanged: (mouse) => {
                                                                if (pressed)
                                                                    musicCard.dragValue = valueAt(mouse.x, mouse.y)
                                                            }
                                                            onReleased: {
                                                                if (musicCard.dragging && musicCard.cur && musicCard.cur.length > 0)
                                                                    island.seek(musicCard.cur.name, musicCard.dragValue * musicCard.cur.length)
                                                                musicCard.dragging = false
                                                            }
                                                        }
                                                    }

                                                    Column {
                                                        id: metaCol
                                                        y: discArea.y + discArea.height + 4
                                                        x: 12
                                                        width: parent.width - 24
                                                        spacing: 1

                                                        Text {
                                                            width: parent.width
                                                            horizontalAlignment: Text.AlignHCenter
                                                            text: musicCard.cur ? musicCard.cur.title : ""
                                                            color: Colors.fg
                                                            font.pixelSize: 12
                                                            font.weight: Font.Bold
                                                            elide: Text.ElideRight
                                                        }

                                                        Text {
                                                            width: parent.width
                                                            horizontalAlignment: Text.AlignHCenter
                                                            visible: musicCard.cur !== null && musicCard.cur.album.length > 0
                                                            text: musicCard.cur ? musicCard.cur.album : ""
                                                            color: Colors.fg
                                                            opacity: 0.7
                                                            font.pixelSize: 10
                                                            elide: Text.ElideRight
                                                        }

                                                        Text {
                                                            width: parent.width
                                                            horizontalAlignment: Text.AlignHCenter
                                                            text: musicCard.cur ? musicCard.cur.artist : ""
                                                            color: Colors.fg
                                                            opacity: 0.7
                                                            font.pixelSize: 10
                                                            elide: Text.ElideRight
                                                        }
                                                    }

                                                    Row {
                                                        id: ctlRow
                                                        y: metaCol.y + metaCol.implicitHeight + 6
                                                        x: (parent.width - width) / 2
                                                        height: 34
                                                        spacing: 12

                                                        Text {
                                                            id: playerGlyphBtn
                                                            height: parent.height
                                                            verticalAlignment: Text.AlignVCenter
                                                            text: musicCard.glyph
                                                            font.family: "Maple Mono NF"
                                                            font.pixelSize: 14
                                                            color: glyphHover.containsMouse ? Colors.accent : Colors.fg
                                                            opacity: 0.85

                                                            MouseArea {
                                                                id: glyphHover
                                                                anchors.fill: parent
                                                                anchors.margins: -4
                                                                hoverEnabled: true
                                                                onClicked: island.nextPlayer()
                                                            }
                                                        }

                                                        Text {
                                                            id: prevBtn
                                                            height: parent.height
                                                            verticalAlignment: Text.AlignVCenter
                                                            text: "\uf048"
                                                            font.family: "Maple Mono NF"
                                                            font.pixelSize: 14
                                                            color: prevHover.containsMouse ? Colors.accent : Colors.fg

                                                            MouseArea {
                                                                id: prevHover
                                                                anchors.fill: parent
                                                                anchors.margins: -4
                                                                hoverEnabled: true
                                                                onClicked: island.pc(["previous"], musicCard.cur ? musicCard.cur.name : "")
                                                            }
                                                        }

                                                        Rectangle {
                                                            id: playSquare
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            width: 38
                                                            height: 38
                                                            radius: musicCard.playing ? 10 : 19
                                                            color: playHover.containsMouse ? Colors.alpha(Colors.accent, "d9") : Colors.accent

                                                            Behavior on radius {
                                                                NumberAnimation {
                                                                    duration: 300
                                                                    easing.type: Easing.OutBack
                                                                }
                                                            }

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: musicCard.cur && musicCard.cur.playing ? "\uf04c" : "\uf04b"
                                                                font.family: "Maple Mono NF"
                                                                font.pixelSize: 15
                                                                color: Colors.bg
                                                            }

                                                            MouseArea {
                                                                id: playHover
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                onClicked: island.pc(["play-pause"], musicCard.cur ? musicCard.cur.name : "")
                                                            }
                                                        }

                                                        Text {
                                                            id: nextBtn
                                                            height: parent.height
                                                            verticalAlignment: Text.AlignVCenter
                                                            text: "\uf051"
                                                            font.family: "Maple Mono NF"
                                                            font.pixelSize: 14
                                                            color: nextHover.containsMouse ? Colors.accent : Colors.fg

                                                            MouseArea {
                                                                id: nextHover
                                                                anchors.fill: parent
                                                                anchors.margins: -4
                                                                hoverEnabled: true
                                                                onClicked: island.pc(["next"], musicCard.cur ? musicCard.cur.name : "")
                                                            }
                                                        }

                                                        Text {
                                                            id: modeBtn
                                                            height: parent.height
                                                            verticalAlignment: Text.AlignVCenter
                                                            text: island.shuffleOn ? "\uf074" : "\uf079"
                                                            font.family: "Maple Mono NF"
                                                            font.pixelSize: 14
                                                            color: (island.shuffleOn || island.loopState > 0) ? Colors.accent : (modeHover.containsMouse ? Colors.accent : Colors.fg)

                                                            MouseArea {
                                                                id: modeHover
                                                                anchors.fill: parent
                                                                anchors.margins: -4
                                                                hoverEnabled: true
                                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                                onClicked: (mouse) => {
                                                                    const n = musicCard.cur ? musicCard.cur.name : ""
                                                                    if (mouse.button === Qt.RightButton)
                                                                        island.cycleLoop(n)
                                                                    else
                                                                        island.toggleShuffle(n)
                                                                }
                                                            }
                                                        }
                                                    }

                                                    Text {
                                                        id: timeRow
                                                        y: ctlRow.y + ctlRow.height + 10
                                                        width: parent.width
                                                        horizontalAlignment: Text.AlignHCenter
                                                        text: island.fmtTime(musicCard.cur ? musicCard.cur.position : 0) + " / " + island.fmtTime(musicCard.cur ? musicCard.cur.length : 0)
                                                        color: Colors.fg
                                                        opacity: 0.5
                                                        font.pixelSize: 9
                                                    }

                                                    Rectangle {
                                                        anchors.fill: parent
                                                        radius: 14
                                                        color: "transparent"
                                                        border.width: 1
                                                        border.color: Colors.alpha(Colors.accent, "4d")
                                                    }
                                                }

                                                Row {
                                                    id: playerPager
                                                    visible: island.players.length > 1
                                                    x: (parent.width - width) / 2
                                                    height: 16
                                                    spacing: 7

                                                    Text {
                                                        id: pagerPrev
                                                        height: parent.height
                                                        verticalAlignment: Text.AlignVCenter
                                                        text: "\uf053"
                                                        font.family: "Maple Mono NF"
                                                        font.pixelSize: 9
                                                        color: pagerPrevHover.containsMouse ? Colors.fg : Colors.alpha(Colors.muted, "99")

                                                        MouseArea {
                                                            id: pagerPrevHover
                                                            anchors.fill: parent
                                                            anchors.margins: -4
                                                            hoverEnabled: true
                                                            onClicked: island.prevPlayer()
                                                        }
                                                    }

                                                    Row {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        spacing: 5

                                                        Repeater {
                                                            model: island.players.length

                                                            delegate: Rectangle {
                                                                required property int index
                                                                width: 5
                                                                height: 5
                                                                radius: 2.5
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                color: index === island.playerIndex ? Colors.accent : Colors.alpha(Colors.fg, "33")

                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    anchors.margins: -3
                                                                    onClicked: island.playerIndex = index
                                                                }
                                                            }
                                                        }
                                                    }

                                                    Text {
                                                        id: pagerNext
                                                        height: parent.height
                                                        verticalAlignment: Text.AlignVCenter
                                                        text: "\uf054"
                                                        font.family: "Maple Mono NF"
                                                        font.pixelSize: 9
                                                        color: pagerNextHover.containsMouse ? Colors.fg : Colors.alpha(Colors.muted, "99")

                                                        MouseArea {
                                                            id: pagerNextHover
                                                            anchors.fill: parent
                                                            anchors.margins: -4
                                                            hoverEnabled: true
                                                            onClicked: island.nextPlayer()
                                                        }
                                                    }
                                                }

                                                Text {
                                                    visible: island.players.length === 0
                                                    text: "No players"
                                                    color: Colors.muted
                                                    font.pixelSize: 11
                                                }
                                                Rectangle {
                                                    width: parent.width
                                                    height: 1
                                                    color: Colors.alpha(Colors.fg, "22")
                                                }

                                                Text {
                                                    text: "AUDIO"
                                                    color: Colors.muted
                                                    font.pixelSize: 10
                                                    font.weight: Font.DemiBold
                                                }

                                                Item {
                                                    width: parent.width
                                                    height: 20

                                                    Text {
                                                        id: spkIcon
                                                        text: Wp.sinkMuted ? "\uf026" : "\uf028"
                                                        color: Wp.sinkMuted ? Colors.muted : Colors.accent
                                                        font.family: "Maple Mono NF"
                                                        font.pixelSize: 12
                                                        width: 14
                                                        horizontalAlignment: Text.AlignHCenter
                                                        anchors.left: parent.left
                                                        anchors.verticalCenter: parent.verticalCenter

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: Wp.toggleSinkMute()
                                                        }
                                                    }

                                                    Text {
                                                        id: volPct
                                                        text: Wp.sinkMuted ? "Muted" : Math.round(Wp.sinkVol * 100) + "%"
                                                        color: Wp.sinkMuted ? Colors.accent : Colors.fg
                                                        font.pixelSize: 11
                                                        anchors.right: parent.right
                                                        anchors.verticalCenter: parent.verticalCenter

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: Wp.toggleSinkMute()
                                                        }
                                                    }

                                                    Rectangle {
                                                        id: track
                                                        anchors.left: spkIcon.right
                                                        anchors.leftMargin: 8
                                                        anchors.right: volPct.left
                                                        anchors.rightMargin: 8
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        height: 6
                                                        radius: 3
                                                        color: Colors.alpha(Colors.muted, "40")

                                                        Rectangle {
                                                            width: Math.round(parent.width * Wp.sinkVol)
                                                            height: parent.height
                                                            radius: 3
                                                            color: Wp.sinkMuted ? Colors.muted : Colors.accent

                                                            Behavior on width {
                                                                NumberAnimation {
                                                                    duration: 120
                                                                }
                                                            }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onPositionChanged: (mouse) => {
                                                                if (pressed)
                                                                    Wp.setSinkVolume(mouse.x / width)
                                                            }
                                                            onClicked: (mouse) => Wp.setSinkVolume(mouse.x / width)
                                                        }
                                                    }
                                                }

                                                Item {
                                                    width: parent.width
                                                    height: 20

                                                    Text {
                                                        id: micIcon
                                                        text: Wp.sourceMuted ? "\uf131" : "\uf130"
                                                        color: Wp.sourceMuted ? Colors.muted : Colors.accent
                                                        font.family: "Maple Mono NF"
                                                        font.pixelSize: 12
                                                        width: 14
                                                        horizontalAlignment: Text.AlignHCenter
                                                        anchors.left: parent.left
                                                        anchors.verticalCenter: parent.verticalCenter

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: Wp.toggleSourceMute()
                                                        }
                                                    }

                                                    Text {
                                                        id: micPct
                                                        text: Wp.sourceMuted ? "Muted" : Math.round(Wp.sourceVol * 100) + "%"
                                                        color: Wp.sourceMuted ? Colors.accent : Colors.fg
                                                        font.pixelSize: 11
                                                        anchors.right: parent.right
                                                        anchors.verticalCenter: parent.verticalCenter

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: Wp.toggleSourceMute()
                                                        }
                                                    }

                                                    Rectangle {
                                                        id: micTrack
                                                        anchors.left: micIcon.right
                                                        anchors.leftMargin: 8
                                                        anchors.right: micPct.left
                                                        anchors.rightMargin: 8
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        height: 6
                                                        radius: 3
                                                        color: Colors.alpha(Colors.muted, "40")

                                                        Rectangle {
                                                            width: Math.round(parent.width * Wp.sourceVol)
                                                            height: parent.height
                                                            radius: 3
                                                            color: Wp.sourceMuted ? Colors.muted : Colors.accent

                                                            Behavior on width {
                                                                NumberAnimation {
                                                                    duration: 120
                                                                }
                                                            }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onPositionChanged: (mouse) => {
                                                                if (pressed)
                                                                    Wp.setSourceVolume(mouse.x / width)
                                                            }
                                                            onClicked: (mouse) => Wp.setSourceVolume(mouse.x / width)
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    id: outDrop
                                                    width: parent.width
                                                    height: 28
                                                    radius: 8
                                                    color: outDropHover.containsMouse || island.outOpen ? Colors.alpha(Colors.fg, "12") : Colors.alpha(Colors.fg, "08")

                                                    Row {
                                                        anchors.left: parent.left
                                                        anchors.leftMargin: 8
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        spacing: 8

                                                        Text {
                                                            text: "OUT"
                                                            color: Colors.accent
                                                            font.pixelSize: 10
                                                            font.weight: Font.DemiBold
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }

                                                        Text {
                                                            text: (Wp.sinks.find(s => s.def) ?? {
                                                                name: "\u2014"
                                                            }).name
                                                            color: Colors.fg
                                                            font.pixelSize: 11
                                                            elide: Text.ElideRight
                                                            width: 280
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }
                                                    }

                                                    Text {
                                                        anchors.right: parent.right
                                                        anchors.rightMargin: 8
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: island.outOpen ? "\u25b4" : "\u25be"
                                                        color: Colors.muted
                                                        font.pixelSize: 11
                                                    }

                                                    MouseArea {
                                                        id: outDropHover
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        onClicked: {
                                                            island.outOpen = !island.outOpen
                                                            island.inOpen = false
                                                        }
                                                    }
                                                }

                                                Column {
                                                    visible: island.outOpen
                                                    width: parent.width
                                                    height: island.outOpen ? implicitHeight : 0
                                                    opacity: island.outOpen ? 1 : 0
                                                    clip: true

                                                    Behavior on height {
                                                        NumberAnimation {
                                                            duration: 160
                                                            easing.type: Easing.OutCubic
                                                        }
                                                    }

                                                    Behavior on opacity {
                                                        NumberAnimation {
                                                            duration: 140
                                                        }
                                                    }

                                                    Repeater {
                                                        model: Wp.sinks

                                                        delegate: Rectangle {
                                                            required property var modelData
                                                            width: parent.width
                                                            height: 24
                                                            radius: 7
                                                            color: outHover.containsMouse ? Colors.alpha(Colors.fg, "12") : "transparent"

                                                            Rectangle {
                                                                id: dot
                                                                x: 8
                                                                width: 6
                                                                height: 6
                                                                radius: 3
                                                                y: parent.height / 2 - 3
                                                                color: modelData.def ? Colors.accent : "transparent"
                                                                border.width: 1
                                                                border.color: modelData.def ? Colors.accent : Colors.alpha(Colors.muted, "80")
                                                            }

                                                            Text {
                                                                anchors.left: dot.right
                                                                anchors.leftMargin: 8
                                                                anchors.right: parent.right
                                                                anchors.rightMargin: 6
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: modelData.name
                                                                color: modelData.def ? Colors.fg : Colors.muted
                                                                font.pixelSize: 11
                                                                elide: Text.ElideRight
                                                            }

                                                            MouseArea {
                                                                id: outHover
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                onClicked: {
                                                                    Wp.setDefault(modelData.id)
                                                                    island.outOpen = false
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    id: inDrop
                                                    width: parent.width
                                                    height: 28
                                                    radius: 8
                                                    color: inDropHover.containsMouse || island.inOpen ? Colors.alpha(Colors.fg, "12") : Colors.alpha(Colors.fg, "08")

                                                    Row {
                                                        anchors.left: parent.left
                                                        anchors.leftMargin: 8
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        spacing: 8

                                                        Text {
                                                            text: "IN"
                                                            color: Colors.accent
                                                            font.pixelSize: 10
                                                            font.weight: Font.DemiBold
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }

                                                        Text {
                                                            text: (Wp.sources.find(s => s.def) ?? {
                                                                name: "\u2014"
                                                            }).name
                                                            color: Colors.fg
                                                            font.pixelSize: 11
                                                            elide: Text.ElideRight
                                                            width: 280
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }
                                                    }

                                                    Text {
                                                        anchors.right: parent.right
                                                        anchors.rightMargin: 8
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: island.inOpen ? "\u25b4" : "\u25be"
                                                        color: Colors.muted
                                                        font.pixelSize: 11
                                                    }

                                                    MouseArea {
                                                        id: inDropHover
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        onClicked: {
                                                            island.inOpen = !island.inOpen
                                                            island.outOpen = false
                                                        }
                                                    }
                                                }

                                                Column {
                                                    visible: island.inOpen
                                                    width: parent.width
                                                    height: island.inOpen ? implicitHeight : 0
                                                    opacity: island.inOpen ? 1 : 0
                                                    clip: true

                                                    Behavior on height {
                                                        NumberAnimation {
                                                            duration: 160
                                                            easing.type: Easing.OutCubic
                                                        }
                                                    }

                                                    Behavior on opacity {
                                                        NumberAnimation {
                                                            duration: 140
                                                        }
                                                    }

                                                    Repeater {
                                                        model: Wp.sources

                                                        delegate: Rectangle {
                                                            required property var modelData
                                                            width: parent.width
                                                            height: 24
                                                            radius: 7
                                                            color: inHover.containsMouse ? Colors.alpha(Colors.fg, "12") : "transparent"

                                                            Rectangle {
                                                                id: dot
                                                                x: 8
                                                                width: 6
                                                                height: 6
                                                                radius: 3
                                                                y: parent.height / 2 - 3
                                                                color: modelData.def ? Colors.accent : "transparent"
                                                                border.width: 1
                                                                border.color: modelData.def ? Colors.accent : Colors.alpha(Colors.muted, "80")
                                                            }

                                                            Text {
                                                                anchors.left: dot.right
                                                                anchors.leftMargin: 8
                                                                anchors.right: parent.right
                                                                anchors.rightMargin: 6
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: modelData.name
                                                                color: modelData.def ? Colors.fg : Colors.muted
                                                                font.pixelSize: 11
                                                                elide: Text.ElideRight
                                                            }

                                                            MouseArea {
                                                                id: inHover
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                onClicked: {
                                                                    Wp.setDefault(modelData.id)
                                                                    island.inOpen = false
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                        }

                        Column {
                            id: settingsTab
                            width: parent.width
                            spacing: 9
                            visible: island.tab === "settings"

                                                Rectangle {
                                                    width: parent.width
                                                    height: 1
                                                    color: Colors.alpha(Colors.fg, "22")
                                                }

                                                Text {
                                                    text: "CONNECTIONS"
                                                    color: Colors.muted
                                                    font.pixelSize: 10
                                                    font.weight: Font.DemiBold
                                                }

                                                Row {
                                                    width: parent.width
                                                    spacing: 8
                                                    visible: island.connView === ""

                                                    Rectangle {
                                                        width: (parent.width - 8) / 2
                                                        height: 56
                                                        radius: 16
                                                        color: shell.wifiOn ? Colors.alpha(Colors.accent, "2e") : Colors.alpha(Colors.fg, "0a")
                                                        border.width: 1
                                                        border.color: shell.wifiOn ? "transparent" : Colors.alpha(Colors.fg, "12")

                                                        Text {
                                                            id: wifiIcon
                                                            x: 12
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: "\uf1eb"
                                                            font.family: "Maple Mono NF"
                                                            font.pixelSize: 18
                                                            color: shell.wifiOn ? Colors.accent : Colors.muted
                                                        }

                                                        Column {
                                                            anchors.left: wifiIcon.right
                                                            anchors.leftMargin: 10
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            spacing: 1

                                                            Text {
                                                                text: "Wi-Fi"
                                                                font.pixelSize: 11
                                                                font.weight: Font.DemiBold
                                                                color: shell.wifiOn ? Colors.fg : Colors.muted
                                                            }

                                                            Text {
                                                                text: shell.wifiOn ? "On" : "Off"
                                                                font.pixelSize: 10
                                                                color: Colors.muted
                                                            }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: island.connView = "wifi"
                                                        }
                                                    }

                                                    Rectangle {
                                                        width: (parent.width - 8) / 2
                                                        height: 56
                                                        radius: 16
                                                        color: shell.btOn ? Colors.alpha(Colors.accent, "2e") : Colors.alpha(Colors.fg, "0a")
                                                        border.width: 1
                                                        border.color: shell.btOn ? "transparent" : Colors.alpha(Colors.fg, "12")

                                                        Text {
                                                            id: btIcon
                                                            x: 12
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: "\uf293"
                                                            font.family: "Maple Mono NF"
                                                            font.pixelSize: 18
                                                            color: shell.btOn ? Colors.accent : Colors.muted
                                                        }

                                                        Column {
                                                            anchors.left: btIcon.right
                                                            anchors.leftMargin: 10
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            spacing: 1

                                                            Text {
                                                                text: "Bluetooth"
                                                                font.pixelSize: 11
                                                                font.weight: Font.DemiBold
                                                                color: shell.btOn ? Colors.fg : Colors.muted
                                                            }

                                                            Text {
                                                                text: shell.btOn ? "On" : "Off"
                                                                font.pixelSize: 10
                                                                color: Colors.muted
                                                            }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: island.connView = "bt"
                                                        }
                                                    }
                                                }

                                                Item {
                                                    visible: island.connView === "wifi"
                                                    width: parent.width
                                                    height: 22

                                                    Text {
                                                        id: wifiBack
                                                        anchors.left: parent.left
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "\uf060"
                                                        font.family: "Maple Mono NF"
                                                        font.pixelSize: 11
                                                        color: wifiBackHover.containsMouse ? Colors.accent : Colors.muted

                                                        MouseArea {
                                                            id: wifiBackHover
                                                            anchors.fill: parent
                                                            anchors.margins: -8
                                                            hoverEnabled: true
                                                            onClicked: {
                                                                island.pendingSsid = ""
                                                                island.connView = ""
                                                            }
                                                        }
                                                    }

                                                    Text {
                                                        anchors.left: wifiBack.right
                                                        anchors.leftMargin: 12
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "Wi-Fi"
                                                        font.pixelSize: 11
                                                        font.weight: Font.DemiBold
                                                        color: Colors.fg
                                                    }

                                                    Text {
                                                        anchors.right: parent.right
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: shell.wifiOn ? "On" : "Off"
                                                        font.pixelSize: 10
                                                        color: shell.wifiOn ? Colors.accent : Colors.muted

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: shell.toggleWifiRadio()
                                                        }
                                                    }
                                                }

                                                Text {
                                                    visible: island.connView === "wifi" && shell.wifiOn && shell.wifiNets.length > 0
                                                    text: "WIFI NETWORKS"
                                                    color: Colors.muted
                                                    font.pixelSize: 9
                                                    font.weight: Font.DemiBold
                                                }

                                                Column {
                                                    width: parent.width
                                                    spacing: 1
                                                    visible: island.connView === "wifi" && shell.wifiOn

                                                    Repeater {
                                                        model: shell.wifiOn ? shell.wifiNets : []

                                                        delegate: Rectangle {
                                                            required property var modelData
                                                            width: parent.width
                                                            height: 24
                                                            radius: 7
                                                            color: wHover.containsMouse ? Colors.alpha(Colors.fg, "12") : "transparent"

                                                            Text {
                                                                id: wSig
                                                                x: 4
                                                                width: 52
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: modelData.signal
                                                                font.family: "Maple Mono NF"
                                                                font.pixelSize: 9
                                                                color: modelData.connected ? Colors.accent : Colors.muted
                                                            }

                                                            Text {
                                                                anchors.left: wSig.right
                                                                anchors.leftMargin: 4
                                                                anchors.right: wLock.left
                                                                anchors.rightMargin: 6
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: modelData.ssid
                                                                font.pixelSize: 10
                                                                color: modelData.connected ? Colors.fg : Colors.muted
                                                                elide: Text.ElideRight
                                                            }

                                                            Text {
                                                                id: wLock
                                                                anchors.right: wCheck.left
                                                                anchors.rightMargin: 6
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: modelData.secured ? "\uf023" : ""
                                                                font.family: "Maple Mono NF"
                                                                font.pixelSize: 9
                                                                color: Colors.muted
                                                            }

                                                            Text {
                                                                id: wCheck
                                                                anchors.right: parent.right
                                                                anchors.rightMargin: 6
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: modelData.connected ? "\uf00c" : ""
                                                                font.family: "Maple Mono NF"
                                                                font.pixelSize: 9
                                                                color: Colors.accent
                                                            }

                                                            MouseArea {
                                                                id: wHover
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                onClicked: {
                                                                    if (modelData.connected) {
                                                                        shell.wifiDisconnect()
                                                                    } else if (modelData.secured) {
                                                                        island.pendingSsid = modelData.ssid
                                                                        pwInput.forceActiveFocus()
                                                                    } else {
                                                                        shell.wifiConnect(modelData.ssid, "")
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    visible: island.connView === "wifi" && island.pendingSsid.length > 0
                                                    width: parent.width
                                                    height: 30
                                                    radius: 8
                                                    color: Colors.alpha(Colors.fg, "0a")
                                                    border.width: 1
                                                    border.color: Colors.alpha(Colors.accent, "44")

                                                    Text {
                                                        id: pwBack
                                                        anchors.left: parent.left
                                                        anchors.leftMargin: 8
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "\uf060"
                                                        font.family: "Maple Mono NF"
                                                        font.pixelSize: 11
                                                        color: pwBackHover.containsMouse ? Colors.accent : Colors.muted

                                                        MouseArea {
                                                            id: pwBackHover
                                                            anchors.fill: parent
                                                            anchors.margins: -6
                                                            hoverEnabled: true
                                                            onClicked: {
                                                                island.pendingSsid = ""
                                                                pwInput.text = ""
                                                            }
                                                        }
                                                    }

                                                    TextInput {
                                                        id: pwInput
                                                        anchors.left: pwBack.right
                                                        anchors.leftMargin: 10
                                                        anchors.right: pwGo.left
                                                        anchors.rightMargin: 10
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        height: 20
                                                        verticalAlignment: TextInput.AlignVCenter
                                                        echoMode: TextInput.Password
                                                        font.pixelSize: 11
                                                        color: Colors.fg
                                                        clip: true
                                                        selectByMouse: true
                                                        onAccepted: {
                                                            shell.wifiConnect(island.pendingSsid, text)
                                                            island.pendingSsid = ""
                                                            text = ""
                                                        }
                                                    }

                                                    Text {
                                                        id: pwGo
                                                        anchors.right: parent.right
                                                        anchors.rightMargin: 8
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "\uf061"
                                                        font.family: "Maple Mono NF"
                                                        font.pixelSize: 11
                                                        color: pwGoHover.containsMouse ? Colors.accent : Colors.muted

                                                        MouseArea {
                                                            id: pwGoHover
                                                            anchors.fill: parent
                                                            anchors.margins: -6
                                                            hoverEnabled: true
                                                            onClicked: {
                                                                shell.wifiConnect(island.pendingSsid, pwInput.text)
                                                                island.pendingSsid = ""
                                                                pwInput.text = ""
                                                            }
                                                        }
                                                    }
                                                }

                                                Item {
                                                    visible: island.connView === "bt"
                                                    width: parent.width
                                                    height: 22

                                                    Text {
                                                        id: btBack
                                                        anchors.left: parent.left
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "\uf060"
                                                        font.family: "Maple Mono NF"
                                                        font.pixelSize: 11
                                                        color: btBackHover.containsMouse ? Colors.accent : Colors.muted

                                                        MouseArea {
                                                            id: btBackHover
                                                            anchors.fill: parent
                                                            anchors.margins: -8
                                                            hoverEnabled: true
                                                            onClicked: island.connView = ""
                                                        }
                                                    }

                                                    Text {
                                                        anchors.left: btBack.right
                                                        anchors.leftMargin: 8
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "Bluetooth"
                                                        font.pixelSize: 11
                                                        font.weight: Font.DemiBold
                                                        color: Colors.fg
                                                    }

                                                    Text {
                                                        anchors.right: parent.right
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: shell.btOn ? "On" : "Off"
                                                        font.pixelSize: 10
                                                        color: shell.btOn ? Colors.accent : Colors.muted

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: shell.toggleBtPower()
                                                        }
                                                    }
                                                }

                                                Text {
                                                    visible: island.connView === "bt" && shell.btOn && shell.btDevices.length > 0
                                                    text: "BLUETOOTH DEVICES"
                                                    color: Colors.muted
                                                    font.pixelSize: 9
                                                    font.weight: Font.DemiBold
                                                }

                                                Column {
                                                    width: parent.width
                                                    spacing: 1
                                                    visible: island.connView === "bt" && shell.btOn

                                                    Repeater {
                                                        model: shell.btOn ? shell.btDevices : []

                                                        delegate: Rectangle {
                                                            required property var modelData
                                                            width: parent.width
                                                            height: 24
                                                            radius: 7
                                                            color: bHover.containsMouse ? Colors.alpha(Colors.fg, "12") : "transparent"

                                                            Text {
                                                                id: bIcon
                                                                x: 4
                                                                width: 16
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: modelData.connected ? "\uf293" : "\uf294"
                                                                font.family: "Maple Mono NF"
                                                                font.pixelSize: 10
                                                                color: modelData.connected ? Colors.accent : Colors.muted
                                                            }

                                                            Text {
                                                                anchors.left: bIcon.right
                                                                anchors.leftMargin: 6
                                                                anchors.right: bState.left
                                                                anchors.rightMargin: 6
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: modelData.name
                                                                font.pixelSize: 10
                                                                color: modelData.connected ? Colors.fg : Colors.muted
                                                                elide: Text.ElideRight
                                                            }

                                                            Text {
                                                                id: bState
                                                                anchors.right: parent.right
                                                                anchors.rightMargin: 6
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: modelData.connected ? "connected" : ""
                                                                font.pixelSize: 9
                                                                color: Colors.accent
                                                            }

                                                            MouseArea {
                                                                id: bHover
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                onClicked: shell.btToggleDevice(modelData.mac, modelData.connected)
                                                            }
                                                        }
                                                    }
                                                }

                                                Row {
                                                    width: parent.width
                                                    spacing: 6

                                                    Text {
                                                        id: connIcon
                                                        text: "\uf6ff"
                                                        font.family: "Maple Mono NF"
                                                        font.pixelSize: 11
                                                        color: Colors.muted
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }

                                                    Text {
                                                        text: {
                                                            let t = shell.connDev.length > 0 ? shell.connDev + " \u00b7 " + shell.connAddr : "No connection"
                                                            if (shell.tsIp.length > 0)
                                                                t += " \u00b7 ts " + shell.tsIp
                                                            return t
                                                        }
                                                        font.pixelSize: 10
                                                        color: Colors.muted
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        elide: Text.ElideRight
                                                        width: parent.width - 20
                                                    }
                                                }
                                            }
                        }

                Column {
                    id: rightCol
                    width: 312
                    spacing: 9

                    Item {
                        width: parent.width
                        height: 14

                        Text {
                            text: "NOTIFICATIONS"
                            color: Colors.muted
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Text {
                                text: ns.trackedNotifications.values.length
                                color: Colors.accent
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "Clear"
                                color: Colors.muted
                                font.pixelSize: 10

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: island.clearAll()
                                }
                            }
                        }
                    }

                    Flickable {
                        id: notifFlick
                        width: parent.width
                        height: Math.min(notifCol.implicitHeight, island.panelMaxH - cols.y - 22 - 14 - 9)
                        contentHeight: notifCol.implicitHeight
                        contentWidth: width
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: contentHeight > height

                        Column {
                            id: notifCol
                            width: notifFlick.width
                            spacing: 9

                            Repeater {
                                id: notifRepeater
                                model: ns.trackedNotifications

                                delegate: Rectangle {
                                    id: ncard
                                    required property var modelData
                                    readonly property var notif: modelData
                                    property bool vanishing: false
                                    property int vanishDelay: 0
                                    width: notifCol.width
                                    height: cardCol.implicitHeight + 14
                                    radius: 10
                                    color: Colors.alpha(Colors.fg, "0a")
                                    border.width: 1
                                    border.color: notif && notif.urgency === 2 ? Colors.alpha(Colors.accent2, "66") : Colors.alpha(Colors.fg, "14")
                                    clip: true

                                    function vanish(delay) {
                                        vanishDelay = delay || 0
                                        if (vanishing)
                                            return
                                        vanishing = true
                                        vanishSeq.start()
                                    }

                                    SequentialAnimation {
                                        id: vanishSeq
                                        PauseAnimation {
                                            duration: ncard.vanishDelay
                                        }

                                        ParallelAnimation {
                                            NumberAnimation {
                                                target: ncard
                                                property: "x"
                                                to: ncard.width * 0.45
                                                duration: 200
                                                easing.type: Easing.OutCubic
                                            }

                                            NumberAnimation {
                                                target: ncard
                                                property: "opacity"
                                                to: 0
                                                duration: 200
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        NumberAnimation {
                                            target: ncard
                                            property: "height"
                                            to: 0
                                            duration: 140
                                            easing.type: Easing.OutCubic
                                        }

                                        ScriptAction {
                                            script: ncard.notif.dismiss()
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: (mouse) => {
                                            if (!notif)
                                                return
                                            if (mouse.button === Qt.RightButton) {
                                                ncard.vanish(0)
                                                return
                                            }
                                            const acts = notif.actions
                                            for (let i = 0; i < acts.length; i++) {
                                                if (acts[i].identifier === "default") {
                                                    acts[i].invoke()
                                                    return
                                                }
                                            }
                                        }
                                    }

                                    Column {
                                        id: cardCol
                                        x: 8
                                        y: 7
                                        width: parent.width - 16
                                        spacing: 3

                                        Text {
                                            text: notif ? notif.appName : ""
                                            color: Colors.accent
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }

                                        Text {
                                            text: notif ? notif.summary : ""
                                            color: Colors.fg
                                            font.pixelSize: 11
                                            wrapMode: Text.Wrap
                                            width: parent.width
                                        }

                                        Text {
                                            visible: notif && notif.body.length > 0
                                            text: notif ? notif.body : ""
                                            color: Colors.muted
                                            font.pixelSize: 10
                                            wrapMode: Text.Wrap
                                            width: parent.width
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: ns.trackedNotifications.values.length === 0
                                text: "No notifications"
                                color: Colors.muted
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            visible: notifFlick.contentHeight > notifFlick.height
                            x: notifFlick.width - 4
                            y: notifFlick.visibleArea.yPosition * notifFlick.height
                            width: 3
                            height: Math.max(20, notifFlick.visibleArea.heightRatio * notifFlick.height)
                            radius: 1.5
                            color: Colors.alpha(Colors.fg, "33")
                        }
                    }
                }
            }
        }

        Rectangle {
            id: wsPill
            x: 8
            y: 2
            width: Math.min(wsRow.width + 20, 184)
            height: 26
            radius: 13
            color: Colors.bg
            border.width: 1
            border.color: Colors.alpha(Colors.accent, "3d")

            MouseArea {
                anchors.fill: parent
            }

            Row {
                id: wsRow
                x: 10
                height: parent.height
                spacing: 7

                Repeater {
                    model: mainWs ? mainWs.list : []

                    delegate: Rectangle {
                        required property var modelData
                        width: 10
                        height: 10
                        radius: 5
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData.active ? Colors.accent : "transparent"
                        border.width: 1
                        border.color: modelData.active ? Colors.accent : Colors.alpha(Colors.muted, "99")
                    }
                }
            }
        }

        Rectangle {
            id: trayPill
            anchors.right: powerPill.left
            anchors.rightMargin: 6
            y: 2
            width: trayOpen ? (trayMenuHandle !== null ? 252 : 176) : 26
            height: trayOpen ? (trayCol.implicitHeight + 12) : 26
            radius: trayOpen ? 14 : 13
            color: Colors.bg
            border.width: 1
            border.color: Colors.alpha(Colors.accent, "3d")
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on radius {
                NumberAnimation {
                    duration: 160
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: trayOpen
                onClicked: trayClose()
            }

            Text {
                id: trayChevron
                anchors.fill: parent
                text: "\uf078"
                font.family: "Maple Mono NF"
                font.pixelSize: 12
                color: trayHover.containsMouse ? Colors.accent2 : Colors.accent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                rightPadding: 2
                bottomPadding: 2
                visible: !trayOpen
            }

            MouseArea {
                id: trayHover
                anchors.fill: parent
                hoverEnabled: true
                enabled: !trayOpen
                onClicked: {
                    island.expanded = false
                    island.powerOpen = false
                    island.trayMenuHandle = null
                    island.trayMenuStack = []
                    trayOpen = true
                }
            }

            Column {
                id: trayCol
                x: 6
                y: 6
                width: parent.width - 12
                spacing: 2
                visible: trayOpen
                opacity: trayOpen ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 140
                    }
                }

                Item {
                    visible: island.trayMenuHandle !== null
                    width: parent.width
                    height: 22

                    Text {
                        id: trayMenuBack
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf060"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 11
                        color: trayMenuBackHover.containsMouse ? Colors.accent : Colors.muted

                        MouseArea {
                            id: trayMenuBackHover
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            onClicked: island.trayMenuBack()
                        }
                    }

                    Text {
                        anchors.left: trayMenuBack.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: island.trayMenuTitle
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: Colors.fg
                        elide: Text.ElideRight
                    }
                }

                QsMenuOpener {
                    id: trayOpener
                    menu: island.trayMenuHandle
                }

                Repeater {
                    model: island.trayMenuHandle !== null ? trayOpener.children : []

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: modelData.isSeparator ? 9 : 24
                        radius: 6
                        color: !modelData.isSeparator && tEntryHover.containsMouse ? Colors.alpha(Colors.fg, "12") : "transparent"

                        Rectangle {
                            visible: modelData.isSeparator
                            x: 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 8
                            height: 1
                            color: Colors.alpha(Colors.fg, "1f")
                        }

                        Text {
                            visible: !modelData.isSeparator
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.text
                            font.pixelSize: 10
                            color: !modelData.enabled ? Colors.alpha(Colors.muted, "66") : (tEntryHover.containsMouse ? Colors.fg : Colors.muted)
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: !modelData.isSeparator && modelData.hasChildren
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf054"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 9
                            color: Colors.muted
                        }

                        MouseArea {
                            id: tEntryHover
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !modelData.isSeparator && modelData.enabled
                            onClicked: {
                                if (modelData.hasChildren) {
                                    island.trayMenuDrill(modelData)
                                } else {
                                    modelData.triggered()
                                    island.trayClose()
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: island.trayMenuHandle === null && SystemTray.items.values.length === 0
                    text: "No tray items"
                    font.pixelSize: 11
                    color: Colors.muted
                }

                Repeater {
                    model: island.trayMenuHandle === null ? SystemTray.items : []

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 26
                        radius: 7
                        color: tinHover.containsMouse ? Colors.alpha(Colors.fg, "12") : "transparent"

                        Image {
                            id: tinIcon
                            x: 6
                            width: 14
                            height: 14
                            anchors.verticalCenter: parent.verticalCenter
                            source: modelData.icon
                            sourceSize: Qt.size(14, 14)
                            smooth: true
                        }

                        Text {
                            anchors.left: tinIcon.right
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.title.length > 0 ? modelData.title : modelData.id
                            font.pixelSize: 11
                            color: tinHover.containsMouse ? Colors.fg : Colors.muted
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: tinHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (modelData.hasMenu) {
                                    island.trayMenuOpen(modelData)
                                } else if (mouse.button === Qt.RightButton) {
                                    modelData.secondaryActivate()
                                    island.trayClose()
                                } else {
                                    modelData.activate()
                                    island.trayClose()
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
                        id: powerPill
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        y: 2
                        width: powerOpen ? 150 : 26
                        height: powerOpen ? (powerCol.implicitHeight + 12) : 26
                        radius: powerOpen ? 14 : 13
                        color: Colors.bg
                        border.width: 1
                        border.color: Colors.alpha(Colors.accent, "3d")
                        clip: true

                        MouseArea {
                            anchors.fill: parent
                            enabled: powerOpen
                            onClicked: powerOpen = false
                        }

            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on radius {
                NumberAnimation {
                    duration: 160
                }
            }

            Text {
                id: powerIcon
                anchors.fill: parent
                text: "\uf011"
                font.family: "Maple Mono NF"
                font.pixelSize: 12
                color: powerHover.containsMouse ? Colors.accent2 : Colors.accent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                rightPadding: 4
                visible: !powerOpen
            }

            MouseArea {
                id: powerHover
                anchors.fill: parent
                hoverEnabled: true
                enabled: !powerOpen
                onClicked: {
                    island.expanded = false
                    trayOpen = false
                    powerOpen = true
                }
            }

            Column {
                id: powerCol
                x: 6
                y: 6
                width: parent.width - 12
                spacing: 2
                visible: powerOpen
                opacity: powerOpen ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 140
                    }
                }

                Repeater {
                    model: [
                        { icon: "\uf023", label: "Lock", cmd: ["hyprlock", "--grace", "0"] },
                        { icon: "\uf2f5", label: "Logout", cmd: ["niri", "msg", "action", "quit", "--skip-confirmation"] },
                        { icon: "\uf186", label: "Suspend", cmd: ["systemctl", "suspend"] },
                        { icon: "\uf021", label: "Reboot", cmd: ["systemctl", "reboot"] },
                        { icon: "\uf011", label: "Shutdown", cmd: ["systemctl", "poweroff"] }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 26
                        radius: 7
                        color: pRowHover.containsMouse ? Colors.alpha(Colors.fg, "12") : "transparent"

                        Text {
                            id: pIcon
                            x: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.icon
                            font.family: "Maple Mono NF"
                            font.pixelSize: 11
                            color: Colors.accent
                        }

                        Text {
                            anchors.left: pIcon.right
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            font.pixelSize: 11
                            color: pRowHover.containsMouse ? Colors.fg : Colors.muted
                        }

                        MouseArea {
                            id: pRowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                powerOpen = false
                                shell.runPower(modelData.cmd)
                            }
                        }
                    }
                }
            }
        }
    }
    }

    Variants {
        model: sideScreens

        PanelWindow {
            id: wsFlash
            required property var modelData
            screen: modelData
            anchors {
                top: true
                left: true
            }
            implicitWidth: 200
            implicitHeight: 30
            exclusiveZone: -1
            color: "transparent"
            mask: Region {
                item: flashHit
            }

            property bool flash: false

            Item {
                id: flashHit
                x: 8
                y: 2
                width: flash ? flashPill.width : 0
                height: flash ? 26 : 0
            }
            readonly property real changedAt: {
                const st = wsByOutput[wsFlash.modelData.name]
                return st ? st.changedAt : 0
            }

            onChangedAtChanged: {
                flash = true
                hideTimer.restart()
            }

            Timer {
                id: hideTimer
                interval: 1600
                onTriggered: wsFlash.flash = false
            }

            Rectangle {
                id: flashPill
                x: 8
                y: 2
                width: Math.min(flashRow.width + 20, 184)
                height: 26
                radius: 13
                color: Colors.bg
                border.width: 1
                border.color: Colors.alpha(Colors.accent, "3d")
                opacity: flash ? 1 : 0
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation {
                        duration: 120
                    }
                }

                Row {
                    id: flashRow
                    x: 10
                    height: parent.height
                    spacing: 7

                    Repeater {
                        model: {
                            const st = wsByOutput[wsFlash.modelData.name]
                            return st ? st.list : []
                        }

                        delegate: Rectangle {
                            required property var modelData
                            width: 10
                            height: 10
                            radius: 5
                            anchors.verticalCenter: parent.verticalCenter
                            color: modelData.active ? Colors.accent : "transparent"
                            border.width: 1
                            border.color: modelData.active ? Colors.accent : Colors.alpha(Colors.muted, "99")
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-4")

        PanelWindow {
            id: osdWin
            required property var modelData
            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusiveZone: -1
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            mask: Region {
                item: shell.osdVisible ? osdPill : osdHidden
            }

            Item {
                id: osdHidden
                width: 0
                height: 0
            }

            Rectangle {
                id: osdPill
                anchors.centerIn: parent
                width: 232
                height: 62
                radius: 20
                color: Colors.bg
                border.width: 1
                border.color: Colors.alpha(Colors.accent, "3d")
                opacity: shell.osdVisible ? 1 : 0
                scale: shell.osdVisible ? 1 : 0.94
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 170
                        easing.type: Easing.OutCubic
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: shell.osdMuted ? "\uf026" : (shell.osdValue > 0.5 ? "\uf028" : "\uf027")
                        font.family: "Maple Mono NF"
                        font.pixelSize: 20
                        color: shell.osdMuted ? Colors.muted : Colors.accent
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7

                        Rectangle {
                            width: 140
                            height: 6
                            radius: 3
                            color: Colors.alpha(Colors.muted, "40")

                            Rectangle {
                                width: Math.round(parent.width * (shell.osdMuted ? 0 : shell.osdValue))
                                height: parent.height
                                radius: 3
                                color: shell.osdMuted ? Colors.muted : Colors.accent

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 120
                                    }
                                }
                            }
                        }

                        Text {
                            text: shell.osdMuted ? "Muted" : Math.round(shell.osdValue * 100) + "%"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: shell.osdMuted ? Colors.muted : Colors.fg
                        }
                    }
                }
            }
        }
    }
}
