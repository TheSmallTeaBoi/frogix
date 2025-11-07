{...}: {
  xdg.configFile."beets/config.yaml".text =
    # yaml
    ''
      plugins: convert duplicates rewrite badfiles embedart fetchart lastgenre deezer discogs spotify musicbrainz lyrics export missing edit mbsync inline chroma autobpm fromfilename
      directory: /home/theo/Data/Music/
      import:
        move: yes
        duplicate_action: merge
        write: yes
      convert:
        dest: /home/theo/Data/music-lossier/
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
        whitelist: /home/theo/.config/beets/genres.txt
        count: 5
        fallback: Unknown
      lyrics:
        force: yes
        synced: yes
      duplicates:
        keys: acoustid_fingerprint
      fetchart:
        auto: yes
        sources: filesystem coverart itunes amazon albumart wikipedia fanarttv
      embedart:
        auto: yes
        remove_art_file: yes
      chroma:
        auto: no
    '';

  xdg.configFile."beets/genres.txt".source = ./genres.txt;
}
