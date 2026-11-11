#!/usr/bin/env python3
"""qute-adblock bundle compiler.

reads pinned easylist + uBO uAssets checkouts and the engine template, emits:
  <out>/greasemonkey/qute-adblock.user.js   engine with spliced rule data

usage: compile.py --easylist DIR --uassets DIR --engine FILE --out DIR
"""
import argparse, collections, json, os, re, sys

EASYLIST_SOURCES = [
    "easylist/easylist_general_hide.txt",
    "easylist/easylist_specific_hide.txt",
    "easylist/easylist_specific_hide_abp.txt",
    "easylist/easylist_allowlist_general_hide.txt",
    "easylist_cookie/easylist_cookie_general_hide.txt",
    "easylist_cookie/easylist_cookie_specific_hide.txt",
    "easylist_cookie/easylist_cookie_specific_ABP.txt",
    "easylist_cookie/easylist_cookie_specific_uBO.txt",
    "easylist_cookie/easylist_cookie_international_specific_hide.txt",
    "easylist_cookie/easylist_cookie_allowlist_general_hide.txt",
    "fanboy-addon/fanboy_annoyance_general_hide.txt",
    "fanboy-addon/fanboy_annoyance_specific_hide.txt",
    "fanboy-addon/fanboy_annoyance_specific_ABP.txt",
    "fanboy-addon/fanboy_annoyance_specific_uBO.txt",
    "fanboy-addon/fanboy_annoyance_international.txt",
    "fanboy-addon/fanboy_annoyance_allowlist_general_hide.txt",
    "fanboy-addon/fanboy_social_general_hide.txt",
    "fanboy-addon/fanboy_social_specific_hide.txt",
    "fanboy-addon/fanboy_social_specific_ABP.txt",
    "fanboy-addon/fanboy_social_specific_uBO.txt",
    "fanboy-addon/fanboy_social_international.txt",
    "fanboy-addon/fanboy_social_allowlist_general_hide.txt",
    "fanboy-addon/fanboy_newsletter_general_hide.txt",
    "fanboy-addon/fanboy_newsletter_specific_hide.txt",
    "fanboy-addon/fanboy_newsletter_specific_ABP.txt",
    "fanboy-addon/fanboy_newsletter_specific_uBO.txt",
    "fanboy-addon/fanboy_newsletter_international_hide.txt",
    "fanboy-addon/fanboy_newsletter_allowlist_general_hide.txt",
    "fanboy-addon/fanboy_notifications_general_hide.txt",
    "fanboy-addon/fanboy_notifications_specific_hide.txt",
    "fanboy-addon/fanboy_notifications_specific_ABP.txt",
    "fanboy-addon/fanboy_notifications_specific_uBO.txt",
    "fanboy-addon/fanboy_notifications_allowlist_general_hide.txt",
    "fanboy-addon/fanboy_agegate_general_hide.txt",
    "fanboy-addon/fanboy_agegate_specific_hide.txt",
    "fanboy-addon/fanboy_agegate_specific_uBO.txt",
    "easylist_adult/adult_specific_hide.txt",
]

# host-block lists (||domain^ rules) — compiled into ADB.hosts for the
# popup defense: window.open to any blocked host is denied, exactly uBO's
# "popup url checked against network filters" behaviour
HOSTS_SOURCES = [
    "easylist/easylist_adservers.txt",
    "easylist/easylist_adservers_popup.txt",
    "easylist/easylist_thirdparty.txt",
    "easylist_adult/adult_adservers.txt",
    "easylist_adult/adult_adservers_popup.txt",
    "easylist_adult/adult_thirdparty.txt",
]

XFILES_SOURCES = [
    "filtri.txt",
]

ADFILT_SOURCES = [
    "AnnoyancesList",
    "AdRemovalListForUnusualAds.txt",
    "AnnoyancesList-2ndDivision.txt",
]

UASSETS_SOURCES = [
    "filters/filters.txt",
    "filters/filters-2024.txt",
    "filters/filters-2025.txt",
    "filters/filters-2026.txt",
    "filters/filters-general.txt",
    "filters/filters-mobile.txt",
    "filters/annoyances.txt",
    "filters/annoyances-cookies.txt",
    "filters/annoyances-others.txt",
    "filters/quick-fixes.txt",
    "filters/unbreak.txt",
    "filters/badware.txt",
    "filters/privacy.txt",
]

PROC_TOKENS = [
    ":has-text(", ":contains(", ":upward(", ":nth-ancestor(", ":xpath(",
    ":remove()", ":style(", ":matches-css(", ":matches-css-before(",
    ":matches-css-after(", ":matches-attr(", ":min-text-length(",
    ":watch-attr(", ":others(", ":if(", ":matches-path(", ":matches-prop(",
    ":shadow(", ":shadow-root", ":remove-attr(", ":remove-class(",
    ":-abp-has(", ":-abp-contains(", ":-abp-properties(", ":not(:has-text(",
]

DOMAIN_OK = re.compile(r"^[a-z0-9.*_-]+$")


def is_proc(sel):
    return any(t in sel for t in PROC_TOKENS)


