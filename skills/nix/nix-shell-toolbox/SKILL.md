---
name: nix-shell-toolbox
description: >
  Run temporary/ad-hoc binaries on NixOS using nix-shell -p and patchelf. Use
  when a prebuilt binary won't run on NixOS, or when you need a tool
  ephemerally without permanent installation.
---

# Nix Shell Toolbox

## Ephemeral tools with nix-shell -p

Run any package temporarily without installing it:

```sh
nix-shell -p <pkg> --run '<command>'
```

The package is available only for that command — no profile pollution, no garbage to clean up.

Examples:

```sh
nix-shell -p patchelf --run 'patchelf --set-interpreter <path> ~/.local/bin/<binary>'
nix-shell -p jq --run 'jq . < file.json'
nix-shell -p ripgrep --run 'rg pattern'
```

This works for any package on nixpkgs.

## Patching ELF interpreters for NixOS

NixOS does not follow the FHS convention — there is no `/lib64/` directory. Prebuilt Linux binaries with the standard dynamic linker hardcoded (`/lib64/ld-linux-x86-64.so.2`) will fail with:

```
Could not start dynamically linked executable: <binary>
NixOS cannot run dynamically linked executables intended for generic
linux environments out of the box.
```

To make them work, patch the ELF interpreter with `patchelf`:

```sh
# Run patchelf ephemerally
nix-shell -p patchelf --run \
  'patchelf --set-interpreter /nix/store/<hash>-glibc-<version>/lib64/ld-linux-x86-64.so.2 ~/.local/bin/<binary>'
```

Find the correct glibc store path via `ldd`:

```sh
ldd ~/.local/bin/<binary>
# look for the line resolving /lib64/ld-linux-x86-64.so.2
```

The patched path is pinned to a specific glibc derivation. If that store path is garbage collected (`nix-store --gc` or system upgrade), the binary breaks and must be re-patched against the current glibc.

## PATH precedence for local binaries

- To ensure `$HOME/.local/bin` binaries take precedence over nixpkgs versions:

```sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

