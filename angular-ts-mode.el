;;; angular-ts-mode.el --- Tree-sitter support for Angular templates  -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Meqeq

;; Author     : Meqeq
;; Maintainer : Meqeq
;; Created    : December 2024
;; Keywords   : angular tree-sitter

;; This file is NOT part of GNU Emacs.

;;; Commentary:
;;
;; Major mode for angular html templates with a tree-sitter support.

;;; Code:

(require 'treesit)
(require 'sgml-mode)

(defvar angular-ts-font-lock-rules
  '(;; Angular font locking rules
   :language angular
   :feature comment
   ((comment) @font-lock-comment-face)

   :language angular
   :feature keyword
   ((["doctype" "@" (control_keyword) (special_keyword) (icu_category)] @font-lock-keyword-face)
    (structural_assignment operator: (identifier) @font-lock-keyword-face))

   :language angular
   :feature definition
   ((tag_name) @font-lock-function-name-face)

   :language angular
   :feature string
   (((static_member_expression "\'" (identifier) "\'") @font-lock-string-face)
    ((quoted_attribute_value) @font-lock-string-face)
    (attribute (_ ("\"") @font-lock-string-face))
    (icu_case (text) @font-lock-string-face)
    ((string) @font-lock-string-face))
   
   :language angular
   :feature property
   ((property_binding (binding_name (identifier) @font-lock-property-use-face))
    (two_way_binding (binding_name (identifier) @font-lock-property-use-face))
    (event_binding (binding_name (identifier) @font-lock-property-use-face))
    (member_expression property: (identifier) @font-lock-property-use-face)
    (structural_directive ["*" (identifier)] @font-lock-property-use-face))
    

   :language angular
   :feature variable
   (((attribute_name) @font-lock-variable-name-face))
   
   :language angular
   :feature function
   ((call_expression function: (identifier) @font-lock-function-call-face)
    (pipe_call name: (identifier) @font-lock-function-call-face))

   :language angular
   :feature type
   (((special_keyword) (identifier) @font-lock-type-face))


   :language angular
   :feature builtin
   (((identifier) @font-lock-builtin-face
     (:match
      "true\\|false\\|\\$any\\|\\$event\\|undefined\\|null" @font-lock-builtin-face)))

   :language angular
   :feature operator
   ((binary_expression
     ["-" "&&" "+" "<" "<=" "=" "==" "===" "!=" "!==" ">" ">=" "*" "/" "||" "%"] @font-lock-operator-face)
    ([(coalescing_operator) (conditional_operator) (ternary_operator)] @font-lock-operator-face)
    (pipe_sequence (pipe_operator) @font-lock-operator-face)
    (pipe_arguments "\:" @font-lock-operator-face))

   :language angular
   :feature punctuation
   (([";" "." "," "?."]) @font-lock-punctuation-face)

   :language angular
   :feature bracket
   ((["(" ")" "[" "]" "{" "}"]) @font-lock-bracket-face)))

(defcustom angular-ts-mode-indent-offset 2
  "Number of spaces used for indentation."
  :type 'integer
  :safe 'integerp
  :group 'angular)

(defvar angular-ts-mode--indent-rules
  `((angular
     ((parent-is "fragment") column-0 0)
     ((node-is "/>") parent-bol 0)
     ((node-is ">") parent-bol 0)
     ((node-is "end_tag") parent-bol 0)
     ((parent-is "comment") prev-adaptive-prefix 0)
     ((parent-is "element") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "script_element") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "style_element") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "start_tag") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "self_closing_tag") parent-bol angular-ts-mode-indent-offset)

     ((node-is "}") parent-bol 0)
     ((parent-is "statement_block") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "switch_body") parent-bol angular-ts-mode-indent-offset)))
  "Angular indentation rules.")



(defun angular-ts-mode--defun-name (node)
  "Return the defun name of NODE.
Return nil if there is no name or if NODE is not a defun node."
  (when (equal (treesit-node-type node) "tag_name")
    (treesit-node-text node t)))

(defun angular-ts-mode--setup ()
  "Angular tree-sitter mode setup."
  (unless (treesit-ready-p 'angular)
    (error "Tree-sitter for Angular isn't available"))

  (treesit-parser-create 'angular)

  (setq-local treesit-simple-indent-rules angular-ts-mode--indent-rules)

  (setq-local treesit-defun-type-regexp "element")
  (setq-local treesit-defun-name-function #'angular-ts-mode--defun-name)

  (setq-local treesit-font-lock-settings
              (apply #'treesit-font-lock-rules
                     angular-ts-font-lock-rules))
  
  (setq-local treesit-font-lock-feature-list
              '((comment definition string)
                (keyword property builtin)
                (attribute type variable function)
                (delimiter operator bracket punctuation)))

  (setq-local treesit-simple-imenu-settings
              '(("Element" "\\`tag_name\\'" nil nil)))

  (setq-local treesit-outline-predicate "\\`element\\'")
  (kill-local-variable 'outline-regexp)
  (kill-local-variable 'outline-heading-end-regexp)
  (kill-local-variable 'outline-level)

  (treesit-major-mode-setup))

;;;###autoload
(define-derived-mode angular-ts-mode html-mode "Angular"
  "Major mode for Angular templates."
  :group 'angular
  (angular-ts-mode--setup))

(when (treesit-ready-p 'angular)
  (add-to-list 'auto-mode-alist '("\\.component\\.html\\'" . angular-ts-mode)))

(provide 'angular-ts-mode)

;;; angular-ts-mode.el ends here