def split_rule(line):
    line = line.strip()
    if not line or line.startswith("!") or line.startswith("["):
        return None
    m = re.match(r"^([^#]*)#@?#?\+js\((.*)\)\s*$", line)
    if m:
        kind = "scriptlet-unhide" if "#@#+js" in line else "scriptlet"
        return m.group(1), kind, m.group(2)
    m = re.match(r"^([^#]*)#%#//scriptlet\((.*)\)\s*$", line)
    if m:
        return m.group(1), "scriptlet", m.group(2)
    m = re.match(r"^([^#]*)#\$#(.*)$", line)
    if m:
        return m.group(1), "style", m.group(2)
    m = re.match(r"^([^#]*)#\?#(.*)$", line)
    if m:
        return m.group(1), "proc", m.group(2)
    m = re.match(r"^([^#]*)#@#(.*)$", line)
    if m:
        return m.group(1), "unhide", m.group(2)
    m = re.match(r"^([^#]*)##(.*)$", line)
    if m:
        doms, sel = m.group(1), m.group(2)
        return doms, ("proc" if is_proc(sel) else "hide"), sel
    return None


def parse_domains(s):
    pos, neg = [], []
    for d in s.split(","):
        d = d.strip().lower()
        if not d:
            continue
        if d.startswith("~"):
            neg.append(d[1:])
        else:
            pos.append(d)
    return pos, neg


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--easylist", required=True)
    ap.add_argument("--uassets", required=True)
    ap.add_argument("--xfiles", required=True)
    ap.add_argument("--adfilt", required=True)
    ap.add_argument("--engine", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    sources = [(os.path.join(args.easylist, p), p) for p in EASYLIST_SOURCES]
    sources += [(os.path.join(args.uassets, p), p) for p in UASSETS_SOURCES]
    sources += [(os.path.join(args.xfiles, p), p) for p in XFILES_SOURCES]
    sources += [(os.path.join(args.adfilt, p), p) for p in ADFILT_SOURCES]

    for path, name in sources:
        if not os.path.isfile(path):
            print(f"missing component: {name} ({path})", file=sys.stderr)
            sys.exit(1)

    generic, generic_exc = set(), set()
    dom_hide = collections.defaultdict(set)
    dom_exc = collections.defaultdict(set)
    generic_proc, dom_proc = set(), collections.defaultdict(set)
    generic_script, dom_script = set(), collections.defaultdict(set)
    counts = collections.Counter()

    for path, _name in sources:
        for raw in open(path, encoding="utf-8", errors="replace"):
            r = split_rule(raw)
            if not r:
                continue
            doms, kind, payload = r
            pos, neg = parse_domains(doms)
            bad = False
            for d in pos + neg:
                if re.fullmatch(r"[a-z0-9_-]+\.\*", d):
                    continue  # uBO entity domain (pornhub.*): keep, matched at runtime
                if "*" in d or not DOMAIN_OK.match(d):
                    bad = True
                    break
            if bad:
                counts["skip-wildcard-domain"] += 1
                continue
            payload = payload.strip()
            if not payload:
                continue
            if kind == "scriptlet":
                if pos:
                    for d in pos:
                        dom_script[d].add(payload)
                else:
                    generic_script.add(payload)
                counts["scriptlet"] += 1
                continue
            if kind in ("scriptlet-unhide", "style"):
                counts[kind] += 1
                continue
            if kind in ("hide", "proc"):
                if not pos:
                    (generic_proc if kind == "proc" else generic).add(payload)
                    for d in neg:
                        dom_exc[d].add(payload)
                else:
                    for d in pos:
                        (dom_proc[d] if kind == "proc" else dom_hide[d]).add(payload)
                    for d in neg:
                        dom_exc[d].add(payload)
                counts[kind] += 1
            elif kind == "unhide":
                if pos:
                    for d in pos:
                        dom_exc[d].add(payload)
                else:
                    generic_exc.add(payload)
                counts["unhide"] += 1

    hosts = set()
    host_re = re.compile(r"^\|\|([a-z0-9*._-]+)\^")
    for name in HOSTS_SOURCES:
        path = os.path.join(args.easylist, name)
        if not os.path.isfile(path):
            print(f"missing hosts component: {name}", file=sys.stderr)
            sys.exit(1)
        for raw in open(path, encoding="utf-8", errors="replace"):
            m = host_re.match(raw.strip())
            if m:
                hosts.add(m.group(1).lower())

    data = {
        "hosts": "\n".join(sorted(hosts)),
        "g": sorted(generic),
        "ge": sorted(generic_exc),
        "d": {k: sorted(v) for k, v in dom_hide.items()},
        "de": {k: sorted(v) for k, v in dom_exc.items()},
        "gp": sorted(generic_proc),
        "dp": {k: sorted(v) for k, v in dom_proc.items()},
        "gs": sorted(generic_script),
        "ds": {k: sorted(v) for k, v in dom_script.items()},
    }
    body = "var ADB=" + json.dumps(data, separators=(",", ":"), ensure_ascii=False) + ";\n"

    engine = open(args.engine, encoding="utf-8").read()
    if "//__DATA__" not in engine:
        print("engine template has no //__DATA__ marker", file=sys.stderr)
        sys.exit(1)
    out_js = engine.replace("//__DATA__", body.strip())

    outdir = os.path.join(args.out, "greasemonkey")
    os.makedirs(outdir, exist_ok=True)
    with open(os.path.join(outdir, "qute-adblock.user.js"), "w", encoding="utf-8") as f:
        f.write(out_js)

    stats = {
        "counts": dict(counts),
        "generic_selectors": len(data["g"]),
        "generic_exceptions": len(data["ge"]),
        "domains": len(data["d"]),
        "domain_selectors": sum(len(v) for v in data["d"].values()),
        "domain_proc": sum(len(v) for v in data["dp"].values()),
        "domain_scriptlets": sum(len(v) for v in data["ds"].values()),
        "blocked_hosts": len(hosts),
        "engine_bytes": len(out_js),
    }
    print(json.dumps(stats))


if __name__ == "__main__":
    main()