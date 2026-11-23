"""Live light/dark for websites, without restarting qutebrowser.

qutebrowser hands `colors.webpage.preferred_color_scheme` to QtWebEngine as a
`--blink-settings=preferredColorScheme=` flag at process start (configdata.yml
marks it `restart: true`), so there is no runtime setter. The devtools protocol
does expose it though: `Emulation.setEmulatedMedia` flips the media feature on a
live page and Blink re-evaluates CSS immediately.

qute must be started with QTWEBENGINE_REMOTE_DEBUGGING=<port> (niri spawn line
does this). This module then holds one websocket to the browser target, attaches
to every page target, and (re)applies the emulation from ~/.config/rice/mode.

Import-cached: `:config-source` re-runs config.py but not this module, so
config.py must call apply() explicitly after import.
"""

import json
import os

from PyQt6.QtCore import QObject, QTimer, QUrl
from PyQt6.QtNetwork import QNetworkAccessManager, QNetworkReply, QNetworkRequest
from PyQt6.QtWebSockets import QWebSocket

from qutebrowser.utils import log

def _port():
    # same env qtwebengine itself uses; "host:port" is allowed there too.
    # return None when neither env var is set so a non-CDP launch (e.g. Mod+B)
    # does not probe port 9222 forever or attach to an unrelated browser/Electron.
    raw = os.environ.get("RICE_CDP_PORT") or os.environ.get("QTWEBENGINE_REMOTE_DEBUGGING")
    if not raw:
        return None
    try:
        return int(raw.rsplit(":", 1)[-1])
    except ValueError:
        return None


PORT = _port()
MODE_FILE = os.path.expanduser("~/.config/rice/mode")

_client = None
_starting = False

_DEBUG = bool(os.environ.get("RICE_CDP_DEBUG"))
_DEBUG_DIR = os.environ.get("XDG_RUNTIME_DIR") or os.path.expanduser("~/.cache")
_DEBUG_LOG = os.path.join(_DEBUG_DIR, "ricecdp-debug.log")


def _dbg(msg):
    if _DEBUG:
        try:
            with open(_DEBUG_LOG, "a") as f:
                f.write(str(msg) + "\n")
        except OSError:
            pass


def current_mode():
    try:
        with open(MODE_FILE) as f:
            return "light" if f.read().strip() == "light" else "dark"
    except OSError:
        return "dark"


class Client(QObject):

    def __init__(self, port=PORT, parent=None):
        super().__init__(parent)
        self._port = port
        self._next_id = 0
        self._attach_ids = set()
        self._sessions = set()
        self._ws = QWebSocket()
        self._ws.connected.connect(self._on_connected)
        self._ws.disconnected.connect(self._on_disconnected)
        self._ws.textMessageReceived.connect(self._on_message)
        self._nam = QNetworkAccessManager(self)
        self._nam.finished.connect(self._on_version)
        self._retry = QTimer(self)
        self._retry.setSingleShot(True)
        self._retry.timeout.connect(self._probe)
        _dbg("client init, probing port %s" % self._port)
        self._probe()

    # connection -----------------------------------------------------
    def _probe(self):
        self._nam.get(QNetworkRequest(
            QUrl("http://127.0.0.1:%d/json/version" % self._port)))

    def _on_version(self, reply):
        ok = reply.error() == QNetworkReply.NetworkError.NoError
        _dbg("probe reply ok=%s err=%s" % (ok, reply.error()))
        body = bytes(reply.readAll())
        reply.deleteLater()
        if not ok:
            self._retry.start(5000)
            return
        try:
            url = json.loads(body.decode("utf-8"))["webSocketDebuggerUrl"]
        except (ValueError, KeyError):
            self._retry.start(5000)
            return
        _dbg("opening ws %s" % url)
        self._ws.open(QUrl(url))

    def _on_connected(self):
        _dbg("ws connected")
        self._send("Target.setDiscoverTargets", {"discover": True})
        self.apply()

    def _on_disconnected(self):
        self._sessions.clear()
        self._attach_ids.clear()
        self._retry.start(2000)

    # protocol -------------------------------------------------------
    def _send(self, method, params=None, session=None):
        self._next_id += 1
        msg = {"id": self._next_id, "method": method}
        if params is not None:
            msg["params"] = params
        if session is not None:
            msg["sessionId"] = session
        try:
            self._ws.sendTextMessage(json.dumps(msg))
        except Exception:
            pass
        return self._next_id

    def _on_message(self, text):
        try:
            msg = json.loads(text)
        except ValueError:
            return
        if "method" in msg or "id" in msg:
            _dbg("recv %s" % (msg.get("method") or ("reply %s" % msg.get("id"))))
        if msg.get("method") == "Target.targetCreated":
            info = msg.get("params", {}).get("targetInfo", {})
            if info.get("type") == "page":
                self._attach_ids.add(self._send(
                    "Target.attachToTarget",
                    {"targetId": info["targetId"], "flatten": True}))
        elif msg.get("method") == "Target.detachedFromTarget":
            sid = msg.get("params", {}).get("sessionId")
            self._sessions.discard(sid)
        elif "id" in msg and msg["id"] in self._attach_ids:
            self._attach_ids.discard(msg["id"])
            sid = msg.get("result", {}).get("sessionId")
            _dbg("attach reply sid=%s err=%s" % (sid, msg.get("error")))
            if sid:
                self._sessions.add(sid)
                self._emulate(sid)

    def _emulate(self, session):
        _dbg("emulate %s on %s" % (current_mode(), session))
        self._send("Emulation.setEmulatedMedia", {
            "media": "",
            "features": [{"name": "prefers-color-scheme",
                          "value": current_mode()}],
        }, session=session)

    # entry point ----------------------------------------------------
    def apply(self):
        for session in list(self._sessions):
            self._emulate(session)


def apply():
    """Connect on first call, then re-apply the current mode to every page.

    config.py is read before QCoreApplication exists, so the Qt objects cannot
    be built right here ("QEventLoop: Cannot be used without QCoreApplication").
    A zero-timer runs as soon as the event loop is up, which is the earliest
    safe point; apply() from later :config-source reloads hits the live client.
    """
    global _client, _starting
    if PORT is None:
        return
    if _client is not None:
        _client.apply()
    elif not _starting:
        _starting = True
        QTimer.singleShot(0, _start)


def _start():
    global _client, _starting
    _starting = False
    if _client is None:
        try:
            _client = Client()
        except Exception:
            log.exception("ricecdp: could not start")