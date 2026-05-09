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

## Nix shell

```sh
nix-shell --run "eldev test"
nix develop -c eldev test
```

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

