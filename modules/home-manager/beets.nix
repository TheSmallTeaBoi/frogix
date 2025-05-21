{...}: {
  xdg.configFile."beets/config.yaml".text = ''
    plugins: convert duplicates rewrite badfiles embedart fetchart
    directory: /home/theo/Data/Music/
    convert:
      dest: /home/theo/Data/music-lossier/
      format: opus
      formats:
        opus: ffmpeg -i $source -y -vn -acodec libopus -ab 192k $dest
    rewrite:
      artist CaparaRezza: Caparezza
    embedart:
      remove_art_file: yes
  '';
}
