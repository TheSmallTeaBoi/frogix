// ==UserScript==
// @name         qute general goop remover
// @namespace    chai.qute.goop
// @version      0.6.0
// @description  general overlay + dead-ad-slot + click-hijack killer for qutebrowser (no ubo cosmetic, so we do it dumb)
// @match        *://*/*
// @run-at       document-start
// @noframes
// @grant        none
// ==/UserScript==
(function () {
  'use strict';
//__SITE_DATA__
  var ALLOW_SAME_ORIGIN_POPUP = true;
  var ADHOSTS = ['zeebestmarketing', 'partylemons', 'tsyndicate', 'dreamserve',
    'exoclick', 'juicyads', 'adsterra', 'popads', 'popcash', 'doubleclick',
    'adservice', 'adsystem', 'outbrain', 'taboola', 'mgid'];
  function isAdUrl(u) {
    try {
      var s = String(u || '').toLowerCase();
      for (var i = 0; i < ADHOSTS.length; i++) if (s.indexOf(ADHOSTS[i]) !== -1) return true;
    } catch (e) {}
    return false;
  }

  // 1. bait the cheap adblock detectors
  try {
    window.canRunAds = true;
    window.canRunAdvertise = true;
    window.google_ad_status = 1;
  } catch (e) {}

  // 2. neuter window.open popunders: allow same-host, block 3rd-party + known adhosts
  var origOpen = window.open.bind(window);
  window.open = function (url) {
    try {
      if (!url || url === 'about:blank') return null;
      if (isAdUrl(url)) return null;
      var u = new URL(url, location.href);
      if (ALLOW_SAME_ORIGIN_POPUP && u.hostname === location.hostname) {
        return origOpen.apply(window, arguments);
      }
      return null;
    } catch (e) { return null; }
  };

  // 3. css: hide dead ad slots instantly (before js even runs)
  var CSS = [
    '.adsbygoogle', '[id^="div-gpt-ad"]', '[id*="ad-slot"]', '[class*="ad-slot"]',
    '[id*="sponsored"]', '[class*="sponsored"]', '[data-ad]', '[data-ad-slot]',
    'iframe[src*="doubleclick"]', 'iframe[src*="adservice"]', 'iframe[src*="adsystem"]',
    '.ad-container:empty', '.ad-wrapper:empty', '[class*="cookie-banner"]'
  ].join(',') + '{display:none !important;}';
  function injectCSS() {
    try {
      var s = document.createElement('style');
      s.setAttribute('data-qute-goop', '1');
      s.textContent = CSS;
      (document.head || document.documentElement).appendChild(s);
    } catch (e) {}
  }

  // 4. overlay killer: full-viewport fixed divs that aren't nav/video
  function isBigFixed(el) {
    try {
      var s = getComputedStyle(el);
      if (s.position !== 'fixed' && s.position !== 'sticky') return false;
      var z = parseInt(s.zIndex || '0', 10);
      if (z < 500) return false;
      var r = el.getBoundingClientRect();
      var vw = window.innerWidth, vh = window.innerHeight;
      if (r.width < vw * 0.6 || r.height < vh * 0.4) return false;
      var tag = (el.tagName || '').toLowerCase();
      if (tag === 'header' || tag === 'nav' || tag === 'video' || el.querySelector('video')) return false;
      return true;
    } catch (e) { return false; }
  }
  function killOverlays() {
    var killed = 0;
    try {
      document.querySelectorAll('div,section,aside').forEach(function (el) {
        if (el.hasAttribute('data-qute-goop')) return;
        var idc = (el.id + ' ' + el.className).toLowerCase();
        var suspect = /overlay|paywall|adblock|interstitial|modal-backdrop|lightbox/.test(idc);
        if (suspect || isBigFixed(el)) { el.remove(); killed++; }
      });
      // restore scroll locked by removed walls
      if (killed > 0) {
        document.body.style.overflow = 'auto';
        document.documentElement.style.overflow = 'auto';
      }
    } catch (e) {}
    return killed;
  }

  // 5. click-hijack guard for wordpress popunder sites (asmrfree pattern:
  // nav decoys to zeebestmarketing/partylemons/tsyndicate + dreamserve iframe
  // + document-level first-click handler). two layers:
  // a) kill ad-target links outright, b) swallow empty-space clicks in
  // capture phase so the site's bubble-phase popunder never fires.
  function pruneAdLinks() {
    try {
      document.querySelectorAll('a[href]').forEach(function (a) {
        var h = a.getAttribute('href') || '';
        if (isAdUrl(h)) a.remove();
      });
    } catch (e) {}
  }
  // click-swallow is opt-IN per dirty host, not opt-out. default-safe:
  // unknown sites never break. upstream lists + window.open neutering
  // already kill known-ad-domain popups; the guard covers same-tab
  // location hijacks via document-level handlers on popunder-class sites.
  // 2026-09-17: asmrfree needs it — first click on a *video link* still
  // hijacked the current tab with the guard on, because link clicks passed
  // through to document handlers. so on dirty hosts we now also starve
  // document handlers for clean link clicks (default nav still happens).
  var DIRTY_HOSTS = ['asmrfree.com'];
  function clickGuardOn() {
    try {
      var h = location.hostname.toLowerCase();
      for (var i = 0; i < DIRTY_HOSTS.length; i++) {
        if (h === DIRTY_HOSTS[i] || h.endsWith('.' + DIRTY_HOSTS[i])) return true;
      }
    } catch (e) {}
    return false;
  }
  // native controls + ARIA widgets + youtube-style custom-element buttons.
  // (yt "read more" is a tp-yt-paper-button / span[role], not a <button>.)
  var INTERACTIVE = 'a,button,input,select,textarea,video,audio,summary,details,label,' +
    '[role="button"],[role="link"],[role="tab"],[role="menuitem"],' +
    '[role="option"],[role="switch"],[role="checkbox"],[role="radio"],' +
    '[contenteditable="true"],[tabindex]';
  window.addEventListener('click', function (e) {
    try {
      var t = e.target;
      var link = t.closest ? t.closest(INTERACTIVE) : null;
      if (link) {
        // real content link: only block if it points at known adhosts
        var href = link.getAttribute ? (link.getAttribute('href') || '') : '';
        if (href && isAdUrl(href)) {
          e.stopPropagation(); e.stopImmediatePropagation(); e.preventDefault();
          link.remove();
        }
        // dirty hosts: starve document-level handlers for clean links too.
        // default navigation still happens; the popunder handler never fires.
        else if (clickGuardOn()) { e.stopPropagation(); }
        return;
      }
      // empty-space click: only swallowed on known-dirty hosts. everywhere
      // else every click passes through untouched, so app-uis can't break.
      if (!clickGuardOn()) return;
      e.stopPropagation();
    } catch (err) {}
  }, true);

  // domain-scoped upstream cosmetic rules (compiled at nix build time from
  // easylist/fanboy general_hide + specific_hide components, spliced in at
  // //__SITE_DATA__ as SITE_CSS_DATA / SITE_UNHIDE_DATA; absent in dev runs).
  // css applies to future nodes automatically, so one injection per page.
  function siteSelectors() {
    var data = (typeof SITE_CSS_DATA !== 'undefined') ? SITE_CSS_DATA : {};
    var undata = (typeof SITE_UNHIDE_DATA !== 'undefined') ? SITE_UNHIDE_DATA : {};
    var out = [];
    try {
      var labels = location.hostname.toLowerCase().split('.');
      var un = {};
      var g = undata['*'] || [];
      for (var k = 0; k < g.length; k++) un[g[k]] = 1;
      for (var i = 0; i < labels.length - 1; i++) {
        var d = labels.slice(i).join('.');
        if (data[d]) out.push.apply(out, data[d]);
        var arr = undata[d];
        if (arr) for (var m = 0; m < arr.length; m++) un[arr[m]] = 1;
      }
      out = out.filter(function (s) { return !un[s]; });
    } catch (e) {}
    return out;
  }
  function applySiteCSS() {
    try {
      if (document.getElementById('qute-site-css')) return;
      var sels = siteSelectors();
      if (!sels.length || !document.documentElement) return;
      var s = document.createElement('style');
      s.id = 'qute-site-css';
      var css = '';
      for (var i = 0; i < sels.length; i += 200) {
        css += sels.slice(i, i + 200).join(',') + '{display:none !important;}';
      }
      s.textContent = css;
      (document.head || document.documentElement).appendChild(s);
    } catch (e) {}
  }

  injectCSS(); applySiteCSS();
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { injectCSS(); applySiteCSS(); killOverlays(); pruneAdLinks(); });
  } else {
    killOverlays(); pruneAdLinks();
  }
  // re-run on dynamic junk, throttled
  var pending = false;
  new MutationObserver(function () {
    if (pending) return;
    pending = true;
    setTimeout(function () { pending = false; killOverlays(); pruneAdLinks(); }, 500);
  }).observe(document.documentElement, { childList: true, subtree: true });
})();
