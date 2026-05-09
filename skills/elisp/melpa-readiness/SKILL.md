---
name: melpa-readiness
description: >
  Prepare an Emacs Lisp package for MELPA submission — source file
  conventions, code style, and submission checklist. Use when user wants to
  submit a package to MELPA or asks about MELPA requirements.
---

# MELPA Readiness

## Source files

- `Package-Requires` only in main file (sub-files: remove entirely)
- Header order: `;; Author:` block above license boilerplate
- SPDX-License-Identifier in every `.el` file (e.g. `;; SPDX-License-Identifier: GPL-3.0-or-later`)
- `;;; Commentary` has real content (not a stub), ≤80 chars
- `;; Author: Name <email>` format
- `LICENSE` file in repo root (standard format, detectable by licensee)

## Code

- Sharp-quote: `#'` everywhere — `mapc #'func`, `defalias 'name #'func`
- No `with-no-warnings` — use `declare-function` for optional deps
- `defcustom` type: `'(repeat string)` not `'list`
- No docstring wider than 80 chars
- No unused lexical arguments

## Submission checklist

- [ ] Public repo for ≥1 month
- [ ] If LLMs generated code: `Assisted-by:` line in headers per CONTRIBUTING.org
- [ ] `eldev lint` clean (checkdoc + package-lint + relint)
- [ ] `eldev -c test` clean (byte-compile + tests)
- [ ] Recipe: `:fetcher` before `:repo`

