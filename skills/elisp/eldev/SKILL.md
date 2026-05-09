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

## Quick reference

| Command | Purpose |
|---|---|
| `eldev deps` / `eldev dtree` | List dependencies / tree |
| `eldev upgrade` | Upgrade deps |
| `eldev upgrade-self` | Upgrade Eldev |
| `eldev lint` / `eldev doctor` | Lint / check health |

Troubleshooting: `-t` / `--trace` shows what Eldev does; `-d` / `--debug` shows stacktraces. `-X` / `--external` uses preinstalled deps (skip isolation).

