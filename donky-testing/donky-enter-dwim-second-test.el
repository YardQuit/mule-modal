;;; donky-enter-dwim-second-test.el --- Tests for donky-enter-dwim (rule-based) -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'donky)

(defvar org-agenda-mode-map nil)

;; Section: donky--editing-mode-p
;; Selector: (ert "donky-enter-dwim-editing-mode-p")

(ert-deftest donky-enter-dwim-editing-mode-p-prog-mode ()
  "Returns non-nil when `major-mode' is `prog-mode'.
Expected: non-nil."
  (let ((major-mode 'prog-mode))
    (should (donky--editing-mode-p))))

(ert-deftest donky-enter-dwim-editing-mode-p-text-mode ()
  "Returns non-nil when `major-mode' is `text-mode'.
Expected: non-nil."
  (let ((major-mode 'text-mode))
    (should (donky--editing-mode-p))))

(ert-deftest donky-enter-dwim-editing-mode-p-org-mode ()
  "Returns non-nil when `major-mode' is `org-mode'.
Expected: non-nil."
  (let ((major-mode 'org-mode))
    (should (donky--editing-mode-p))))

(ert-deftest donky-enter-dwim-editing-mode-p-fundamental-mode ()
  "Returns non-nil when `major-mode' is `fundamental-mode'.
Expected: non-nil."
  (let ((major-mode 'fundamental-mode))
    (should (donky--editing-mode-p))))

(ert-deftest donky-enter-dwim-editing-mode-p-dired-mode ()
  "Returns nil when `major-mode' is `dired-mode' (not in the list).
Expected: nil."
  (let ((major-mode 'dired-mode))
    (should-not (donky--editing-mode-p))))

(ert-deftest donky-enter-dwim-editing-mode-p-info-mode ()
  "Returns nil when `major-mode' is `Info-mode' (not in the list).
Expected: nil."
  (let ((major-mode 'Info-mode))
    (should-not (donky--editing-mode-p))))

(ert-deftest donky-enter-dwim-editing-mode-p-derived-mode-not-caught ()
  "Modes derived from a listed mode but with a different symbol name are
NOT matched. `member' uses exact equality, not `derived-mode-p'.
Expected: nil."
  (let ((major-mode 'python-mode))
    (should-not (donky--editing-mode-p))))

;; Section: donky-add-enter-rule (macro and registration)
;; Selector: (ert "donky-enter-dwim-register-rule")

(ert-deftest donky-enter-dwim-register-rule-adds-to-list ()
  "Registering a rule adds it to `donky--enter-rules'.
Expected: rule count increases by 1."
  (let ((before-count (length donky--enter-rules)))
    (donky-add-enter-rule test-elem nil test-cmd)
    (should (= (length donky--enter-rules) (1+ before-count)))
    (setq donky--enter-rules
          (cl-remove 'test-elem donky--enter-rules :key #'car :test 'eq))))

(ert-deftest donky-enter-dwim-register-rule-stores-correct-form ()
  "Rules store element type, property, and command symbols correctly.
Expected: (test-rule nil cmd-a cmd-b)."
  (donky-add-enter-rule test-rule nil cmd-a cmd-b)
  (let ((rule (cl-find 'test-rule donky--enter-rules :key #'car :test 'eq)))
    (should (equal (nth 0 rule) 'test-rule))
    (should (null (nth 1 rule)))
    (should (equal (nthcdr 2 rule) '(cmd-a cmd-b))))
  (setq donky--enter-rules
        (cl-remove 'test-rule donky--enter-rules :key #'car :test 'eq)))

;; Section: donky-add-enter-rule configuration (defcustom)
;; Selector: (ert "donky-enter-dwim-config")

(ert-deftest donky-enter-dwim-config-default-rules-enabled ()
  "When `donky-default-enter-rules-enabled' is t, default rules are installed.
Expected: default rules exist in `donky--enter-rules'."
  (let ((donky-default-enter-rules-enabled t)
        (donky--enter-rules nil))
    (when donky-default-enter-rules-enabled
      (donky-add-enter-rule item :checkbox org-toggle-checkbox)
      (donky-add-enter-rule headline :todo-type donky-org-todo)
      (donky-add-enter-rule link nil org-open-at-point markdown-follow-thing-at-point browse-url-at-point))
    (should (member '(item :checkbox org-toggle-checkbox) donky--enter-rules))
    (should (member '(headline :todo-type donky-org-todo) donky--enter-rules))
    (should (member '(link nil org-open-at-point markdown-follow-thing-at-point browse-url-at-point) donky--enter-rules))
    (should-not (cl-find 'table donky--enter-rules :key #'car :test 'eq))))

(ert-deftest donky-enter-dwim-config-custom-rules ()
  "When `donky-default-enter-rules-enabled' is nil, no default rules are installed.
User can add custom rules in config.el.
Expected: only custom rules exist, no default rules."
  (let ((donky-default-enter-rules-enabled nil)
        (donky--enter-rules nil))
    (when donky-default-enter-rules-enabled
      (donky-add-enter-rule item :checkbox org-toggle-checkbox)
      (donky-add-enter-rule headline :todo-type donky-org-todo)
      (donky-add-enter-rule link nil org-open-at-point markdown-follow-thing-at-point browse-url-at-point))
    (donky-add-enter-rule table nil org-table-next-row)
    (should-not (member '(item :checkbox org-toggle-checkbox) donky--enter-rules))
    (should-not (member '(headline :todo-type donky-org-todo) donky--enter-rules))
    (should-not (member '(link nil org-open-at-point markdown-follow-thing-at-point browse-url-at-point) donky--enter-rules))
    (should (member '(table nil org-table-next-row) donky--enter-rules))))

;; Section: donky-enter-dwim dispatcher - Org Mode
;; Selector: (ert "donky-enter-dwim-org")

(ert-deftest donky-enter-dwim-org-link-follows-org-open-at-point ()
  "In org-mode with link element (context), calls `org-open-at-point'.
Expected: called-cmd is 'org-open-at-point."
  (let (called-cmd)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(paragraph (:begin 1 :end 10))))
              ((symbol-function 'org-element-context)
               (lambda () '(link (:path "http://example.com"))))
              ((symbol-function 'org-open-at-point)
               (lambda () (interactive) nil))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((major-mode 'org-mode))
        (donky-enter-dwim)))
    (should (eq called-cmd 'org-open-at-point))))

(ert-deftest donky-enter-dwim-org-checkbox-toggles ()
  "In org-mode with checkbox item (parent element), calls `org-toggle-checkbox'.
Expected: called-cmd is 'org-toggle-checkbox."
  (let (called-cmd)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(item (:checkbox t))))
              ((symbol-function 'org-element-context)
               (lambda () '(plain-text (:begin 1 :end 5))))
              ((symbol-function 'org-toggle-checkbox)
               (lambda () (interactive) nil))
              ((symbol-function 'org-element-property)
               (lambda (prop elem)
                 (if (and (consp elem) (eq (car elem) 'item))
                     (plist-get (cadr elem) prop)
                   nil)))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((major-mode 'org-mode))
        (donky-enter-dwim)))
    (should (eq called-cmd 'org-toggle-checkbox))))

(ert-deftest donky-enter-dwim-org-todo-cycles ()
  "In org-mode with TODO headline, calls `donky-org-todo'.
Expected: called-cmd is 'donky-org-todo."
  (let (called-cmd)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(headline (:todo-type todo))))
              ((symbol-function 'org-element-property)
               (lambda (prop elem)
                 (if (and (consp elem) (eq (car elem) 'headline))
                     (plist-get (cadr elem) prop)
                   nil)))
              ((symbol-function 'donky-org-todo)
               (lambda () (interactive) nil))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((major-mode 'org-mode))
        (donky-enter-dwim)))
    (should (eq called-cmd 'donky-org-todo))))

(ert-deftest donky-enter-dwim-org-table-follows-rule ()
  "In org-mode with table element (parent), calls `org-table-next-row'.
Expected: called-cmd is 'org-table-next-row."
  (let (called-cmd)
    (donky-add-enter-rule table nil org-table-next-row)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(table (:begin 1 :end 100))))
              ((symbol-function 'org-element-context)
               (lambda () '(table (:begin 1 :end 100))))
              ((symbol-function 'org-table-next-row)
               (lambda () (interactive) nil))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((major-mode 'org-mode))
        (donky-enter-dwim)))
    (setq donky--enter-rules
          (cl-remove 'table donky--enter-rules :key #'car :test 'eq))
    (should (eq called-cmd 'org-table-next-row))))

(ert-deftest donky-enter-dwim-org-src-block-does-nothing ()
  "In org-mode on src-block with no matching rule, no command called.
Expected: called-cmd is nil."
  (let (called-cmd)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(src-block (:language "python"))))
              ((symbol-function 'org-element-context)
               (lambda () '(src-block (:language "python"))))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((major-mode 'org-mode))
        (donky-enter-dwim)))
    (should (null called-cmd))))

;; Section: donky-enter-dwim dispatcher - Nested Element Priority
;; Selector: (ert "donky-enter-dwim-nested")

(ert-deftest donky-enter-dwim-context-fires-before-parent ()
  "Context elements (inline like links) are checked before parent elements.
When point is on a link inside a table, the link rule fires before table rule.
Expected: called-cmd is 'org-open-at-point, not 'org-table-next-row."
  (let (called-cmd)
    (donky-add-enter-rule table nil org-table-next-row)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(table (:begin 1 :end 100))))
              ((symbol-function 'org-element-context)
               (lambda () '(link (:path "http://example.com"))))
              ((symbol-function 'org-table-next-row)
               (lambda () (interactive) nil))
              ((symbol-function 'org-open-at-point)
               (lambda () (interactive) nil))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((major-mode 'org-mode))
        (donky-enter-dwim)))
    (setq donky--enter-rules
          (cl-remove 'table donky--enter-rules :key #'car :test 'eq))
    (should (eq called-cmd 'org-open-at-point))))

(ert-deftest donky-enter-dwim-table-under-headline-fires-table-first ()
  "When a table is nested under a headline, the table rule fires before
the headline rule. This tests element-first iteration (parent before ancestors).
Expected: called-cmd is 'org-table-next-row, not 'donky-org-todo."
  (let (called-cmd)
    (donky-add-enter-rule table nil org-table-next-row)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(table (:begin 1 :end 100))))
              ((symbol-function 'org-element-context)
               (lambda () '(table (:begin 1 :end 100))))
              ((symbol-function 'org-element-lineage)
               (lambda (elem)
                 (list '(headline (:todo-type todo)))))
              ((symbol-function 'org-table-next-row)
               (lambda () (interactive) nil))
              ((symbol-function 'donky-org-todo)
               (lambda () (interactive) nil))
              ((symbol-function 'org-element-property)
               (lambda (prop elem)
                 (if (and (consp elem) (eq (car elem) 'headline))
                     (plist-get (cadr elem) prop)
                   nil)))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((major-mode 'org-mode))
        (donky-enter-dwim)))
    (setq donky--enter-rules
          (cl-remove 'table donky--enter-rules :key #'car :test 'eq))
    (should (eq called-cmd 'org-table-next-row))))

(ert-deftest donky-enter-dwim-link-in-table-under-headline-follows-link ()
  "When a link is inside a table which is under a headline, the link fires
first (context priority), then table (parent), then headline (ancestor).
Expected: called-cmd is 'org-open-at-point."
  (let (called-cmd)
    (donky-add-enter-rule table nil org-table-next-row)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(table (:begin 1 :end 100))))
              ((symbol-function 'org-element-context)
               (lambda () '(link (:path "http://example.com"))))
              ((symbol-function 'org-element-lineage)
               (lambda (elem)
                 (list '(headline (:todo-type todo)))))
              ((symbol-function 'org-table-next-row)
               (lambda () (interactive) nil))
              ((symbol-function 'org-open-at-point)
               (lambda () (interactive) nil))
              ((symbol-function 'donky-org-todo)
               (lambda () (interactive) nil))
              ((symbol-function 'org-element-property)
               (lambda (prop elem)
                 (if (and (consp elem) (eq (car elem) 'headline))
                     (plist-get (cadr elem) prop)
                   nil)))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((major-mode 'org-mode))
        (donky-enter-dwim)))
    (setq donky--enter-rules
          (cl-remove 'table donky--enter-rules :key #'car :test 'eq))
    (should (eq called-cmd 'org-open-at-point))))

;; Section: donky-enter-dwim dispatcher - Org-Agenda Mode
;; Selector: (ert "donky-enter-dwim-agenda")

(ert-deftest donky-enter-dwim-agenda-calls-native-agenda-ret ()
  "In org-agenda-mode, calls native agenda RET (org-agenda-switch-to).
Expected: called-cmd is 'org-agenda-switch-to."
  (let (called-cmd)
    (cl-letf (((symbol-function 'org-agenda-mode-p)
               (lambda () t))
              ((symbol-function 'lookup-key)
               (lambda (_map _key) 'org-agenda-switch-to))
              ((symbol-function 'org-agenda-switch-to)
               (lambda () (interactive) nil))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((org-agenda-mode-map (make-sparse-keymap))
            (major-mode 'org-agenda-mode))
        (donky-enter-dwim)))
    (should (eq called-cmd 'org-agenda-switch-to))))

(ert-deftest donky-enter-dwim-agenda-with-undefined-ret-does-nothing ()
  "In org-agenda-mode with undefined RET, nothing happens.
Expected: called-cmd is nil."
  (let (called-cmd)
    (cl-letf (((symbol-function 'org-agenda-mode-p)
               (lambda () t))
              ((symbol-function 'lookup-key)
               (lambda (_map _key) 'undefined))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((org-agenda-mode-map (make-sparse-keymap))
            (major-mode 'org-agenda-mode))
        (donky-enter-dwim)))
    (should (null called-cmd))))

(ert-deftest donky-enter-dwim-agenda-with-keymap-ret-does-nothing ()
  "In org-agenda-mode where RET is bound to a keymap, nothing happens.
Expected: called-cmd is nil."
  (let (called-cmd)
    (cl-letf (((symbol-function 'org-agenda-mode-p)
               (lambda () t))
              ((symbol-function 'lookup-key)
               (lambda (_map _key) (make-sparse-keymap)))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((org-agenda-mode-map (make-sparse-keymap))
            (major-mode 'org-agenda-mode))
        (donky-enter-dwim)))
    (should (null called-cmd))))

(ert-deftest donky-enter-dwim-agenda-takes-priority-over-rules ()
  "Agenda mode dispatch takes priority over all other handlers.
Expected: called-cmd is 'org-agenda-switch-to, not rule command."
  (let (called-cmd)
    (cl-letf (((symbol-function 'org-agenda-mode-p)
               (lambda () t))
              ((symbol-function 'lookup-key)
               (lambda (_map _key) 'org-agenda-switch-to))
              ((symbol-function 'org-agenda-switch-to)
               (lambda () (interactive) nil))
              ((symbol-function 'org-element-at-point)
               (lambda () '(item (:checkbox t))))
              ((symbol-function 'org-toggle-checkbox)
               (lambda () (interactive) nil))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((org-agenda-mode-map (make-sparse-keymap))
            (major-mode 'org-agenda-mode))
        (donky-enter-dwim)))
    (should (eq called-cmd 'org-agenda-switch-to))))

;; Section: donky-enter-dwim dispatcher - Markdown Mode
;; Selector: (ert "donky-enter-dwim-markdown")

(ert-deftest donky-enter-dwim-markdown-follows-mdfn ()
  "In markdown-mode with link element, calls `markdown-follow-thing-at-point'.
Expected: called-cmd is 'markdown-follow-thing-at-point."
  (let (called-cmd)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(paragraph (:begin 1 :end 10))))
              ((symbol-function 'org-element-context)
               (lambda () '(link (:path "http://example.com"))))
              ((symbol-function 'markdown-follow-thing-at-point)
               (lambda (&optional pos) (interactive) nil))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((major-mode 'markdown-mode))
        (donky-enter-dwim)))
    (should (eq called-cmd 'markdown-follow-thing-at-point))))

(ert-deftest donky-enter-dwim-markdown-fallback-to-browse-url ()
  "In markdown-mode without markdown function, falls back to browse-url.
Expected: called-cmd is 'browse-url-at-point."
  (let (called-cmd)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(paragraph (:begin 1 :end 10))))
              ((symbol-function 'org-element-context)
               (lambda () '(link (:path "http://example.com"))))
              ((symbol-function 'markdown-follow-thing-at-point) nil)
              ((symbol-function 'browse-url-at-point)
               (lambda () (interactive) nil))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((major-mode 'markdown-mode))
        (donky-enter-dwim)))
    (should (eq called-cmd 'browse-url-at-point))))

;; Section: donky-enter-dwim dispatcher - Non-editing modes
;; Selector: (ert "donky-enter-dwim-non-editing")

(ert-deftest donky-enter-dwim-non-editing-calls-native-ret ()
  "In a non-editing mode with a saved RET binding, calls it.
Expected: called-cmd is #'dired-find-file."
  (let (called-cmd)
    (setq donky--saved-ret-binding #'dired-find-file)
    (cl-letf (((symbol-function 'dired-find-file)
               (lambda () (interactive) nil))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((major-mode 'dired-mode))
        (donky-enter-dwim)))
    (setq donky--saved-ret-binding nil)
    (should (eq called-cmd #'dired-find-file))))

(ert-deftest donky-enter-dwim-non-editing-no-ret-does-nothing ()
  "In a non-editing mode with no saved RET binding, no command is called.
Expected: called-cmd is nil."
  (let (called-cmd)
    (let ((donky--saved-ret-binding nil))
      (cl-letf (((symbol-function 'call-interactively)
                 (lambda (cmd) (setq called-cmd cmd))))
        (donky-enter-dwim)))
    (should (null called-cmd))))

(ert-deftest donky-enter-dwim-non-editing-undefined-ret-does-nothing ()
  "In a non-editing mode where saved RET is 'undefined, nothing happens.
Expected: called-cmd is nil."
  (let (called-cmd)
    (let ((donky--saved-ret-binding 'undefined))
      (cl-letf (((symbol-function 'call-interactively)
                 (lambda (cmd) (setq called-cmd cmd))))
        (donky-enter-dwim)))
    (should (null called-cmd))))

(ert-deftest donky-enter-dwim-non-editing-keymap-ret-does-nothing ()
  "In a non-editing mode where saved RET is a keymap, nothing happens.
Expected: called-cmd is nil."
  (let (called-cmd)
    (let ((km (make-sparse-keymap)))
      (let ((donky--saved-ret-binding km))
        (cl-letf (((symbol-function 'call-interactively)
                   (lambda (cmd) (setq called-cmd cmd))))
          (donky-enter-dwim))))
    (should (null called-cmd))))

;; Section: donky-org-todo
;; Selector: (ert "donky-org-todo")

(ert-deftest donky-org-todo-toggles-todo-to-done ()
  "donky-org-todo changes TODO headline to DONE.
Expected: org-todo called with 'done."
  (let (called-with)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(headline (:todo-type todo))))
              ((symbol-function 'org-element-property)
               (lambda (prop elem)
                 (if (and (consp elem) (eq (car elem) 'headline))
                     (plist-get (cadr elem) prop)
                   nil)))
              ((symbol-function 'org-todo)
               (lambda (&rest args)
                 (setq called-with args))))
      (donky-org-todo))
    (should (eq (car called-with) 'done))))

(ert-deftest donky-org-todo-toggles-done-to-todo ()
  "donky-org-todo changes DONE headline back to TODO.
Expected: org-todo called with 'todo."
  (let (called-with)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(headline (:todo-type done))))
              ((symbol-function 'org-element-property)
               (lambda (prop elem)
                 (if (and (consp elem) (eq (car elem) 'headline))
                     (plist-get (cadr elem) prop)
                   nil)))
              ((symbol-function 'org-todo)
               (lambda (&rest args)
                 (setq called-with args))))
      (donky-org-todo))
    (should (eq (car called-with) 'todo))))

(ert-deftest donky-org-todo-adds-todo-if-none ()
  "donky-org-todo adds TODO to headline with no keyword.
Expected: org-todo called with 'todo."
  (let (called-with)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(headline (:todo-type nil))))
              ((symbol-function 'org-element-property)
               (lambda (prop elem)
                 (if (and (consp elem) (eq (car elem) 'headline))
                     (plist-get (cadr elem) prop)
                   nil)))
              ((symbol-function 'org-todo)
               (lambda (&rest args)
                 (setq called-with args))))
      (donky-org-todo))
    (should (eq (car called-with) 'todo))))

;; Section: donky-enter-dwim dispatcher - Editing modes
;; Selector: (ert "donky-enter-dwim-editing")

(ert-deftest donky-enter-dwim-editing-mode-no-context-does-nothing ()
  "In an editing mode with no org/markdown context, nothing happens.
Expected: called-cmd is nil."
  (let (called-cmd)
    (let ((donky--saved-ret-binding nil))
      (cl-letf (((symbol-function 'call-interactively)
                 (lambda (cmd) (setq called-cmd cmd))))
        (let ((major-mode 'prog-mode))
          (donky-enter-dwim))))
    (should (null called-cmd))))

;; Section: donky-enter-dwim dispatcher - Priority and precedence
;; Selector: (ert "donky-enter-dwim-priority")

(ert-deftest donky-enter-dwim-checkbox-priority-over-generic-item ()
  "Item with checkbox property triggers checkbox rule before others.
Expected: called-cmd is 'org-toggle-checkbox."
  (let (called-cmd)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(item (:checkbox t))))
              ((symbol-function 'org-element-context)
               (lambda () '(plain-text (:begin 1 :end 5))))
              ((symbol-function 'org-toggle-checkbox)
               (lambda () (interactive) nil))
              ((symbol-function 'org-element-property)
               (lambda (prop elem)
                 (if (and (consp elem) (eq (car elem) 'item))
                     (plist-get (cadr elem) prop)
                   nil)))
              ((symbol-function 'call-interactively)
               (lambda (cmd) (setq called-cmd cmd))))
      (let ((major-mode 'org-mode))
        (donky-enter-dwim)))
    (should (eq called-cmd 'org-toggle-checkbox))))

;; Section: donky-enter-dwim dispatcher - Edge cases
;; Selector: (ert "donky-enter-dwim-edge")

(ert-deftest donky-enter-dwim-call-interactively-called-once ()
  "When a command is found, `call-interactively' is called exactly once.
Expected: call-count is 1."
  (let (call-count)
    (donky-add-enter-rule table nil org-table-next-row)
    (cl-letf (((symbol-function 'org-element-at-point)
               (lambda () '(table (:begin 1 :end 100))))
              ((symbol-function 'org-element-context)
               (lambda () '(table (:begin 1 :end 100))))
              ((symbol-function 'org-table-next-row)
               (lambda () (interactive) nil))
              ((symbol-function 'call-interactively)
               (lambda (cmd)
                 (setq call-count (1+ (or call-count 0))))))
      (let ((major-mode 'org-mode))
        (donky-enter-dwim)))
    (setq donky--enter-rules
          (cl-remove 'table donky--enter-rules :key #'car :test 'eq))
    (should (= call-count 1))))

;;; donky-enter-dwim-second-test.el ends here
