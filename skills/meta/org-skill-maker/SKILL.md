---
name: org-skill-maker
description: >
  Create and maintain agent skills using Org-mode as the source format. Add
  entries to SKILLS.org with EXPORT_SKILL_* properties, then export to
  markdown. Use when user wants to create, write, or build a new skill in an
  Org-mode-based skills repo.
---

# Org Skill Maker

## Process

1. ****Gather requirements**** — ask user about:
    - What task/domain does the skill cover?
    - What specific use cases should it handle?
    - Does it need executable scripts or just instructions?
    - Any reference materials to include?

2. ****Draft the skill**** — add an entry in `SKILLS.org`:
    - Create a `* Category` heading with `:EXPORT_SKILL_SUBDIR:` property for grouping
    - Create a `** Skill Name` heading under it with `:EXPORT_SKILL_NAME:` and `:EXPORT_SKILL_DESCRIPTION:` properties
    - Write instructions under `***` subsections

3. ****Export**** — generate `skills/<subdir>/<name>/SKILL.md`:
    - Interactively: `M-x ox-skills-export-wim-to-md` (`C-c C-e s a` / `SPC m e s a`)
    - Batch: `eldev emacs --batch -l export-skills.el` (needs `Eldev` file — see Export workflow)

4. ****Review with user**** — present draft and ask:
    - Does this cover your use cases?
    - Anything missing or unclear?
    - Should any section be more/less detailed?

## Skill Structure

Source (`SKILLS.org`):

```org
#+SKILL_BASE_DIR: skills
* Category                                  # :EXPORT_SKILL_SUBDIR: category
** Skill Name                               # :EXPORT_SKILL_NAME: skill-name
                                             # :EXPORT_SKILL_DESCRIPTION: Brief description.
*** Quick start
...
```

Generated (`skills/`):

```
category/skill-name/
├── SKILL.md           # Main instructions (generated)
├── REFERENCE.md       # Detailed docs (if needed)
├── EXAMPLES.md        # Usage examples (if needed)
└── scripts/           # Utility scripts (if needed)
    └── helper.js
```

## Template

In `SKILLS.org`, a skill entry follows this pattern. The YAML frontmatter is auto-generated from `EXPORT_SKILL_*` properties — do not write it manually.

```org
** Skill Name                               # :EXPORT_SKILL_NAME: skill-name
                                              # :EXPORT_SKILL_DESCRIPTION: Brief description.

*** Quick start

 [Minimal working example]

*** Workflows

 [Step-by-step processes with checklists for complex tasks]

*** Advanced features

 [Link to separate files: See REFERENCE.md]
```

### Org properties reference

| Property | Used on | Purpose |
|---|---|---|
| `#+SKILL_BASE_DIR` | top | Sets output root (e.g. `skills`) |
| `:EXPORT_SKILL_SUBDIR:` | `*` | Subdirectory name under `SKILL_BASE_DIR`  (e.g. `meta`, `elisp`) |
| `:EXPORT_SKILL_NAME:` | `**` | Skill directory name + `name:` in generated YAML |
| `:EXPORT_SKILL_DESCRIPTION:` | `**` | `description:` in generated YAML — triggers agent loading |

### Special org elements

- `#+begin_export md` … `#+end_export` — raw markdown pass-through (for content that doesn't convert cleanly).
- Headings below `***` become `##` or `###` in the markdown output (depending on depth).
- Org `#+begin_src` blocks become fenced code blocks.
- Org tables convert to pipe tables.
- Hand-written `.md` files in `skills/` are left untouched — you can mix exported and manual skills freely.

## Description Requirements

The description is **the only thing your agent sees** when deciding which skill to load. It's surfaced in the system prompt alongside all other installed skills. Your agent reads these descriptions and picks the relevant skill based on the user's request.

**Goal**: Give your agent just enough info to know:

1. What capability this skill provides
2. When/why to trigger it (specific keywords, contexts, file types)

**Format**:

- Max 1024 chars
- Write in third person
- First sentence: what it does
- Second sentence: "Use when [specific triggers]"

**Good example**:

```
Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when user mentions PDFs, forms, or document extraction.
```

**Bad example**:

```
Helps with documents.
```

## When to Add Scripts

Add utility scripts when:

- Operation is deterministic (validation, formatting)
- Same code would be generated repeatedly
- Errors need explicit handling

Scripts save tokens and improve reliability vs generated code.

## When to Split Files

Split content when:

- `SKILLS.org` section exceeds 200 lines
- Generated `SKILL.md` exceeds 100 lines
- Content has distinct domains
- Advanced features are rarely needed

Extract detailed sections into `REFERENCE.md` and link to it from the main skill.

## Export workflow

`SKILLS.org` is the single source of truth; `skills/` is generated output. Re-run export after every edit.

### Interactively (Emacs)

```
M-x ox-skills-export-wim-to-md
# or: C-c C-e s a  (default bindings)
# or: SPC m e s a  (evil/spacemacs)
```

### Batch (Eldev + export-skills.el)

The repo provides `export-skills.el` and an `Eldev` file that handles dependency management (fetches `ox-skills` from GitHub automatically).

```sh
eldev emacs --batch -l export-skills.el
```

With Nix (if `eldev` is not on `PATH`):

```sh
nix-shell --run "eldev emacs --batch -l export-skills.el"
```

The `Eldev` file declares ox-skills as a VC dependency from `gicrisf/ox-skills` and uses the `gnu` archive. No manual setup needed.

## Review Checklist

After drafting, verify:

- [ ] `:EXPORT_SKILL_SUBDIR:` set on top-level (`*`) headings
- [ ] `:EXPORT_SKILL_NAME:` and `:EXPORT_SKILL_DESCRIPTION:` set on each skill (`**`)
- [ ] `EXPORT_SKILL_DESCRIPTION` includes triggers ("Use when...")
- [ ] Generated `SKILL.md` under 100 lines (extract to `REFERENCE.md` if over)
- [ ] No time-sensitive info
- [ ] Consistent terminology
- [ ] Concrete examples included
- [ ] References one level deep
- [ ] Run export and verify the generated output looks correct

