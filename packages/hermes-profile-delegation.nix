{ lib, stdenvNoCC, fetchFromGitHub }:
# Directory-based Hermes plugin: the derivation root must contain
# plugin.yaml + __init__.py, so we expose profile_delegation/ at $out.
# Upstream: https://github.com/LegendEvent/hermes-profile-delegation
stdenvNoCC.mkDerivation {
  name = "profile-delegation";
  src = fetchFromGitHub {
    owner = "LegendEvent";
    repo = "hermes-profile-delegation";
    rev = "a2560240d17fa4dcb388770d7dbc15dd31ac5be1";
    hash = "sha256-72rFvhY8BXKLHBpA8J9kSoLp5+Tma9Bzn94WvWMLRWE=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    cp -r $src/profile_delegation/* $out/
  '';

  meta = with lib; {
    description = "Cross-profile subagent delegation for hermes-agent";
    homepage = "https://github.com/LegendEvent/hermes-profile-delegation";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
