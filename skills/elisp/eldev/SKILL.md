---
name: eldev
description: >
  Configure and build Elisp projects using Eldev. Manage dependencies from
  package archives, Git repos, and local sources. Run tests with ERT,
  byte-compile projects, launch interactive Emacs sessions with project
  context, and manage loading modes. Use when user mentions eldev, an Eldev
  file, or an Elisp project with dependencies.
---

# Eldev

## Quick start

- `eldev init` — create `Eldev` file
- `Eldev` = project config (Elisp, version-controlled)
- `Eldev-local` = user-local overrides (not version-controlled; add to `.gitignore`)
- `eldev help` / `eldev help COMMAND` — built-in docs

## Project setup

Default: use MELPA only. In `Eldev`:

```elisp
(eldev-use-package-archive 'melpa)
```

VC repositories:

```elisp
(eldev-use-vc-repository 'dep-name :github "USER/REPO")
```

Local sources (in `Eldev-local` only):

```elisp
(eldev-use-local-sources "~/path/to/dep")
```

Extra deps for specific commands:

```elisp
(eldev-add-extra-dependencies 'test 'some-package)
(eldev-add-extra-dependencies 'emacs 'evil)
```

## Testing (ERT)

```sh
eldev test              # all tests
eldev test my-test      # specific test by name
eldev -p test           # test as installed package
```

## Interactive Emacs

```sh
eldev emacs             # clean session with project
eldev emacs -nw         # terminal mode
eldev eval "(foo 42)"   # quick eval
```

### Running with evil

In `Eldev-local`:

```elisp
(eldev-add-extra-dependencies 'emacs 'evil)

(add-hook 'after-init-hook
          (lambda () (require 'evil) (evil-mode 1)))
```

Then `eldev emacs -nw`.

## Loading modes

- `-p` / `--packaged` = build + install as package (closest to user install).
- `-c` / `--byte-compiled` = compile all files first.
- `-o` / `--compiled-on-demand` = compile only when loaded (large projects).

## MELPA readiness

### Source files

- `Package-Requires` only in main file (sub-files: remove entirely)
- Header order: `;; Author:` block above license boilerplate
- SPDX-License-Identifier in every `.el` file (e.g. `;; SPDX-License-Identifier: GPL-3.0-or-later`)
- `;;; Commentary` has real content (not a stub), ≤80 chars
- `;; Author: Name <email>` format
- `LICENSE` file in repo root (standard format, detectable by licensee)

### Code

- Sharp-quote: `#'` everywhere — `mapc #'func`, `defalias 'name #'func`
- No `with-no-warnings` — use `declare-function` for optional deps
- `defcustom` type: `'(repeat string)` not `'list`
- No docstring wider than 80 chars
- No unused lexical arguments

### Submission checklist

- [ ] Public repo for ≥1 month
- [ ] If LLMs generated code: `Assisted-by:` line in headers per CONTRIBUTING.org
- [ ] `eldev lint` clean (checkdoc + package-lint + relint)
- [ ] `eldev -c test` clean (byte-compile + tests)
- [ ] Recipe: `:fetcher` before `:repo`

## Nix shell

```sh
nix-shell --run "eldev test"
nix develop -c eldev test
```

### Getting older Emacs versions

The current `nixos-unstable` channel only ships `emacs` (latest, e.g. 30.2) and `emacs30`. Older majors (`emacs28`, `emacs29`) are removed once they fall out of nixpkgs's active set. To get them, pin a revision:

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

For a reproducible pin (`fetchTarball` follows the branch tip, so the hash drifts):

```nix
let
  pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/<commit-sha>.tar.gz";
    sha256 = "<nix-prefetch-url-output>";
  }) {};
in pkgs.emacs29
```

Get `sha256`:

```sh
nix-prefetch-url --unpack https://github.com/NixOS/nixpkgs/archive/<commit-sha>.tar.gz
```

Headless variants (faster builds, enough for `--batch`):

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

Both land on `PATH`; disambiguate by full path or by `EMACS=`.

## Targeting a specific Emacs binary

Eldev picks the Emacs to run from the `EMACS` (or `ELDEV_EMACS`) environment variable, falling back to `emacs` on `PATH`. Set it inline — no shell pollution:

```sh
EMACS=/path/to/emacs eldev test
```

Combined with a Nix store path:

```sh
EMACS=/nix/store/83arrrf333lc4qwnzjgvwqhwvy4n9ksm-emacs-29.4/bin/emacs eldev test
```

Compare two versions side by side:

```sh
EMACS=/nix/store/.../bin/emacs eldev test 2>&1 | tail -5
echo "=== default ==="
eldev test 2>&1 | tail -5
```

### Probing internals via a temp file

For ad-hoc debugging — write a small Elisp probe to /tmp and load it with `eldev emacs --batch`:

```sh
cat > /tmp/probe.el <<'EOF'
;; your probing code here
(message "hello from %s" emacs-version)
EOF

EMACS=/path/to/emacs eldev emacs --batch -l /tmp/probe.el
```

- `'EOF'` (quoted marker) prevents shell expansion.
- `EMACS=...` targets a specific version without touching shell state.
- `eldev emacs` loads the project and all deps on `load-path`.
- `--batch`: headless, exits when done, output to stdout.
- `-l /tmp/probe.el` loads the file as the last init step.

For one-liners, `--eval '(form)'` works but nested quotes get painful. Multi-line → heredoc.

### Pitfalls

- ****Smart quotes.**** Elisp only recognises straight `'` (apostrophe). No `´` or typographic quotes.
- ****Cleanup.**** `rm /tmp/probe*.el` when done.
- ****Env vs Eldev form.**** `EMACS=path eldev …` sets the binary; `eldev --setup '(setq …)'` sets Eldev options. Different mechanisms.

## Quick reference

| Command | Purpose |
|---|---|
| `eldev deps` / `eldev dtree` | List dependencies / tree |
| `eldev upgrade` | Upgrade deps |
| `eldev upgrade-self` | Upgrade Eldev |
| `eldev lint` / `eldev doctor` | Lint / check health |

Troubleshooting: `-t` / `--trace` shows what Eldev does; `-d` / `--debug` shows stacktraces. `-X` / `--external` uses preinstalled deps (skip isolation).

