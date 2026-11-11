// ==UserScript==
// @name         qute cosmetic adblock
// @namespace    chai.qute.adblock
// @version      1.6.7
// @description  cosmetic ad filtering for qutebrowser: element hiding, procedural filters, scriptlets, dead-slot collapsing
// @match        *://*/*
// @run-at       document-start
// @noframes
// @grant        none
// ==/UserScript==
(function () {
  'use strict';
  //__DATA__

  window.__qadbMain = 1;
  var host = (location.hostname || '').toLowerCase();
  if (!host) return;
  var labels = host.split('.');
  var suffixes = [];
  for (var i = 0; i < labels.length; i++) suffixes.push(labels.slice(i).join('.'));

  function collect(map) {
    var out = [];
    for (var i = 0; i < suffixes.length; i++) {
      var v = map[suffixes[i]];
      if (v) out.push.apply(out, v);
    }
    return out;
  }

  // ---------------------------------------------------------------- css layer
  var exc = Object.create(null);
  collect(ADB.de).forEach(function (s) { exc[s] = 1; });
  ADB.ge.forEach(function (s) { exc[s] = 1; });

  function cssFor(list) {
    var out = [];
    for (var i = 0; i < list.length; i++) if (!exc[list[i]]) out.push(list[i]);
    return out;
  }

  function injectCSS(selectors, id) {
    if (!selectors.length) return;
    var root = document.head || document.documentElement;
    if (!root) return;
    var s = document.createElement('style');
    s.id = id;
    s.setAttribute('type', 'text/css');
    // one selector per rule: the css parser drops only the invalid rule
    // itself, never its neighbours (comma lists die wholesale)
    var css = '';
    for (var i = 0; i < selectors.length; i++) {
      css += selectors[i] + '{display:none !important}\n';
    }
    s.textContent = css;
    root.appendChild(s);
  }

  function collectEntities(map) {
    var out = [];
    for (var k in map) {
      if (k.charAt(k.length - 1) !== '*') continue;
      var prefix = k.slice(0, -1); // 'pornhub.'
      for (var i = 0; i < suffixes.length; i++) {
        var suf = suffixes[i];
        if (suf.indexOf(prefix) === 0 &&
            suf.slice(prefix.length).indexOf('.') === -1) {
          out.push.apply(out, map[k]);
          break;
        }
      }
    }
    return out;
  }

  var genericSels = cssFor(ADB.g);
  var siteSels = cssFor(collect(ADB.d).concat(collectEntities(ADB.d)));

  // at @run-at document-start QtWebEngine gives us an empty document: <html> does
  // not exist yet, so wait for it (fires before <head> is parsed -> no ad flash).
  function ensureCSS() {
    if (document.getElementById('qadb-generic')) return true;
    if (!document.documentElement) return false;
    injectCSS(genericSels, 'qadb-generic');
    injectCSS(siteSels, 'qadb-site');
    return true;
  }
  if (!ensureCSS()) {
    try {
      var cssWatch = new MutationObserver(function () {
        if (ensureCSS()) cssWatch.disconnect();
      });
      cssWatch.observe(document, { childList: true, subtree: true });
    } catch (e) {}
  }

  // ------------------------------------------------------------- hide helpers
  function hide(el) {
    if (!el || el.__qadb) return;
    el.__qadb = 1;
    try { el.style.setProperty('display', 'none', 'important'); } catch (e) {}
  }

  // ------------------------------------------------------- procedural filters
  var OPS = ['has-text', 'contains', 'upward', 'nth-ancestor', 'xpath', 'remove',
    'style', 'matches-css-before', 'matches-css-after', 'matches-css',
    'matches-attr', 'min-text-length', 'watch-attr', 'others', 'if',
    'matches-path', 'matches-prop', 'shadow-root', 'shadow', 'remove-attr',
    'remove-class'];

  function findOp(rule, from) {
    for (var i = from; i < rule.length; i++) {
      if (rule.charAt(i) !== ':') continue;
      for (var j = 0; j < OPS.length; j++) {
        var o = OPS[j];
        if (rule.substr(i + 1, o.length) !== o) continue;
        var after = rule.charAt(i + 1 + o.length);
        if (after === '(' || (o === 'shadow-root' && after === '')) return { idx: i, name: o };
      }
    }
    return null;
  }

  function readArg(rule, start) {
    // start points at '(' ; returns {arg, end} with end = index after ')'
    var depth = 0, quote = null;
    for (var i = start; i < rule.length; i++) {
      var ch = rule.charAt(i);
      if (quote) { if (ch === quote && rule.charAt(i - 1) !== '\\') quote = null; continue; }
      if (ch === '"' || ch === "'") { quote = ch; continue; }
      if (ch === '(') depth++;
      else if (ch === ')') { depth--; if (depth === 0) return { arg: rule.slice(start + 1, i), end: i + 1 }; }
    }
    return null;
  }

  function parseProc(rule) {
    var first = findOp(rule, 0);
    if (!first) return null;
    var base = rule.slice(0, first.idx);
    var ops = [];
    var pos = first.idx;
    while (pos < rule.length) {
      var op = findOp(rule, pos);
      if (!op || op.idx !== pos) return null;
      var name = op.name;
      var p = pos + 1 + name.length;
      if (rule.charAt(p) === '(') {
        var r = readArg(rule, p);
        if (!r) return null;
        ops.push({ name: name, arg: r.arg });
        pos = r.end;
      } else {
        ops.push({ name: name, arg: '' });
        pos = p;
      }
    }
    return { base: base, ops: ops };
  }

  function unquote(s) {
    s = s.trim();
    if (s.length > 1 && (s.charAt(0) === '"' || s.charAt(0) === "'") && s.charAt(s.length - 1) === s.charAt(0)) {
      return s.slice(1, -1);
    }
    return s;
  }

  function cssMatch(el, arg) {
    var m = /^\s*([-\w]+)\s*:\s*(.*)$/.exec(arg);
    if (!m) return false;
    var val;
    try { val = getComputedStyle(el).getPropertyValue(m[1]); } catch (e) { return false; }
    var want = unquote(m[2]);
    if (want.charAt(0) === '/' && want.lastIndexOf('/') > 0) {
      var end = want.lastIndexOf('/');
      try { return new RegExp(want.slice(1, end), want.slice(end + 1)).test(val); } catch (e) { return false; }
    }
    return val.trim() === want.trim();
  }

  function attrMatch(el, arg) {
    var m = /^\s*([-\w]+)\s*([~|^$*]?=)\s*(.*)$/.exec(arg);
    if (!m) return false;
    var v = el.getAttribute(m[1]);
    if (v === null) return false;
    var want = unquote(m[3]);
    var re = null;
    if (want.charAt(0) === '/' && want.lastIndexOf('/') > 0) {
      var end = want.lastIndexOf('/');
      try { re = new RegExp(want.slice(1, end), want.slice(end + 1)); } catch (e) { return false; }
    }
    switch (m[2]) {
      case '=': return re ? re.test(v) : v === want;
      case '^=': return v.indexOf(want) === 0;
      case '$=': return v.slice(-want.length) === want;
      case '*=': return v.indexOf(want) !== -1;
      case '~=': return (' ' + v + ' ').indexOf(' ' + want + ' ') !== -1;
      case '|=': return v === want || v.indexOf(want + '-') === 0;
    }
    return false;
  }

  function xpathAll(expr) {
    var out = [];
    try {
      var r = document.evaluate(expr, document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
      for (var i = 0; i < r.snapshotLength; i++) out.push(r.snapshotItem(i));
    } catch (e) {}
    return out;
  }

  function applyProc(rule) {
    var p = parseProc(rule);
    if (!p) return;
    var list;
    try { list = p.base ? Array.prototype.slice.call(document.querySelectorAll(p.base)) : []; } catch (e) { return; }
    if (!list.length) return;
    for (var i = 0; i < p.ops.length; i++) {
      var op = p.ops[i], arg = op.arg, next = [];
      switch (op.name) {
        case 'has-text':
        case 'contains': {
          var needle = unquote(arg).toLowerCase();
          for (var a = 0; a < list.length; a++) {
            var t = (list[a].textContent || '').toLowerCase();
            if (t.indexOf(needle) !== -1) next.push(list[a]);
          }
          list = next; break;
        }
        case 'min-text-length': {
          var n = parseInt(arg, 10) || 0;
          for (var b = 0; b < list.length; b++) if ((list[b].textContent || '').length >= n) next.push(list[b]);
          list = next; break;
        }
        case 'matches-css':
        case 'matches-css-before':
        case 'matches-css-after': {
          for (var c = 0; c < list.length; c++) if (cssMatch(list[c], arg)) next.push(list[c]);
          list = next; break;
        }
        case 'matches-attr': {
          for (var d = 0; d < list.length; d++) if (attrMatch(list[d], arg)) next.push(list[d]);
          list = next; break;
        }
        case 'matches-path': {
          var re = null;
          try { re = new RegExp(unquote(arg)); } catch (e) { return; }
          if (!re.test(location.pathname + location.search)) return;
          break;
        }
        case 'upward':
        case 'nth-ancestor': {
          var up = parseInt(arg, 10) || 1;
          for (var e = 0; e < list.length; e++) {
            var el = list[e];
            for (var k = 0; k < up && el; k++) el = el.parentElement;
            if (el) next.push(el);
          }
          list = next; break;
        }
        case 'xpath': {
          var found = xpathAll(unquote(arg));
          var set = new Set(found);
          for (var f = 0; f < list.length; f++) if (set.has(list[f])) next.push(list[f]);
          list = next; break;
        }
        case 'others': {
          var seen = new Set(list);
          for (var g = 0; g < list.length; g++) {
            var sib = list[g].parentElement ? list[g].parentElement.children : [];
            for (var h = 0; h < sib.length; h++) if (!seen.has(sib[h])) next.push(sib[h]);
          }
          list = next; break;
        }
        case 'remove': {
          for (var m = 0; m < list.length; m++) { try { list[m].remove(); } catch (e) {} }
          return;
        }
        case 'style': {
          for (var q = 0; q < list.length; q++) { try { list[q].style.cssText += ';' + arg; } catch (e) {} }
          return;
        }
        case 'remove-attr': {
          var at = unquote(arg);
          for (var r2 = 0; r2 < list.length; r2++) { try { list[r2].removeAttribute(at); } catch (e) {} }
          return;
        }
        case 'remove-class': {
          var cl = unquote(arg);
          for (var s2 = 0; s2 < list.length; s2++) { try { list[s2].classList.remove(cl); } catch (e) {} }
          return;
        }
        default:
          return; // unsupported operator: drop the rule rather than mis-apply it
      }
      if (!list.length) return;
    }
    for (var z = 0; z < list.length; z++) hide(list[z]);
  }

  var procRules = collect(ADB.dp).concat(collectEntities(ADB.dp), ADB.gp);
  var procDone = Object.create(null);
  function runProc() {
    for (var i = 0; i < procRules.length; i++) {
      var r = procRules[i];
      if (procDone[r]) continue;
      procDone[r] = 1;
      try { applyProc(r); } catch (e) {}
    }
  }

  // ---------------------------------------------------------------- scriptlets
  function splitArgs(s) {
    var out = [], cur = '', quote = null, depth = 0;
    for (var i = 0; i < s.length; i++) {
      var ch = s.charAt(i);
      if (quote) { if (ch === quote) quote = null; else cur += ch; continue; }
      if (ch === '"' || ch === "'") { quote = ch; continue; }
      if (ch === '(') depth++;
      if (ch === ')') depth--;
      if (ch === ',' && depth === 0) { out.push(cur.trim()); cur = ''; continue; }
      cur += ch;
    }
    if (cur.trim()) out.push(cur.trim());
    return out;
  }

  function chainGet(chain) {
    var parts = chain.split('.');
    var obj = window;
    for (var i = 0; i < parts.length - 1; i++) {
      if (obj == null) return null;
      obj = obj[parts[i]];
    }
    return { obj: obj, prop: parts[parts.length - 1] };
  }

  function constValue(v) {
    switch (v) {
      case 'true': return true;
      case 'false': return false;
      case 'null': return null;
      case 'undefined': return undefined;
      case 'noopFunc': return function () {};
      case 'emptyArr': return [];
      case 'emptyObj': return {};
      case 'noopCallbackFunc': return function (cb) { if (typeof cb === 'function') cb(); };
      case 'trueFunc': return function () { return true; };
      case 'falseFunc': return function () { return false; };
      case '': return '';
    }
    var n = Number(v);
    return isNaN(n) ? v : n;
  }

  function forceLeaf(obj, chain, value) {
    var parts = chain.split('.');
    for (var i = 0; i < parts.length - 1; i++) {
      if (obj == null || !(parts[i] in Object(obj))) return;
      obj = obj[parts[i]];
    }
    try {
      Object.defineProperty(obj, parts[parts.length - 1], {
        get: function () { return value; },
        set: function () {},
        configurable: true,
        enumerable: true
      });
    } catch (e) {}
  }

  function defineConst(chain, value) {
    var t = chainGet(chain);
    if (t && t.obj) {
      try {
        Object.defineProperty(t.obj, t.prop, {
          get: function () { return value; },
          set: function () {},
          configurable: false,
          enumerable: true
        });
      } catch (e) {}
      return;
    }
    // the parent object does not exist yet: trap the assignment on the
    // closest existing ancestor and re-apply when the page defines it
    var parts = chain.split('.');
    var obj = window, i = 0;
    while (i < parts.length - 1 && obj != null && (parts[i] in obj)) {
      obj = obj[parts[i]];
      i++;
    }
    if (obj == null || i >= parts.length - 1) return;
    var rest = parts.slice(i);
    try {
      Object.defineProperty(obj, rest[0], {
        configurable: true,
        enumerable: true,
        get: function () { return obj['__qadb_v_' + rest[0]]; },
        set: function (v) {
          obj['__qadb_v_' + rest[0]] = v;
          forceLeaf(v, rest.join('.'), value);
        }
      });
    } catch (e) {}
  }

  function abortRead(chain) {
    var t = chainGet(chain);
    if (!t || !t.obj) return;
    try {
      Object.defineProperty(t.obj, t.prop, {
        get: function () { throw new ReferenceError('qadb'); },
        set: function () {},
        configurable: false
      });
    } catch (e) {}
  }

  function abortWrite(chain) {
    var t = chainGet(chain);
    if (!t || !t.obj) return;
    try {
      Object.defineProperty(t.obj, t.prop, {
        get: function () { return undefined; },
        set: function () { throw new ReferenceError('qadb'); },
        configurable: false
      });
    } catch (e) {}
  }

  function jsonPrune(paths) {
    var orig = JSON.parse;
    var list = paths.split(/\s+/).filter(Boolean);
    JSON.parse = function () {
      var res = orig.apply(this, arguments);
      try {
        for (var i = 0; i < list.length; i++) {
          var parts = list[i].split('.');
          var stack = [res];
          for (var p = 0; p < parts.length; p++) {
            var key = parts[p], nextStack = [];
            for (var s = 0; s < stack.length; s++) {
              var o = stack[s];
              if (o == null) continue;
              if (key === '[-]' && Array.isArray(o)) { nextStack.push.apply(nextStack, o); continue; }
              if (typeof o === 'object' && key in o) {
                if (p === parts.length - 1) { try { delete o[key]; } catch (e) {} }
                else nextStack.push(o[key]);
              }
            }
            stack = nextStack;
          }
        }
      } catch (e) {}
      return res;
    };
  }

  function timerDefuser(kind, needle, delay) {
    var orig = window[kind];
    if (typeof orig !== 'function') return;
    var re = null;
    if (needle) { try { re = new RegExp(needle); } catch (e) { re = null; } }
    window[kind] = function (fn, ms) {
      try {
        var src = typeof fn === 'function' ? fn.toString() : String(fn);
        var delayOk = !delay || String(ms) === String(delay);
        if (delayOk && (!re || re.test(src))) return 0;
      } catch (e) {}
      return orig.apply(window, arguments);
    };
  }

  function preventFetch(pattern) {
    var orig = window.fetch;
    if (typeof orig !== 'function') return;
    var re = null;
    try { re = new RegExp(pattern); } catch (e) { return; }
    window.fetch = function (input) {
      var u = typeof input === 'string' ? input : (input && input.url) || '';
      if (re.test(u)) return Promise.reject(new TypeError('qadb'));
      return orig.apply(window, arguments);
    };
  }

  function preventXhr(pattern) {
    var orig = XMLHttpRequest.prototype.open;
    var re = null;
    try { re = new RegExp(pattern); } catch (e) { return; }
    XMLHttpRequest.prototype.open = function (method, url) {
      if (re.test(String(url))) { try { this.abort(); } catch (e) {} return; }
      return orig.apply(this, arguments);
    };
  }

  function domAction(fn) {
    var run = function () { try { fn(); } catch (e) {} };
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', run);
    else run();
    try {
      new MutationObserver(run).observe(document.documentElement, { childList: true, subtree: true });
    } catch (e) {}
  }

  function prunePaths(obj, paths) {
    for (var i = 0; i < paths.length; i++) {
      var parts = paths[i].split('.');
      var stack = [obj];
      for (var q = 0; q < parts.length; q++) {
        var key = parts[q], next = [];
        for (var w = 0; w < stack.length; w++) {
          var o = stack[w];
          if (o == null) continue;
          if (key === '[-]' && Array.isArray(o)) { next.push.apply(next, o); continue; }
          if (typeof o === 'object' && key in o) {
            if (q === parts.length - 1) { try { delete o[key]; } catch (e) {} }
            else next.push(o[key]);
          }
        }
        stack = next;
      }
    }
  }

  function compileRe(x) {
    try { return new RegExp(x); } catch (e) { return null; }
  }

  function urlArg(input) {
    if (typeof input === 'string') return input;
    if (input && input.url) return input.url;
    return '';
  }

  // fetch body rewriting (trusted-replace-fetch-response / trusted-rpfr /
  // json-prune-fetch-response)
  var fetchHooks = [];
  function addFetchHook(h) { fetchHooks.push(h); patchFetch(); }
  var _fetchPatched = false;
  function patchFetch() {
    if (_fetchPatched || typeof window.fetch !== 'function') return;
    _fetchPatched = true;
    var orig = window.fetch;
    window.fetch = function (input, init) {
      var u = urlArg(input);
      var hits = [];
      for (var i = 0; i < fetchHooks.length; i++) {
        if (fetchHooks[i].url && fetchHooks[i].url.test(u)) hits.push(fetchHooks[i]);
      }
      if (!hits.length) return orig.apply(window, arguments);
      return orig.apply(window, arguments).then(function (resp) {
        try {
          return resp.clone().text().then(function (body) {
            for (var i = 0; i < hits.length; i++) {
              var h = hits[i];
              if (h.mode === 'prune') {
                try { var j = JSON.parse(body); prunePaths(j, h.paths); body = JSON.stringify(j); } catch (e) {}
              } else if (h.re) {
                body = body.replace(h.re, h.repl);
              }
            }
            return new Response(body, {
              status: resp.status, statusText: resp.statusText, headers: resp.headers
            });
          });
        } catch (e) { return resp; }
      });
    };
  }

  // XHR responseText rewriting (trusted-replace-xhr-response / json-prune-xhr-response)
  var xhrHooks = [];
  var _xhrPatched = false;
  function addXhrHook(h) { xhrHooks.push(h); patchXhr(); }
  function patchXhr() {
    if (_xhrPatched) return;
    var proto = window.XMLHttpRequest && window.XMLHttpRequest.prototype;
    if (!proto || !proto.open) return;
    _xhrPatched = true;
    var oOpen = proto.open, oSend = proto.send;
    proto.open = function (m, u) {
      this.__qurl = String(u);
      return oOpen.apply(this, arguments);
    };
    proto.send = function () {
      var x = this;
      var hits = [];
      for (var i = 0; i < xhrHooks.length; i++) {
        if (xhrHooks[i].url && xhrHooks[i].url.test(x.__qurl || '')) hits.push(xhrHooks[i]);
      }
      if (hits.length) {
        var rd = Object.getOwnPropertyDescriptor(proto, 'responseText');
        var rr = Object.getOwnPropertyDescriptor(proto, 'response');
        try {
          Object.defineProperty(x, 'responseText', {
            configurable: true,
            get: function () {
              var t = rd ? rd.get.call(x) : '';
              for (var i = 0; i < hits.length; i++) {
                var h = hits[i];
                if (h.mode === 'prune') {
                  try { var j = JSON.parse(t); prunePaths(j, h.paths); t = JSON.stringify(j); } catch (e) {}
                } else if (h.re) { t = t.replace(h.re, h.repl); }
              }
              return t;
            }
          });
          Object.defineProperty(x, 'response', {
            configurable: true,
            get: function () {
              var v = rr ? rr.get.call(x) : null;
              if (x.responseType === 'json' || (v && typeof v === 'object')) {
                try {
                  var t2 = rd ? rd.get.call(x) : '';
                  for (var i = 0; i < hits.length; i++) {
                    var h = hits[i];
                    if (h.mode === 'prune') {
                      try { var j = JSON.parse(t2); prunePaths(j, h.paths); t2 = JSON.stringify(j); } catch (e) {}
                    } else if (h.re) { t2 = t2.replace(h.re, h.repl); }
                  }
                  return JSON.parse(t2);
                } catch (e) { return v; }
              }
              return v;
            }
          });
        } catch (e) {}
      }
      return oSend.apply(this, arguments);
    };
  }

  function nodeTextOp(selector, pattern, replacement) {
    var re = compileRe(pattern);
    if (!re) return;
    var run = function () {
      try {
        document.querySelectorAll(selector || 'script').forEach(function (el) {
          var w = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, null, false);
          while (w.nextNode()) {
            var n = w.currentNode;
            if (re.test(n.nodeValue)) n.nodeValue = n.nodeValue.replace(re, replacement);
          }
        });
      } catch (e) {}
    };
    domAction(run);
  }

  function domlessEval(needle) {
    var origEval = window.eval;
    var reE2 = compileRe(needle || '');
    window.eval = function (code) {
      if (!reE2 || reE2.test(String(code))) return undefined;
      return origEval.apply(window, arguments);
    };
    try {
      var origFn = Function.prototype.constructor;
      Function.prototype.constructor = function (code) {
        if (reE2 && reE2.test(String(code))) return function () {};
        return origFn.apply(this, arguments);
      };
    } catch (e) {}
  }

  function runScriptlet(spec) {
    var args = splitArgs(spec);
    var name = unquote(args[0] || '');
    var a = args.slice(1).map(unquote);
    switch (name) {
      // ---- uBO aliases ----
      case 'set': case 'trusted-set':
        defineConst(a[0], constValue(a[1])); break;
      case 'aopr':
        abortRead(a[0]); break;
      case 'aopw':
        abortWrite(a[0]); break;
      case 'aost': case 'acis': {
        var nA = a[0];
        var needleA = a[1] || '';
        var tA = chainGet(nA);
        if (!tA || !tA.obj) break;
        try {
          Object.defineProperty(tA.obj, tA.prop, {
            get: function () {
              var cs = document.currentScript;
              if (cs && (!needleA || (cs.textContent || '').indexOf(needleA) !== -1)) throw new ReferenceError('qadb');
              return undefined;
            },
            set: function () {},
            configurable: false
          });
        } catch (e) {}
        break;
      }
      case 'acs': case 'abort-current-script': {
        // abort-current-script(chain, needle): property access throws when the
        // executing script (inline text or src) matches needle
        var tCS = chainGet(a[0]);
        if (!tCS || !tCS.obj) break;
        try {
          Object.defineProperty(tCS.obj, tCS.prop, {
            get: function () {
              var cs = document.currentScript;
              if (cs) {
                var src = (cs.textContent || '') + ' ' + (cs.src || '');
                if (!a[1] || src.indexOf(a[1]) !== -1) throw new ReferenceError('qadb');
              }
              return undefined;
            },
            set: function (v) {
              var cs2 = document.currentScript;
              if (cs2) {
                var src2 = (cs2.textContent || '') + ' ' + (cs2.src || '');
                if (!a[1] || src2.indexOf(a[1]) !== -1) throw new ReferenceError('qadb');
              }
            },
            configurable: false
          });
        } catch (e) {}
        break;
      }
      case 'nostif':
        timerDefuser('setTimeout', a[0], a[1]); break;
      case 'nosiif':
        timerDefuser('setInterval', a[0], a[1]); break;
      case 'nowoif': {
        var origOpen2 = window.open;
        var reO2 = compileRe(a[0] || a[1] || '');
        window.open = function (url) {
          if (reO2 && reO2.test(String(url || ''))) return null;
          if (!reO2 && !a[0]) return null;
          return origOpen2.apply(window, arguments);
        };
        break;
      }
      case 'no-fetch-if': case 'nofetch-if': {
        var pat = (a[0] || '').split(' method:')[0].split(' type:')[0];
        preventFetch(pat || '.');
        break;
      }
      case 'no-xhr-if': case 'noxhr-if': {
        var patX = (a[0] || '').split(' method:')[0].split(' type:')[0];
        preventXhr(patX || '.');
        break;
      }
      case 'noeval-if': case 'noeval':
        domlessEval(a[0]); break;
      case 'ra':
        domAction(function () {
          document.querySelectorAll(a[1] || '*').forEach(function (el) { el.removeAttribute(a[0]); });
        });
        break;
      case 'rc':
        domAction(function () {
          document.querySelectorAll(a[1] || '*').forEach(function (el) { el.classList.remove(a[0]); });
        });
        break;
      case 'aeld': {
        var origAel2 = EventTarget.prototype.addEventListener;
        var type2 = a[0] || '';
        var reA2 = compileRe(a[1] || '');
        EventTarget.prototype.addEventListener = function (type, fn) {
          try {
            var src = typeof fn === 'function' ? fn.toString() : String(fn);
            var typeOk = !type2 || type2 === '*' || type2 === type;
            var srcOk = !reA2 || reA2.test(src);
            if (typeOk && srcOk) return;
          } catch (e) {}
          return origAel2.apply(this, arguments);
        };
        break;
      }
      // ---- cookies / storage ----
      case 'trusted-set-cookie': case 'set-cookie': {
        // uBO form: name, value, [domain], [path], [expire], ..., 'reload', [delay]
        var scv = a.slice(1);
        var name = a[0], value = scv[0] || '';
        var reload = false, delay = 1000;
        var attr = '';
        for (var cvi = 1; cvi < scv.length; cvi++) {
          var tok = scv[cvi];
          if (tok === 'reload') { reload = true; continue; }
          if (/^\d+$/.test(tok) && reload) { delay = parseInt(tok, 10); continue; }
          if (!tok) continue;
          if (/^(domain|path|secure|samesite|expires)=/i.test(tok)) attr += '; ' + tok;
          else if (tok === 'now') attr += '; expires=Thu, 01 Jan 1970 00:00:00 GMT';
          else if (/^-?\d+$/.test(tok)) attr += '; max-age=' + tok;
        }
        try {
          document.cookie = name + '=' + value + '; path=/' + attr;
          if (reload) {
            setTimeout(function () {
              // only reload if the cookie actually stuck (uBO semantics)
              if ((';' + document.cookie).indexOf(';' + name + '=' + value) !== -1) {
                location.reload();
              }
            }, Math.max(200, delay));
          }
        } catch (e) {}
        break;
      }
      case 'remove-cookie': {
        var reRc = compileRe(a[0] || a[1] || '');
        var rcFn = function () {
          if (!reRc) return;
          try {
            document.cookie.split(';').forEach(function (c) {
              var k = c.split('=')[0].trim();
              if (reRc.test(k)) document.cookie = k + '=; Max-Age=-99999999; path=/';
            });
          } catch (e) {}
        };
        domAction(rcFn);
        break;
      }
      case 'set-local-storage-item': case 'trusted-set-local-storage-item':
      case 'remove-local-storage-item': {
        try {
          if (a[1] === '$remove$' || name.indexOf('remove') === 0) localStorage.removeItem(a[0]);
          else localStorage.setItem(a[0], a[1] || '');
        } catch (e) {}
        break;
      }
      case 'set-session-storage-item': case 'remove-session-storage-item': {
        try {
          if (a[1] === '$remove$' || name.indexOf('remove') === 0) sessionStorage.removeItem(a[0]);
          else sessionStorage.setItem(a[0], a[1] || '');
        } catch (e) {}
        break;
      }
      // ---- dom helpers ----
      case 'trusted-click-element': {
        var selC = (a[0] || '').replace(/,+/g, ',');
        var delayC = parseInt(a[2] || a[1] || '10', 10) || 10;
        var clickC = function () {
          try {
            document.querySelectorAll(selC).forEach(function (el) { el.click(); });
          } catch (e) {}
        };
        setTimeout(clickC, delayC);
        setTimeout(clickC, delayC + 500);
        break;
      }
      case 'rmnt':
        nodeTextOp(a[0], a[1] || '', '');
        break;
      case 'rpnt': case 'trusted-rpnt':
        nodeTextOp(a[0], a[1] || '', a[2] || '');
        break;
      case 'href-sanitizer':
        domAction(function () {
          try {
            document.querySelectorAll(a[0] || 'a[href*="#@"]').forEach(function (el) {
              var h = el.getAttribute('href') || '';
              var cut = h.indexOf('#@');
              if (cut !== -1) el.setAttribute('href', h.slice(0, cut));
            });
          } catch (e) {}
        });
        break;
      // ---- timers ----
      case 'nano-stb': case 'nano-sib': {
        var kind = name === 'nano-stb' ? 'setTimeout' : 'setInterval';
        var patN = a[0] || '';
        var boost = parseFloat(a[2] || a[3] || '0.001') || 0.001;
        var origN = window[kind];
        if (typeof origN !== 'function') break;
        var reN = patN && patN !== '*' ? compileRe(patN) : null;
        window[kind] = function (fn, ms) {
          try {
            var src = typeof fn === 'function' ? fn.toString() : String(fn);
            if (!reN || reN.test(src)) {
              arguments[1] = Math.max(1, Math.round((ms || 0) * boost));
            }
          } catch (e) {}
          return origN.apply(window, arguments);
        };
        break;
      }
      // ---- response patching ----
      case 'trusted-rpfr': case 'trusted-replace-fetch-response': {
        addFetchHook({
          mode: 'replace',
          re: a[0] ? new RegExp(a[0], 'gms') : null,
          repl: a[1] || '',
          url: compileRe(a[2] || a[3] || '')
        });
        break;
      }
      case 'json-prune-fetch-response': {
        var pp = (a[0] || '').split(/\s+/).filter(Boolean);
        addFetchHook({ mode: 'prune', paths: pp, url: compileRe(a[2] || a[3] || '') });
        break;
      }
      case 'trusted-replace-xhr-response': {
        addXhrHook({
          mode: 'replace',
          re: a[0] ? new RegExp(a[0].replace(/^\/(.+)\/[a-z]*$/, '$1'), 'gms') : null,
          repl: a[1] || '',
          url: compileRe(a[2] || '')
        });
        break;
      }
      case 'json-prune-xhr-response': {
        var px = (a[0] || '').split(/\s+/).filter(Boolean);
        addXhrHook({ mode: 'prune', paths: px, url: compileRe(a[2] || a[3] || '') });
        break;
      }
      case 'trusted-replace-argument': {
        var tR = chainGet(a[0]);
        if (!tR || !tR.obj) break;
        var idxR = parseInt(a[1] || '0', 10) || 0;
        var valR = a[2];
        var reCond = compileRe((a[3] || '').replace(/^condition\s*,?\s*/, ''));
        var fnR = tR.obj[tR.prop];
        if (typeof fnR !== 'function') break;
        tR.obj[tR.prop] = function () {
          try {
            var hit = !reCond;
            for (var i = 0; i < arguments.length; i++) {
              if (reCond && reCond.test(String(arguments[i]))) { hit = true; break; }
            }
            if (hit) {
              var v = valR;
              if (/^json:/.test(v)) v = JSON.parse(v.slice(5));
              arguments[idxR] = v;
            }
          } catch (e) {}
          return fnR.apply(this, arguments);
        };
        break;
      }
      // ---- long names ----
      case 'set-constant':
      case 'trusted-set-constant':
        defineConst(a[0], constValue(a[1])); break;
      case 'abort-on-property-read':
        abortRead(a[0]); break;
      case 'abort-on-property-write':
        abortWrite(a[0]); break;
      case 'abort-current-inline-script': {
        var needle = a[1] || '';
        var t = chainGet(a[0]);
        if (!t || !t.obj) break;
        try {
          Object.defineProperty(t.obj, t.prop, {
            get: function () {
              var cs = document.currentScript;
              if (cs && (!needle || (cs.textContent || '').indexOf(needle) !== -1)) throw new ReferenceError('qadb');
              return undefined;
            },
            set: function () {},
            configurable: false
          });
        } catch (e) {}
        break;
      }
      case 'json-prune':
        jsonPrune(a.join(' ')); break;
      case 'no-setTimeout-if':
        timerDefuser('setTimeout', a[0], a[1]); break;
      case 'no-setInterval-if':
        timerDefuser('setInterval', a[0], a[1]); break;
      case 'prevent-fetch':
        preventFetch(a[0]); break;
      case 'prevent-xhr':
        preventXhr(a[0]); break;
      case 'remove-attr':
        domAction(function () {
          document.querySelectorAll(a[1] || '*').forEach(function (el) { el.removeAttribute(a[0]); });
        });
        break;
      case 'remove-class':
        domAction(function () {
          document.querySelectorAll(a[1] || '*').forEach(function (el) { el.classList.remove(a[0]); });
        });
        break;
      case 'set-attr':
        domAction(function () {
          document.querySelectorAll(a[0] || '*').forEach(function (el) { el.setAttribute(a[1], a[2] || ''); });
        });
        break;
      case 'addEventListener-defuser': {
        var origAel = EventTarget.prototype.addEventListener;
        var reA = null;
        try { reA = new RegExp(a[1] || a[0]); } catch (e) { break; }
        EventTarget.prototype.addEventListener = function (type, fn) {
          try {
            var src = typeof fn === 'function' ? fn.toString() : String(fn);
            if (reA.test(src)) return;
          } catch (e) {}
          return origAel.apply(this, arguments);
        };
        break;
      }
      case 'window.open-defuser': {
        var origOpen = window.open;
        var reO = null;
        try { reO = new RegExp(a[0]); } catch (e) { break; }
        window.open = function (url) {
          if (reO.test(String(url || ''))) return null;
          return origOpen.apply(window, arguments);
        };
        break;
      }
      case 'prevent-eval-if': {
        domlessEval(a[0]);
        break;
      }
      case 'cookie-remover': {
        var reC = null;
        try { reC = new RegExp(a[0]); } catch (e) { break; }
        var desc = Object.getOwnPropertyDescriptor(Document.prototype, 'cookie');
        if (!desc || !desc.set) break;
        Object.defineProperty(document, 'cookie', {
          get: desc.get,
          set: function (v) { if (!reC.test(String(v))) desc.set.call(document, v); },
          configurable: true
        });
        break;
      }
      case 'nowebrtc': {
        var noop = function () { throw new Error('qadb'); };
        try { window.RTCPeerConnection = noop; window.webkitRTCPeerConnection = noop; } catch (e) {}
        break;
      }
      case 'set-cookie':
        try { document.cookie = a[0] + '=' + (a[1] || '') + '; path=' + (a[2] || '/'); } catch (e) {}
        break;
      default:
        break; // unsupported scriptlet
    }
  }

  // ---- scriptlet skip list -------------------------------------------------
  // scriptlets exist to kill ads and anti-adblock walls. on sites where ads
  // are not a problem they are pure risk (youtube: response rewriting,
  // appendChild patching and timer boosting corrupted player controls).
  // KNOB: domains (with any subdomain) where scriptlets must not run.
  var SCRIPTLET_SKIP = [
    'youtube.com',
    'youtube-nocookie.com',
    'youtu.be'
  ];
  var scriptletsSkipped = false;
  for (var sk = 0; sk < SCRIPTLET_SKIP.length; sk++) {
    var bad = SCRIPTLET_SKIP[sk];
    if (host === bad || host.slice(-(bad.length + 1)) === '.' + bad) {
      scriptletsSkipped = true;
      break;
    }
  }
  var scriptlets = scriptletsSkipped ? [] :
      collect(ADB.ds).concat(collectEntities(ADB.ds), ADB.gs);
  for (var si = 0; si < scriptlets.length; si++) {
    try { runScriptlet(scriptlets[si]); } catch (e) {}
  }

  // ------------------------------------------------------- dead slot collapser
  var AD_TOKEN = /(^|[-_ ])(ad|ads|adv|advert|adverts|advertisement|advertising|adslot|adunit|adbox|adwrap|adwrapper|adcontainer|adbanner|adserver|adtech|adsense|adsbygoogle|dfp|gpt|sponsor|sponsored|promo|promoted|advertorial|prebid|taboola|outbrain|adchoices|sky|skyscraper)([-_ ]|$)/i;
  var AD_LABEL = /^(advertisement|advertising|publicidad|anzeige|sponsored|promoted|ad|ads|anuncio|publicit[eé]|reklame|pubblicit[aà])$/i;
  var CAND = '[id*="ad" i],[class*="ad" i],[id*="sponsor" i],[class*="sponsor" i],' +
    '[id*="promo" i],[class*="promo" i],[data-ad],[data-ad-slot],[data-ad-unit],' +
    '[aria-label*="advert" i],[id*="banner" i],[class*="banner" i]';

  function adish(el) {
    var idc = (el.id || '') + ' ' + (typeof el.className === 'string' ? el.className : '');
    if (AD_TOKEN.test(idc)) return true;
    var fi = el.querySelectorAll('iframe');
    for (var ai = 0; ai < fi.length; ai++) {
      var frI = fi[ai].getBoundingClientRect();
      if (crossHostIframe(fi[ai]) && isIabSize(Math.round(frI.width), Math.round(frI.height))) return true;
    }
    if (el.hasAttribute && (el.hasAttribute('data-ad') || el.hasAttribute('data-ad-slot') || el.hasAttribute('data-ad-unit'))) return true;
    var al = el.getAttribute && el.getAttribute('aria-label');
    if (al && /advert|sponsor|promo/i.test(al)) return true;
    return false;
  }

  var AD_SRC = /doubleclick|googlesynd|adservice|adsystem|adnxs|criteo|taboola|outbrain|mgid|revcontent|trafficjunky|juicyads|exoclick|exosrv|realsrv|elsrv|gsrv\.dev|tsyndicate|adtng|hilltop|propeller|banner\.go\?|spaceid=|popunder|popads|popcash|adsterra|zeropark|onclickads|smartadserver|rubicon|pubmatic|openx|spotx|a-ads|adcash|clickadu|onclickmega|galaksion|adsrv|whitetraf|trafficstars/i;

  // canonical IAB banner dimensions: a cross-origin iframe at exactly one of
  // these sizes is an ad unit, whatever its src says (legit embeds — video
  // players, tweets, maps, calendars — are never exact banner sizes)
  var IAB_SIZES = [[300,250],[336,280],[728,90],[160,600],[300,600],[970,90],[970,250],
    [320,50],[468,60],[234,60],[120,600],[125,125],[250,250],[200,200],[180,150],
    [980,120],[930,180],[750,100],[640,480],[120,60],[160,60],[320,100],[300,100],
    [720,300],[980,150],[250,360],[468,640],[300,50],[88,31],[120,240],[234,120]];
  function isIabSize(w, h) {
    for (var i = 0; i < IAB_SIZES.length; i++) {
      if (IAB_SIZES[i][0] === w && IAB_SIZES[i][1] === h) return true;
    }
    return false;
  }
  function crossHostIframe(f) {
    var src = f.getAttribute('src') || '';
    if (!src) return false;
    try { return new URL(src, location.href).host !== location.host; }
    catch (e) { return false; }
  }

  function hasContent(el) {
    var txt = (el.textContent || '').trim();
    if (txt.length > 0 && !AD_LABEL.test(txt)) return true;
    var media = el.querySelectorAll('img,video,canvas,svg,picture,object,embed');
    for (var i = 0; i < media.length; i++) {
      var m = media[i];
      var tag = m.tagName;
      if (tag === 'IMG' || tag === 'EMBED' || tag === 'OBJECT') {
        // broken creative (failed/blocked load): not content, collapse away
        if (m.complete && m.naturalWidth === 0 && !(m.alt || '').trim()) continue;
      }
      var r = m.getBoundingClientRect();
      if (r.width > 2 && r.height > 2) return true;
    }
    var frames = el.querySelectorAll('iframe');
    for (var j = 0; j < frames.length; j++) {
      var src = frames[j].getAttribute('src') || '';
      if (AD_SRC.test(src)) continue; // ad-network frame: never counts as content
      var fr = frames[j].getBoundingClientRect();
      if (crossHostIframe(frames[j]) && isIabSize(Math.round(fr.width), Math.round(fr.height))) continue;
      var fr = frames[j].getBoundingClientRect();
      if (src && !/^about:blank/i.test(src) && fr.height > 2) return true;
    }
    return false;
  }

  var STOP = /^(body|html|main|article)$/i;

  function collapse(el) {
    if (!el || el.__qadb) return;
    hide(el);
    var p = el.parentElement, depth = 0;
    while (p && depth < 3 && !STOP.test(p.tagName) && p !== document.body) {
      if (p.id === 'content' || /(^|[-_ ])(content|main|article|page|layout|grid|container)([-_ ]|$)/i.test(p.id + ' ' + (typeof p.className === 'string' ? p.className : ''))) break;
      if (hasContent(p)) break;
      hide(p);
      p = p.parentElement;
      depth++;
    }
  }

  function sweepAdFrames() {
    // any iframe pointing at an ad network is an ad unit by definition; walk
    // up to its sized slot wrapper and collapse it (covers containers whose
    // class/id gives no ad hint at all, e.g. notfans' <table>/.opt stack)
    var frames;
    try { frames = document.querySelectorAll('iframe'); } catch (e) { return; }
    for (var i = 0; i < frames.length; i++) {
      var f = frames[i];
      if (f.__qadb) continue;
      var src = f.getAttribute('src') || '';
      var fr0 = f.getBoundingClientRect();
      var isAdUnit = AD_SRC.test(src) ||
        (crossHostIframe(f) && isIabSize(Math.round(fr0.width), Math.round(fr0.height)));
      if (!isAdUnit) { f.__qadb = 1; continue; }
      f.__qadb = 1;
      var el = f.parentElement, depth = 0;
      while (el && el !== document.body && depth < 5) {
        var r = el.getBoundingClientRect();
        if (r.width >= 250 && r.height >= 90) {
          forceHide(el);
          // collapse now-empty wrappers above the slot too
          var up = el.parentElement, u = 0;
          while (up && up !== document.body && u < 3) {
            if (hasContent(up)) break;
            forceHide(up);
            up = up.parentElement; u++;
          }
          break;
        }
        if (hasContent(el)) { forceHide(f); break; }
        el = el.parentElement;
        depth++;
      }
    }
  }

  function forceHide(el) {
    // like hide() but ignores the __qabd once-mark: some sites revert inline
    // styles to defeat adblock (notfans' .nocopy armor), so these paths must
    // win the style war on every pass
    if (!el) return;
    try { el.style.setProperty('display', 'none', 'important'); } catch (e) {}
  }

  var PROMO_TEXT = /(unlock|join now|claim your|limited( time| offer)?|live (sex|cams)|\$\d|is free|free (trial|access|premium|tokens)|watch (now|free)|download now|special offer|– ?free|for free)/i;

  function sweepPromoStrips() {
    // top-of-page full-width promo strips (house ads, affiliate bars). shape:
    // direct body child, near y=0, short text, promo wording, and NOT a nav
    // bar (nav = all links same-host). collapses the whole class of
    // "BRAZZERS IS FREE / UNLOCK NOW" bars without any per-site rule.
    if (!document.body) return;
    var kids = document.body.children;
    for (var i = 0; i < kids.length && i < 12; i++) {
      var el = kids[i];
      var r = el.getBoundingClientRect();
      if (r.width < innerWidth * 0.6 || r.height < 22 || r.height > 180) continue;
      if (r.y > 200) continue;
      var txt = (el.textContent || '').trim();
      if (txt.length < 8 || txt.length > 220) continue;
      if (!PROMO_TEXT.test(txt)) continue;
      var links = el.querySelectorAll('a[href]');
      var sameHost = 0;
      for (var j = 0; j < links.length; j++) {
        try { if (new URL(links[j].href).host === location.host) sameHost++; } catch (e) {}
      }
      if (links.length && sameHost === links.length) continue; // navigation, not an ad
      forceHide(el);
    }
  }

  function sweep() {
    var nodes;
    try { nodes = document.querySelectorAll(CAND); } catch (e) { return; }
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.__qadb) continue;
      if (!adish(el)) continue;
      var r = el.getBoundingClientRect();
      if (r.width < 20 || r.height < 10) continue;
      if (hasContent(el)) continue;
      collapse(el);
    }
  }

  // --------------------------------------------- popunder / click-hijack guard
  // the "click anywhere, get sent somewhere" pattern: a document-level
  // click/mousedown handler that opens an ad window (or stages one at
  // about:blank and writes into it). two layers, both generic:
  //   1. window.open: ad-network urls + blank/blob/data staging are dead
  //      everywhere (same-host and non-ad cross-host opens stay alive: oauth,
  //      share intents). mirrors the old goop remover minus its oauth breakage.
  //   2. the handler itself is refused at registration time on any host not in
  //      POP_GUARD_SAFE (document/body/window-level listeners whose source
  //      mentions window.open / atob staging / ad networks). per-site lists are
  //      how uBO does this; an invertible allowlist is how we do it, so the
  //      long tail of tube/aggregator sites is covered without whack-a-mole.
  var POP_GUARD_SAFE = [
    'google.com', 'youtube.com', 'youtube-nocookie.com', 'github.com',
    'gitlab.com', 'reddit.com', 'x.com', 'twitter.com', 'whatsapp.com',
    'telegram.org', 'discord.com', 'netflix.com', 'twitch.tv', 'amazon.com',
    'mercadolibre.com', 'stackoverflow.com', 'wikipedia.org', 'archive.org',
    'spotify.com', 'facebook.com', 'instagram.com', 'openai.com', 'claude.ai',
    'chatgpt.com', 'gmail.com', 'duckduckgo.com', 'bing.com',
    'weather.com', 'distrowatch', 'nixos.org', 'matrix.org',
    'element.io', 'torbox.app', 'proton.me', 'kagi.com'
  ];
  var POP_TYPES = { click: 1, mousedown: 1, mouseup: 1, pointerdown: 1,
    touchstart: 1, auxclick: 1, dblclick: 1 };
  var POP_SRC = /window\.open|\.open\(\s*['"]?(about:blank|blob:|data:|https?:)|atob\s*\(|pop_?under|popunder|adsbytrafficjunky|zone_\d|tabunder|window\.top\.location/i;

  function popGuardOff() {
    for (var i = 0; i < POP_GUARD_SAFE.length; i++) {
      var d = POP_GUARD_SAFE[i];
      if (host === d || host.slice(-(d.length + 1)) === '.' + d) return true;
    }
    return false;
  }

  // uBO's popup defence: the popup target is checked against the network
  // host-block set (compiled from easylist adservers/popup/thirdparty +
  // adult adservers). window.open to any blocked host (or parent domain)
  // never opens a tab at all.
  var BLOCKED_HOSTS = null;
  function hostBlocked(h) {
    if (!BLOCKED_HOSTS) {
      BLOCKED_HOSTS = new Set(ADB.hosts.split('\n'));
    }
    if (BLOCKED_HOSTS.has(h)) return true;
    var parts = h.split('.');
    for (var i = 1; i < parts.length - 1; i++) {
      if (BLOCKED_HOSTS.has(parts.slice(i).join('.'))) return true;
    }
    return false;
  }

  // popunder entry domains rotate hourly, so host lists can't catch the
  // window.open target. the signal that never rotates: the open happens
  // synchronously inside a click that hit NON-INTERACTIVE page area. a
  // capture-phase tracker records that, and the wrapper denies cross-origin
  // opens riding empty-space clicks. same-host and allowlisted hosts are
  // never denied (oauth, share intents ride real buttons anyway).
  // the elements that legitimately open windows on press. video/audio/canvas
  // are deliberately ABSENT: no real player opens a cross-origin popup when
  // you press play — that press pattern is a popunder riding the player
  var INTERACTIVE_SEL = 'a,button,input,select,textarea,summary,details,label,' +
    '[role=\"button\"],[role=\"link\"],[role=\"tab\"],[role=\"menuitem\"],' +
    '[role=\"option\"],[role=\"switch\"],[role=\"checkbox\"],[role=\"radio\"],' +
    '[contenteditable=\"true\"],[tabindex]';
  var clickInteractive = true;
  try {
    var markInteractive = function (e) {
      clickInteractive = !!(e.target && e.target.closest && e.target.closest(INTERACTIVE_SEL));
    };
    // popunder handlers fire on pointerdown/mousedown, before click dispatch
    document.addEventListener('pointerdown', markInteractive, true);
    document.addEventListener('mousedown', markInteractive, true);
    document.addEventListener('click', markInteractive, true);
    document.addEventListener('auxclick', markInteractive, true);
  } catch (e) {}

  var origOpenGlobal = window.open;
  if (typeof origOpenGlobal === 'function') {
    window.open = function (url) {
      var u = String(url === undefined ? '' : url);
      if (!u || /^about:blank/i.test(u) || /^(blob|data):/i.test(u)) return null;
      try {
        var abs = new URL(u, location.href);
        if (hostBlocked(abs.hostname)) return null;
        if (abs.host !== location.host) {
          if (!popGuardOff() && !clickInteractive) return null; // empty-space popunder
          if (AD_SRC.test(abs.href)) return null;
        }
        if (AD_SRC.test(u)) return null;
      } catch (e) {}
      return origOpenGlobal.apply(window, arguments);
    };
  }

  if (!popGuardOff()) {
    try {
      var origAelPop = EventTarget.prototype.addEventListener;
      EventTarget.prototype.addEventListener = function (type, fn, opts) {
        try {
          if (POP_TYPES[type] && typeof fn === 'function' && POP_SRC.test(fn.toString())) {
            var self = this;
            var tName = self === window ? 'window'
              : (self === document ? 'document'
              : (self === document.documentElement ? 'documentElement'
              : (self === document.body ? 'body' : '')));
            if (tName) {
              return; // refuse: document-level popunder trap
            }
          }
        } catch (e) {}
        return origAelPop.call(this, type, fn, opts);
      };
    } catch (e) {}
  }

  // ------------------------------------------------- overlays / anti-adblock
  function killOverlays() {
    var nodes;
    try { nodes = document.querySelectorAll('div,section,aside,dialog'); } catch (e) { return; }
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.__qadb) continue;
      var s;
      try { s = getComputedStyle(el); } catch (e) { continue; }
      if (s.position !== 'fixed' && s.position !== 'sticky') continue;
      var r = el.getBoundingClientRect();
      if (r.width < innerWidth * 0.5 || r.height < innerHeight * 0.4) continue;
      var idc = (el.id || '') + ' ' + (typeof el.className === 'string' ? el.className : '');
      var txt = (el.textContent || '').slice(0, 400);
      var adWall = /adblock|ad blocker|ad-block|bloqueador de anuncios|desactiv[aá] (tu|el) (adblock|bloqueador)/i.test(txt);
      if (!adish(el) && !adWall) continue;
      if (el.querySelector('video')) continue;
      hide(el);
      try {
        document.documentElement.style.setProperty('overflow', 'auto', 'important');
        if (document.body) document.body.style.setProperty('overflow', 'auto', 'important');
      } catch (e) {}
    }
  }

  // ------------------------------------------------------------------- timing
  var passCount = 0;
  function pass() {
    passCount++;
    try { ensureCSS(); } catch (e) {}
    try { runProc(); } catch (e) {}
    try { sweepAdFrames(); } catch (e) {}
    try { sweepPromoStrips(); } catch (e) {}
    try { sweep(); } catch (e) {}
    try { killOverlays(); } catch (e) {}
    try {
      if (document.documentElement) {
        document.documentElement.setAttribute('data-qadb', String(passCount));
      }
    } catch (e) {}
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', pass);
  } else {
    pass();
  }
  window.addEventListener('load', pass);
  setTimeout(pass, 800);
  setTimeout(pass, 2500);

  var pending = false;
  try {
    new MutationObserver(function () {
      if (pending) return;
      pending = true;
      setTimeout(function () { pending = false; pass(); }, 400);
    }).observe(document.documentElement, { childList: true, subtree: true });
  } catch (e) {}
})();
