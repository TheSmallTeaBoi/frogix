import QtQuick
import Quickshell
import "."

/* Month calendar flyout, opened from the island clock (see shell.qml).
   Self-contained: it follows today until the user pages away, and shares
   the pywal palette through the Colors singleton. */
Rectangle {
    id: root

    implicitWidth: 280
    implicitHeight: 264
    radius: 18
    color: Colors.bg
    border.width: 1
    border.color: Colors.alpha(Colors.accent, "3d")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property int cellW: 36
    readonly property int cellH: 30

    property int viewYear: clock.date.getFullYear()
    property int viewMonth: clock.date.getMonth()

    readonly property var days: {
        const y = viewYear
        const m = viewMonth
        const first = (new Date(y, m, 1).getDay() + 6) % 7
        const today = clock.date
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(y, m, i - first + 1)
            out.push({
                label: d.getDate(),
                inMonth: d.getMonth() === m,
                isToday: d.toDateString() === today.toDateString(),
                weekend: d.getDay() === 0 || d.getDay() === 6
            })
        }
        return out
    }

    function shift(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1)
        viewYear = d.getFullYear()
        viewMonth = d.getMonth()
    }

    function goToday() {
        viewYear = clock.date.getFullYear()
        viewMonth = clock.date.getMonth()
    }

    Item {
        id: header
        x: 12
        y: 10
        width: parent.width - 24
        height: 26

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
            color: Colors.fg
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: [
                    {
                        glyph: "\uf060",
                        action: "prev"
                    },
                    {
                        glyph: "\uf2bb",
                        action: "today"
                    },
                    {
                        glyph: "\uf061",
                        action: "next"
                    }
                ]

                delegate: Rectangle {
                    required property var modelData
                    width: 24
                    height: 24
                    radius: 7
                    color: navHover.containsMouse ? Colors.alpha(Colors.fg, "12") : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.glyph
                        font.family: "Maple Mono NF"
                        font.pixelSize: 11
                        color: navHover.containsMouse ? Colors.accent : Colors.muted
                    }

                    MouseArea {
                        id: navHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (modelData.action === "prev")
                                root.shift(-1)
                            else if (modelData.action === "next")
                                root.shift(1)
                            else
                                root.goToday()
                        }
                    }
                }
            }
        }
    }

    Row {
        id: weekRow
        x: (root.width - width) / 2
        y: header.y + header.height + 6
        spacing: 0

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

            delegate: Text {
                required property var modelData
                width: root.cellW
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Colors.muted
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }
    }

    Grid {
        id: grid
        x: (root.width - width) / 2
        y: weekRow.y + weekRow.height + 4
        columns: 7
        spacing: 0

        Repeater {
            model: root.days

            delegate: Item {
                required property var modelData
                width: root.cellW
                height: root.cellH

                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: 9
                    color: modelData.isToday ? Colors.accent : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: 11
                        color: modelData.isToday ? Colors.bg : (modelData.inMonth ? (modelData.weekend ? Colors.muted : Colors.fg) : Colors.alpha(Colors.muted, "66"))
                    }
                }
            }
        }
    }
}
