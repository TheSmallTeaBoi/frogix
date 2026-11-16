# `frogix.*` options

The full option reference, **generated from the live option tree** — this is
what the modules declare, not a hand-maintained copy, so it cannot drift from
the code.

Every `enable` defaults to `frogix.enable`, so a host that sets only
`frogix.enable = true` gets the whole suite; everything below can be
overridden per host. Values shown are the **universal defaults** —
ratholomew overrides many of them (see [hosts.md](hosts.md)).

Options are listed alphabetically and split by tree: system modules first,
home-manager modules second (the latter are set under
`home-manager.users.<user>.frogix.*`).

After touching a module's options, regenerate this page (module prose lives
in the option descriptions, not here):

```bash
nix eval --raw .#docs.optionsMd > docs/options.md
```
