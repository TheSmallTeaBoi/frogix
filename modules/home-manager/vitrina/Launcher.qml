import QtQuick
import Quickshell
import Quickshell.Widgets
import "."

/* The launcher panel UI. Hosted by a short-lived full-screen overlay
   PanelWindow created fresh on every open (see shell.qml) so niri grants
   keyboard focus. State and models are owned by shell.qml so the IPC
   handler and the UI stay in sync. */
Item {
    id: root

    required property var host

    readonly property var modeInfo: host.launcherModeInfo

    Component.onCompleted: {
        /* the host window is only created while the launcher is open, so
           onLauncherOpenChanged never fires for this instance */
        root.syncInput()
        root.focusInput()
    }

    function focusInput() {
        Qt.callLater(function () {
            input.forceActiveFocus()
        })
    }

    function syncInput() {
        if (input.text !== host.launcherQuery)
            input.text = host.launcherQuery
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.host.launcherOpen
        onActivated: root.host.closeLauncher()
    }

    Shortcut {
        sequence: "Tab"
        enabled: root.host.launcherOpen
        onActivated: root.host.cycleLauncherMode(1)
    }

    Shortcut {
        sequence: "Shift+Tab"
        enabled: root.host.launcherOpen
        onActivated: root.host.cycleLauncherMode(-1)
    }

    Shortcut {
        sequence: "Down"
        enabled: root.host.launcherOpen
        onActivated: root.host.launcherMove(1)
    }

    Shortcut {
        sequence: "Up"
        enabled: root.host.launcherOpen
        onActivated: root.host.launcherMove(-1)
    }

    Connections {
        target: root.host

        function onLauncherOpenChanged() {
            if (root.host.launcherOpen) {
                root.syncInput()
                root.focusInput()
            }
        }

        function onLauncherModeChanged() {
            root.syncInput()
            root.focusInput()
        }

        function onLauncherQueryChanged() {
            root.syncInput()
        }

        function onLauncherIndexChanged() {
            resultList.positionViewAtIndex(root.host.launcherIndex, ListView.Contain)
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Rectangle {
            id: searchBox
            width: parent.width
            height: 44
            radius: 12
            color: Colors.alpha(Colors.fg, "0a")
            border.width: 1
            border.color: Colors.alpha(Colors.fg, "14")

            Text {
                id: searchIcon
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                text: root.modeInfo.icon
                font.family: "Maple Mono NF"
                font.pixelSize: 15
                color: Colors.accent
            }

            Text {
                anchors.left: input.left
                anchors.verticalCenter: input.verticalCenter
                visible: input.text.length === 0
                text: root.modeInfo.placeholder
                font.pixelSize: 13
                color: Colors.muted
            }

            TextInput {
                id: input
                anchors.left: searchIcon.right
                anchors.leftMargin: 10
                anchors.right: hint.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                verticalAlignment: TextInput.AlignVCenter
                font.pixelSize: 13
                color: Colors.fg
                selectionColor: Colors.accent
                selectedTextColor: Colors.bg
                selectByMouse: true
                clip: true

                onTextChanged: root.host.setLauncherQuery(text)

                onAccepted: root.host.launcherActivate(root.host.launcherIndex)
            }

            Text {
                id: hint
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "↑↓  ↵  esc"
                font.pixelSize: 10
                color: Colors.muted
            }
        }

        Row {
            id: tabRow
            spacing: 6

            Repeater {
                model: root.host.launcherModes

                delegate: Rectangle {
                    required property var modelData
                    width: tabLabel.implicitWidth + 22
                    height: 24
                    radius: 8
                    color: root.host.launcherMode === modelData.id ? Colors.alpha(Colors.accent, "2e") : Colors.alpha(Colors.fg, "08")
                    border.width: 1
                    border.color: root.host.launcherMode === modelData.id ? Colors.alpha(Colors.accent, "3d") : "transparent"

                    Text {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: modelData.icon + "  " + modelData.label
                        font.family: "Maple Mono NF"
                        font.pixelSize: 10
                        color: root.host.launcherMode === modelData.id ? Colors.fg : Colors.muted
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.host.setLauncherMode(modelData.id)
                            root.focusInput()
                        }
                    }
                }
            }
        }

        Item {
            id: results
            width: parent.width
            height: parent.height - searchBox.height - tabRow.height - 20

            ListView {
                id: resultList
                anchors.fill: parent
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: root.host.launcherItems
                currentIndex: root.host.launcherIndex

                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index

                    width: resultList.width
                    height: 38
                    radius: 8
                    color: index === root.host.launcherIndex ? Colors.alpha(Colors.accent, "2e") : (rowHover.containsMouse ? Colors.alpha(Colors.fg, "0a") : "transparent")

                    Row {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 20
                        spacing: 10

                        Item {
                            width: 20
                            height: 20
                            anchors.verticalCenter: parent.verticalCenter

                            IconImage {
                                anchors.fill: parent
                                visible: modelData.kind !== "emoji" && (modelData.icon || "").length > 0
                                source: modelData.icon || ""
                                implicitSize: 18
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: modelData.kind === "emoji"
                                text: modelData.char || ""
                                font.family: "Noto Color Emoji"
                                font.pixelSize: 18
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: modelData.kind !== "emoji" && (modelData.icon || "").length === 0
                                text: root.modeInfo.icon
                                font.family: "Maple Mono NF"
                                font.pixelSize: 14
                                color: Colors.accent
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 30
                            spacing: 1

                            Text {
                                width: parent.width
                                text: modelData.title
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: Colors.fg
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                visible: text.length > 0
                                text: modelData.subtitle
                                font.pixelSize: 10
                                color: Colors.muted
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.host.launcherIndex = index
                        onClicked: {
                            root.host.launcherIndex = index
                            root.host.launcherActivate(index)
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 8
                visible: root.host.launcherItems.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.modeInfo.icon
                    font.family: "Maple Mono NF"
                    font.pixelSize: 28
                    color: Colors.alpha(Colors.accent, "aa")
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.host.launcherHint
                    font.pixelSize: 11
                    color: Colors.muted
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
