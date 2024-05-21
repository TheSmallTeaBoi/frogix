{
  inputs,
  outputs,
  pkgs,
  config,
  ...
}: {
  xdg.configFile."/home/theo/.config/iamb/config.toml".text = ''
    [profiles.user]
    user_id = "@thesmallteaboi:matrix.org"
  '';
}
