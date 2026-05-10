;;; export-skills.el --- Export all skills from SKILLS.org  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Giovanni Crisalfi
;; Version: 1.0.0
;; Package-Requires: ((emacs "27.2") (ox-skills "0.1.0"))
;; Keywords: tools, org, skills, wp

;;; Commentary:
;;
;; Usage:
;;   eldev emacs --batch -l export-skills.el
;;
;; Or via Nix:
;;   nix-shell --run "eldev emacs --batch -l export-skills.el"

;;; Code:

(require 'ox-skills)

;; Guard: Eldev loads this file twice (require + -l), so skip on re-entry
(unless (boundp 'export-skills--done)
  (setq export-skills--done t)
  (dolist (file '("SKILLS.org" "REACT-SKILLS.org"))
    (when (file-exists-p file)
      (find-file file)
      (ox-skills-export-wim-to-md t))))

(provide 'export-skills)

;;; export-skills.el ends here
