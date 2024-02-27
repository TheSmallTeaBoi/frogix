{inputs, outputs, ...}:
{
  xdg.configFile."/home/theo/.xprofile".text = ''
  exec awesome &
  exec /home/theo/.config/polybar/launch.sh &
  exec picom &
  exec sxhkd &
  exec xset r rate 180 70 &
  exec kmonad /home/theo/git/keys/keys.kbd &
  exec nicotine -ds
  '';
}

