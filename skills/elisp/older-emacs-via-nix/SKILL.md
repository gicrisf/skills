---
name: older-emacs-via-nix
description: >
  Pin nixpkgs revisions to build and use older Emacs versions (27, 28, 29) for
  testing eldev projects. Use when user needs an older Emacs for testing, or
  mentions emacs27/28/29 and nix.
---

# Older Emacs via Nix

The current `nixos-unstable` channel only ships `emacs` (the latest, e.g. 30.2) and `emacs30`. Older majors (`emacs28`, `emacs29`) are removed once they fall out of nixpkgs's active set. To get them, pin a revision:

| Want | nixpkgs branch | Version shipped |
|---|---|---|
| Emacs 29 | `nixos-24.05` | 29.4 |
| Emacs 28 | `nixos-23.11` | 28.2 |
| Emacs 27 | `nixos-22.05` | 27.2 |

One-shot build — write a tiny `.nix` expression to /tmp and `nix-build` it:

```sh
cat > /tmp/emacs29.nix <<'EOF'
let
  pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
  }) {};
in pkgs.emacs29
EOF

nix-build /tmp/emacs29.nix --no-out-link
```

`nix-build` prints the store path (e.g. `/nix/store/...-emacs-29.4`). The binary is at `<store-path>/bin/emacs`. Omit `--no-out-link` to register a GC root.

For a reproducible pin (`fetchTarball` follows the branch tip, so the hash drifts over time):

```nix
let
  pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/<commit-sha>.tar.gz";
    sha256 = "<nix-prefetch-url-output>";
  }) {};
in pkgs.emacs29
```

Get the `sha256`:

```sh
nix-prefetch-url --unpack https://github.com/NixOS/nixpkgs/archive/<commit-sha>.tar.gz
```

Headless variants (substitute the attribute name, faster builds for `--batch`):

- `pkgs.emacs29-nox` — no X/GTK
- `pkgs.emacs29-gtk3` / `pkgs.emacs29-pgtk`

Add to `shell.nix` for multiple Emacs versions together:

```nix
{ pkgs ? import <nixpkgs> {} }:

let
  oldPkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
  }) {};
in
pkgs.mkShell {
  buildInputs = [ pkgs.emacs oldPkgs.emacs29 /* eldev, etc. */ ];
}
```

Both land on `PATH`; disambiguate by full path or by `EMACS=` (see the `eldev` skill's *Targeting a specific Emacs binary* section).

