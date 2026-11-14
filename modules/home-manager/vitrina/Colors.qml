pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string path: `${Quickshell.env("HOME")}/.cache/wal/colors.json`

    property string bg: "#10131a"
    property string fg: "#c6cad2"
    property string accent: "#7aa2f7"
    property string accent2: "#9ece6a"
    property string muted: "#565f89"

    function alpha(hex, a) {
        return `#${a}${hex.slice(1)}`
    }

    FileView {
        path: root.path
        watchChanges: true
        blockLoading: true
        onFileChanged: this.reload()
        onLoaded: {
            const c = JSON.parse(this.text())
            root.bg = c.special.background
            root.fg = c.special.foreground
            root.accent = c.colors.color1
            root.accent2 = c.colors.color2
            root.muted = c.colors.color8
        }
    }
}
