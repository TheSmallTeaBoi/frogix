pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var sinks: []
    property var sources: []
    property string defaultSink: ""
    property string defaultSource: ""
    property real sinkVol: 0
    property bool sinkMuted: false
    property real sourceVol: 0
    property bool sourceMuted: false

    Process {
        id: sub
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                if (line.indexOf("sink") < 0 && line.indexOf("source") < 0)
                    return
                if (line.indexOf("'change'") >= 0) {
                    if (line.indexOf("sink") >= 0)
                        sinkVolProc.running = true
                    else
                        sourceVolProc.running = true
                } else {
                    statusProc.running = true
                    sinkVolProc.running = true
                    sourceVolProc.running = true
                }
            }
        }
        onExited: subRestart.restart()
    }

    Timer {
        id: subRestart
        interval: 1000
        onTriggered: sub.running = true
    }

    function refresh() {
        statusProc.running = true
        sinkVolProc.running = true
        sourceVolProc.running = true
    }

    function apply(args) {
        cmd.running = false
        cmd.command = ["wpctl", ...args]
        cmd.running = true
    }

    function setSinkVolume(v) {
        const clamped = Math.max(0, Math.min(1, v))
        root.sinkVol = clamped
        volCommit.value = clamped
        volCommit.restart()
    }

    function setSourceVolume(v) {
        const clamped = Math.max(0, Math.min(1, v))
        root.sourceVol = clamped
        srcVolCommit.value = clamped
        srcVolCommit.restart()
    }

    function toggleSinkMute() {
        root.sinkMuted = !root.sinkMuted
        apply(["set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    }

    function toggleSourceMute() {
        root.sourceMuted = !root.sourceMuted
        apply(["set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
    }

    function setDefault(id) {
        apply(["set-default", id])
    }

    Timer {
        id: volCommit
        interval: 120
        property real value: 0
        onTriggered: root.apply(["set-volume", "@DEFAULT_AUDIO_SINK@", `${Math.round(value * 100)}%`])
    }

    Timer {
        id: srcVolCommit
        interval: 120
        property real value: 0
        onTriggered: root.apply(["set-volume", "@DEFAULT_AUDIO_SOURCE@", `${Math.round(value * 100)}%`])
    }

    Process {
        id: statusProc
        command: ["wpctl", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n")
                const sinks = []
                const sources = []
                let section = ""
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i]
                    if (line.includes("Sinks:")) {
                        section = "sink"
                        continue
                    }
                    if (line.includes("Sources:")) {
                        section = "source"
                        continue
                    }
                    if (line.includes("Video") || line.includes("Stream Outputs") || line.includes("Stream Inputs") || line.includes("Settings")) {
                        section = ""
                        continue
                    }
                    const m = line.match(/(\*?)\s*(\d+)\.\s+(.+?)\s+\[vol:\s*([\d.]+)\]/)
                    if (!m)
                        continue
                    const isDefault = m[1] === "*"
                    const entry = {
                        id: m[2],
                        name: m[3],
                        vol: parseFloat(m[4]),
                        def: isDefault
                    }
                    if (section === "sink") {
                        sinks.push(entry)
                        if (isDefault)
                            root.defaultSink = m[2]
                    } else if (section === "source") {
                        sources.push(entry)
                        if (isDefault)
                            root.defaultSource = m[2]
                    }
                }
                root.sinks = sinks
                root.sources = sources
            }
        }
    }

    Process {
        id: sinkVolProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/Volume:\s*([\d.]+)(\s*\[MUTED\])?/)
                if (m) {
                    root.sinkVol = parseFloat(m[1])
                    root.sinkMuted = Boolean(m[2])
                }
            }
        }
    }

    Process {
        id: sourceVolProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/Volume:\s*([\d.]+)(\s*\[MUTED\])?/)
                if (m) {
                    root.sourceVol = parseFloat(m[1])
                    root.sourceMuted = Boolean(m[2])
                }
            }
        }
    }

    Process {
        id: cmd
        onExited: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
