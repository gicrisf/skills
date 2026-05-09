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

;; Visit the file first to initialise org-element cache
(find-file "SKILLS.org")
(ox-skills-export-wim-to-md t)

(provide 'export-skills)

;;; export-skills.el ends here
