{config, ...}: {
  xdg.configFile."iamb/config.toml".text = ''
    [profiles.user]
    user_id = "@thesmallteaboi:matrix.org"

    [settings.notifications]
    enabled = true
    via = "bell"

    [settings]
    username_display = "displayname"

    [dirs]
    downloads = '${config.home.homeDirectory}/Unorganized/iamb/'
  '';
}
