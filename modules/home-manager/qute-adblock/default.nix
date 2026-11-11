{
  config,
  pkgs,
  lib,
  ...
}:
# qute-adblock — declarative qutebrowser adblocking, three layers:
#   1. native network blocking (content.blocking, brave adblock engine)
#   2. the compiled engine (./bundle.nix): generic + domain cosmetic CSS,
#      procedural filters, uBO-style scriptlets, dead-slot collapsing —
#      installed as greasemonkey script AND injected as a world-0 user script
#      from extraConfig (greasemonkey runs isolated from the page, so the
#      scriptlet layer needs the python injection below)
#   3. python fallback: QtWebEngine drops user-script injection on some
#      cross-site redirect chains (www.espn.com -> www.espn.com.ar); the
#      injector polls tabs and evals the engine when its marker is missing.
# updates: ./update-qute-lists.sh (bumps the pins, commit the diff)
let
  adblockBundle = import ./bundle.nix { inherit pkgs lib; };
  engine = "${adblockBundle}/share/qutebrowser/greasemonkey/qute-adblock.user.js";
in
{
  programs.qutebrowser.settings = {
    content.blocking.method = lib.mkDefault "both";
    content.blocking.adblock.lists = lib.mkDefault [
      "https://easylist.to/easylist/easylist.txt"
      "https://easylist.to/easylist/easyprivacy.txt"
      "https://secure.fanboy.co.nz/fanboy-annoyance.txt"
      "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt"
      "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt"
      "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt"
      "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt"
      "https://github.com/uBlockOrigin/uAssets/raw/master/filters/quick-fixes.txt"
      "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=0&mimetype=plaintext"
      "https://raw.githubusercontent.com/easylist/easylist/master/easylist_adult/adult_adservers.txt"
      "https://raw.githubusercontent.com/easylist/easylist/master/easylist_adult/adult_thirdparty.txt"
      "https://raw.githubusercontent.com/easylist/easylist/master/easylist_adult/adult_adservers_popup.txt"
      "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters-2024.txt"
      "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters-2025.txt"
      "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters-2026.txt"
      "https://raw.githubusercontent.com/gioxx/xfiles/master/filtri.txt"
      "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/AnnoyancesList"
      "https://filters.adtidy.org/windows/filters/2.txt"
    ];
    content.javascript.can_open_tabs_automatically = lib.mkDefault false;
  };

  xdg.configFile."qutebrowser/greasemonkey/qute-adblock.user.js".source = engine;

  programs.qutebrowser.extraConfig = ''
    # --- qute-adblock engine injection (see ./default.nix) -------------------
    import json as _adb_json

    from qutebrowser.utils import objreg, usertypes, log

    _adb_engine_path = "${engine}"
    from qutebrowser.utils import objreg, usertypes, log

    _adb_engine_path = "/tmp/qb-adb/config/greasemonkey/qute-adblock.user.js"
    _adb_source = None
    _adb_timer = None
    _adb_injected = set()
    _adb_probe = (
        "(function(){var d=document.documentElement;"
        "return !!(d && d.hasAttribute('data-qadb'))})()"
    )


    def _adb_engine():
        global _adb_source
        if _adb_source is None:
            try:
                with open(_adb_engine_path, encoding="utf-8") as f:
                    _adb_source = f.read()
            except OSError:
                _adb_source = ""
        return _adb_source


    def _adb_check_tab(tab):
        if len(_adb_injected) > 512:
            _adb_injected.clear()
        try:
            if tab.url().scheme() not in ("http", "https"):
                return
            if tab.load_status() not in (
                    usertypes.LoadStatus.success, usertypes.LoadStatus.success_https):
                return
            if (tab.tab_id, tab.url().toDisplayString()) in _adb_injected:
                return
        except Exception:
            return
        src = _adb_engine()
        if not src:
            return

        # marker check + eval in one shot: no callback round-trip needed
        wrapped = (
            "(function(){var d=document.documentElement;"
            "if (d && d.hasAttribute('data-qadb')) return;"
            "try{eval(" + _json.dumps(src) + ")}catch(e){}})()"
        )
        try:
            log.misc.debug("qadb: fallback injection on %s" % tab.url().toDisplayString())
            _adb_injected.add((tab.tab_id, tab.url().toDisplayString()))
            tab.run_js_async(wrapped, world=usertypes.JsWorld.main)
        except Exception:
            pass


    def _adb_sweep():
        try:
            for win_id in list(objreg.window_registry):
                try:
                    tb = objreg.get("tabbed-browser", scope="window", window=win_id)
                except Exception:
                    continue
                for tab in tb.widgets():
                    _adb_check_tab(tab)
        except Exception:
            pass


    def _adb_page_script(tab):
        # register the engine as a user script in the REAL main world (worldId 0):
        # qutebrowser's greasemonkey path runs isolated from the page, so its
        # scriptlets can never patch page javascript. injected at DocumentCreation
        # -> runs before any page script, on every navigation.
        try:
            if getattr(tab, "_qadb_script", False):
                return
            tab._qadb_script = True
            src = _adb_engine()
            if not src:
                return
            from qutebrowser.qt.webenginecore import QWebEngineScript
            script = QWebEngineScript()
            script.setName("qadb-main")
            script.setWorldId(0)
            script.setInjectionPoint(QWebEngineScript.InjectionPoint.DocumentCreation)
            script.setRunsOnSubFrames(False)
            script.setSourceCode(src)
            page = tab._widget.page()
            page.scripts().insert(script)
            # popup guard for SUBFRAMES (video embeds run their own popunders):
            # the main engine stays top-frame only, this 20-liner runs in every
            # frame — a frame never legitimately opens a cross-origin window
            guard = QWebEngineScript()
            guard.setName("qadb-frameguard")
            guard.setWorldId(0)
            guard.setInjectionPoint(QWebEngineScript.InjectionPoint.DocumentCreation)
            guard.setRunsOnSubFrames(True)
            guard.setSourceCode(
                '(function(){"use strict";'
                'if(window.__qadbFrame)return;window.__qadbFrame=1;'
                'var orig=window.open;'
                'window.open=function(u){'
                'var s=String(u===undefined?"":u);'
                'if(!s||/^about:blank/i.test(s)||/^(blob|data):/i.test(s))return null;'
                'try{var a=new URL(s,location.href);'
                'if(a.host!==location.host)return null;'
                '}catch(e){}'
                'return orig.apply(window,arguments);};'
                '})();'
            )
            page.scripts().insert(guard)
            log.misc.debug("qadb: main-world script attached to tab %s" % tab.tab_id)
        except Exception as e:
            log.misc.error("qadb: script attach failed: %s" % e)



    def _adb_collapse_blocked(info):
        # --- uBO mechanism port: collapse blocked subframes ---------------------
        # uBO collapses the element whose request got blocked; qute's engine only
        # kills the request, leaving the dead frame. this hook fires after the
        # brave engine decided (registered later -> sees is_blocked), finds the
        # first-party tab and hides the matching iframe.
        try:
            if not info.is_blocked:
                return
            if info.resource_type not in (
                    interceptor.ResourceType.sub_frame,
                    interceptor.ResourceType.object):
                return
            fp = info.first_party_url
            if fp is None or fp.scheme() not in ("http", "https"):
                return
            key = info.request_url.host() + info.request_url.path()
            if len(key) < 8:
                return
            js = (
                "(function(){var k=" + _adb_json.dumps(key) + ";"
                "document.querySelectorAll('iframe[src*=\"'+k+'\"]').forEach(function(f){"
                "f.style.setProperty('display','none','important');});"
                "})()"
            )
            for _win in list(objreg.window_registry):
                try:
                    _tb = objreg.get("tabbed-browser", scope="window", window=_win)
                except Exception:
                    continue
                for _tab in _tb.widgets():
                    try:
                        if _tab.url().host() == fp.host():
                            _tab.run_js_async(js, world=usertypes.JsWorld.main)
                            return
                    except Exception:
                        continue
        except Exception:
            pass


    def _adb_start_timer():
        global _adb_timer
        if _adb_timer is not None:
            return
        try:
            interceptor.register(_adb_collapse_blocked)  # after brave engine -> sees is_blocked
        except Exception as e:
            log.misc.error("qadb: collapse interceptor failed: %s" % e)
        from qutebrowser.qt.core import QTimer
        _adb_timer = QTimer()
        _adb_timer.setInterval(2000)
        _adb_timer.timeout.connect(_adb_sweep)
        _adb_timer.start()
        for win_id in list(objreg.window_registry):
            try:
                tb = objreg.get("tabbed-browser", scope="window", window=win_id)
            except Exception:
                continue
            for tab in tb.widgets():
                _adb_page_script(tab)


    def _adb_first_request(_info):
        # config.py runs before QApplication exists, so the QTimer can only be
        # created once the browser is actually doing something.
        _adb_start_timer()


    try:
        from qutebrowser.api import interceptor
        interceptor.register(_adb_first_request)
        log.misc.debug("qadb: interceptor registered")

    except Exception as e:
        log.misc.error("qadb: interceptor registration failed: %s" % e)



  '';
}
