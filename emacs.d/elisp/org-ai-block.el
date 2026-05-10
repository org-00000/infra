;;; org-ai-block.el --- Font-lock support for #+begin_ai blocks -*- lexical-binding: t; -*-
;; [[ref:4a1f8c2e-7b3d-4e9a-b5f0-2c6d8e1a4b7f][Specification: doc/pseudo-language.org]]

(defface org-ai-block-delimiter
  '((t :inherit org-block-begin-line :slant italic))
  "Face for #+begin_ai / #+end_ai delimiter lines in Org buffers.")

(with-eval-after-load 'org
  (font-lock-add-keywords
   'org-mode
   '(("^[ \t]*#\\+\\(begin_ai\\|end_ai\\)\\b.*$"
      0 'org-ai-block-delimiter prepend))
   'append))

(provide 'org-ai-block)
;;; org-ai-block.el ends here
