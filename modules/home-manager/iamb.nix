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

    [settings.notifications]
    enabled = true
    via = "bell"

    [settings]
    username_display = "displayname"

    [dirs]
    downloads = '/home/theo/Data/Unorganized/iamb/'
  '';
}
