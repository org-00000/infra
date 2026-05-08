;;; .dir-locals.el -*- lexical-binding: t; no-byte-compile: t -*-
((org-mode
   (fill-column . 85)
   (org-confirm-babel-evaluate . nil)
   (eval . (add-hook 'before-save-hook #'whitespace-cleanup nil t))
   (eval . (add-hook 'after-save-hook #'lar-reload nil t)))
  (elixir-mode
    (eval . (setq-local eglot-workspace-configuration
              `(:elixirLS (:projectDir ,(or (getenv "BACKEND")
                                          (error "BACKEND env var is not set"))))))))
