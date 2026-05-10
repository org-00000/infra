;;; pseudo-language.el --- Org Mode support for pseudo-language source blocks -*- lexical-binding: t; -*-
;; [[ref:4a1f8c2e-7b3d-4e9a-b5f0-2c6d8e1a4b7f][Specification: doc/pseudo-language.org]]
;; [[id:2c0bf03a-0099-45e8-b773-bc96e309f24b]]

(define-derived-mode pseudo-mode org-mode "Pseudo"
  "Major mode for #+begin_src pseudo blocks (see doc/pseudo-language.org).
Content is displayed verbatim with no syntax highlighting,
matching the behaviour of #+begin_example blocks.")

(with-eval-after-load 'org-src
  (add-to-list 'org-src-lang-modes '("pseudo" . pseudo)))

(provide 'pseudo-language)
;;; pseudo-language.el ends here
