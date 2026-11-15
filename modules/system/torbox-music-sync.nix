{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.frogix."torbox-music-sync";
  musicDir = cfg.musicDir;
  inboxDir = "${musicDir}/_inbox";
  stateDir = "/var/lib/torbox-music-sync";
  rcloneConf = "/run/rclone-torbox/rclone.conf";
  torboxPath = cfg.remotePath;

  # Nebula (eclipse's TorBox addon) caches FULL ALBUMS, one folder each, and
  # the files carry no embedded tags either. Metadata lives in the shape:
  #   folder: "<artist> - <album> (<year>) [FLAC ...]"
  #   track:  "NN - <title>.flac"
  # Derive tags from that so beets has something to match/place by. This
  # seeds the autotagger (album mode matches the release) and is the fallback
  # identity for albums MusicBrainz doesn't know. mutagen writes the tags.
  tagger = pkgs.writeScript "nbtagger" ''
    #!${pkgs.python3.withPackages (ps: [ ps.mutagen ])}/bin/python3
    import os
    import re
    import sys

    from mutagen import File as MFile

    ALBUM = re.compile(r'^(?P<artist>.+?) - (?P<album>.+) \((?P<year>\d{4})\)(?: \[[^\]]*\])?$')
    TRACK = re.compile(r'^(?P<track>\d+)\s*-\s*(?P<title>.+)$')


    def main(root):
        for dp, _, files in os.walk(root):
            folder = os.path.basename(dp)
            am = ALBUM.match(folder)
            for fn in files:
                stem, _ = os.path.splitext(fn)
                tm = TRACK.match(stem)
                path = os.path.join(dp, fn)
                audio = MFile(path, easy=True)
                if audio is None:
                    print('unreadable (left as-is):', fn)
                    continue
                if am:
                    audio['albumartist'] = am.group('artist')
                    audio['artist'] = am.group('artist')
                    audio['album'] = am.group('album')
                    audio['date'] = am.group('year')
                if tm:
                    audio['tracknumber'] = tm.group('track')
                    audio['title'] = tm.group('title')
                elif not am:
                    print('no-shape (left as-is):', fn)
                    continue
                audio.save()
                a = am.group('artist') if am else '-'
                b = am.group('album') if am else folder
                t = tm.group('title') if tm else stem
                print('tagged:', a, '/', b, '/', t)


    if __name__ == '__main__':
        main(sys.argv[1])
  '';

  # Only pulls genuinely NEW files each week: lists the torbox nebula remote
  # (audio only — the .nfo sidecars are dropped), diffs against a seen-list,
  # downloads only the diff, derives tags from the folder/filename shape,
  # imports via beets using the host user's beets config in ALBUM mode (so the same
  # plugins — fetchart, lastgenre, lyrics — fire and the path format matches
  # the rest of the library), then marks the batch seen.
  # `--quiet-fallback asis` overrides his config's default `skip` so albums
  # MusicBrainz doesn't know import with the derived tags instead of
  # vanishing. If any step exits non-zero the seen-list isn't updated, so the
  # batch retries next week.
  syncScript = pkgs.writeShellScript "torbox-music-sync" ''
    set -euo pipefail
    inbox="${inboxDir}"
    remote="torbox:${torboxPath}/"
    seen="${stateDir}/seen.txt"
    conf="${rcloneConf}"

    tmp_remote=$(mktemp)
    tmp_new=$(mktemp)
    trap 'rm -f "$tmp_remote" "$tmp_new"' EXIT

    mkdir -p "$inbox" "$(dirname "$seen")"
    touch "$seen"

    echo "=== listing remote files ==="
    ${pkgs.rclone}/bin/rclone lsf "$remote" \
      --config "$conf" --recursive --files-only \
      | grep -iE '\.(flac|mp3|m4a|opus|ogg|wav)$' > "$tmp_remote" || true

    echo "=== diffing against seen-list ==="
    sort "$tmp_remote" -o "$tmp_remote"
    sort "$seen" -o "$seen"
    comm -23 "$tmp_remote" "$seen" > "$tmp_new"

    count=$(wc -l < "$tmp_new")
    if [ "$count" -eq 0 ]; then
      echo "no new files since last sync"
      exit 0
    fi

    echo "=== $count new file(s) to sync ==="

    ${pkgs.rclone}/bin/rclone copy "$remote" "$inbox/" \
      --config "$conf" \
      --files-from "$tmp_new" \
      --transfers 4 \
      --checkers 8 \
      --contimeout 30s \
      --timeout 300s \
      --retries 3 \
      --stats 30s

    echo "=== tagging from folder/filename shape ==="
    ${tagger} "$inbox"

    echo "=== beets import (user config, album mode, autotag, asis fallback) ==="
    ${pkgs.beets}/bin/beet import -q --quiet-fallback asis "$inbox"

    cat "$tmp_new" >> "$seen"
    find "$inbox" -mindepth 1 -delete

    echo "=== sync complete: $count file(s) processed ==="
  '';
in
{
  options.frogix."torbox-music-sync" = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "weekly TorBox -> beets music sync";
    };
    musicDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${config.frogix.user}/Music";
      description = "beets library root the sync imports into";
    };
    remotePath = lib.mkOption {
      type = lib.types.str;
      default = "nebula";
      description = "path inside the torbox remote to sync from";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.torbox-music-sync = {
      description = "TorBox -> beets weekly music sync";
      after = [
        "torbox-webdav.service"
        "network-online.target"
      ];
      wants = [
        "torbox-webdav.service"
        "network-online.target"
      ];
      serviceConfig = {
        Type = "oneshot";
        User = config.frogix.user;
        Group = "users";
        ExecStart = syncScript;
        StateDirectory = "torbox-music-sync";
        # autotagging + lastgenre + lyrics are network-bound and rate-limited,
        # so a big batch can outrun the default start timeout — give it room.
        TimeoutStartSec = "30min";
        Nice = 10;
        IOSchedulingClass = "idle";
      };
    };

    systemd.timers.torbox-music-sync = {
      description = "Weekly TorBox music sync (Mon 04:00)";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "Mon 04:00";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
