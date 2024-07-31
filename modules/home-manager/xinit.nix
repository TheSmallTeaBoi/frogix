{...}: {
  xdg.configFile."/home/theo/.xprofile".text =
    #bash
    ''
      exec nvidia-settings --assign CurrentMetaMode="HDMI-0: nvidia-auto-select @960x1707 +0+0 {rotation=right, viewportin=960x1706, AllowGSYNC=Off}, DP-3: nvidia-auto-select +960+626" &
      exec kmonad /home/theo/git/keys/keys.kbd &
      exec picom &
      exec sxhkd &
      # There's probably a better way of doing this but /shrug
      exec bash -c "sleep 3; awesome" &
      exec xset r rate 180 70 &
      exec nicotine -s
    '';
}
