{
  config,
  lib,
  ...
}:
let
  cfg = config.frogix.beets;
in
{
  options.frogix."beets".enable = lib.mkOption {
    type = lib.types.bool;
    default = config.frogix.enable;
    description = "beets music tagger config";
  };

  options.frogix.beets.libraryDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/Music";
    description = "beets library directory";
  };
  options.frogix.beets.convertDest = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/Music-lossy";
    description = "beets convert plugin destination";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."beets/config.yaml".text =
      # yaml
      ''
        plugins: convert duplicates rewrite badfiles embedart fetchart lastgenre deezer discogs spotify musicbrainz lyrics export missing edit mbsync inline chroma autobpm fromfilename
        directory: ${cfg.libraryDir}
        import:
          move: yes
          duplicate_action: merge
          write: yes
        convert:
          dest: ${cfg.convertDest}
          never_convert_lossy_files: yes
          format: opus
          formats:
            opus: ffmpeg -i $source -y -vn -acodec libopus -ab 192k $dest
        rewrite:
          artist CapaRezza: Caparezza
        embedart:
          remove_art_file: yes
        lastgenre:
          force: yes
          keep_existing: yes
          whitelist: ${config.home.homeDirectory}/.config/beets/genres.txt
          count: 5
          fallback: Unknown
        lyrics:
          force: yes
          synced: yes
        duplicates:
          keys: acoustid_fingerprint
        fetchart:
          auto: yes
        embedart:
          auto: yes
          remove_art_file: yes
        chroma:
          auto: no
      '';

    xdg.configFile."beets/genres.txt".source = ./genres.txt;
  };
}
