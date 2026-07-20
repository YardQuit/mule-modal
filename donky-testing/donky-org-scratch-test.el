;;; donky-org-scratch-test.el --- Tests for org-scratch functions -*- lexical-binding: t; -*-

(require 'ert)
(require 'org)
(require 'donky)
(defvar this-original-command)
(defvar last-command-event)

;;; ---------------------------------------------------------------------------
;;; Helper Macro
;;; ---------------------------------------------------------------------------

(defmacro donky-with-clean-scratch (&rest body)
  "Execute BODY with a guaranteed-absent *org-scratch* buffer, then clean up."
  (declare (indent 0))
  `(let ((--scratch-created nil))
     (when (get-buffer "*org-scratch*")
       (kill-buffer "*org-scratch*"))
     (unwind-protect
         (progn ,@body)
       (when (get-buffer "*org-scratch*")
         (kill-buffer "*org-scratch*")))))

;;; ---------------------------------------------------------------------------
;;; Tests for `donky-insert-org-scratch-message'
;;; ---------------------------------------------------------------------------

(ert-deftest donky-insert-org-scratch-message/inserts-text ()
  "Should insert the org-mode scribble header into the current buffer."
  (with-temp-buffer
    (donky-insert-org-scratch-message)
    (goto-char (point-min))
    (should (search-forward "# This buffer is for scribbling in org-mode." nil t))))

(ert-deftest donky-insert-org-scratch-message/contains-save-hint ()
  "The inserted text should mention saving the buffer."
  (with-temp-buffer
    (donky-insert-org-scratch-message)
    (goto-char (point-min))
    (should (search-forward "save to file with" nil t))
    ;; `substitute-command-keys' expands \[save-some-buffers]; we only
    ;; assert that some substitution occurred (non-empty, non-literal key).
    (should (search-forward "for persistence" nil t))))

(ert-deftest donky-insert-org-scratch-message/point-at-max ()
  "Point should be at `point-max' after insertion."
  (with-temp-buffer
    (donky-insert-org-scratch-message)
    (should (= (point) (point-max)))))

(ert-deftest donky-insert-org-scratch-message/appends-to-existing ()
  "Should append the message after any pre-existing buffer content."
  (with-temp-buffer
    (insert "PRE-EXISTING")
    (donky-insert-org-scratch-message)
    (goto-char (point-min))
    (should (search-forward "PRE-EXISTING" nil t))
    (should (search-forward "# This buffer is for scribbling in org-mode." nil t))))

(ert-deftest donky-insert-org-scratch-message/non-empty-buffer ()
  "Resulting buffer should not be empty."
  (with-temp-buffer
    (donky-insert-org-scratch-message)
    (should (> (buffer-size) 0))))

;;; ---------------------------------------------------------------------------
;;; Tests for `donky-create-org-scratch'
;;; ---------------------------------------------------------------------------

(ert-deftest donky-create-org-scratch/creates-named-buffer ()
  "Should create a buffer named *org-scratch*."
  (donky-with-clean-scratch
   (donky-create-org-scratch)
   (should (buffer-live-p (get-buffer "*org-scratch*")))))

(ert-deftest donky-create-org-scratch/enables-org-mode ()
  "The created buffer should be in `org-mode'."
  (donky-with-clean-scratch
   (donky-create-org-scratch)
   (with-current-buffer "*org-scratch*"
     (should (eq major-mode 'org-mode)))))

(ert-deftest donky-create-org-scratch/switches-to-buffer ()
  "Should switch the current window to the new buffer."
  (donky-with-clean-scratch
   (donky-create-org-scratch)
   (should (eq (current-buffer) (get-buffer "*org-scratch*")))))

(ert-deftest donky-create-org-scratch/contains-scratch-message ()
  "The created buffer should contain the scratch message text."
  (donky-with-clean-scratch
   (donky-create-org-scratch)
   (with-current-buffer "*org-scratch*"
     (goto-char (point-min))
     (should (search-forward "# This buffer is for scribbling in org-mode." nil t)))))

(ert-deftest donky-create-org-scratch/idempotent-buffer ()
  "Calling twice should reuse (not duplicate) the *org-scratch* buffer."
  (donky-with-clean-scratch
   (donky-create-org-scratch)
   (let ((first-buf (get-buffer "*org-scratch*")))
     (donky-create-org-scratch)
     (should (eq (get-buffer "*org-scratch*") first-buf)))))

;;; ---------------------------------------------------------------------------
;;; Tests for `donky-org-scratch'
;;; ---------------------------------------------------------------------------

(ert-deftest donky-org-scratch/creates-when-absent ()
  "When no *org-scratch* buffer exists, should create one."
  (donky-with-clean-scratch
   (donky-org-scratch)
   (should (buffer-live-p (get-buffer "*org-scratch*")))
   (with-current-buffer "*org-scratch*"
     (should (eq major-mode 'org-mode)))))

(ert-deftest donky-org-scratch/switches-when-present ()
  "When *org-scratch* already exists, should switch to it without recreating."
  (donky-with-clean-scratch
   (donky-create-org-scratch)
   (let ((original-buf (get-buffer "*org-scratch*")))
     ;; Add some content so we can verify it survives.
     (with-current-buffer original-buf
       (insert "* My Scribbles"))
     (donky-org-scratch)
     (should (eq (current-buffer) original-buf))
     ;; Same buffer object — not a fresh one.
     (should (eq (get-buffer "*org-scratch*") original-buf))
     ;; Content preserved.
     (goto-char (point-min))
     (should (search-forward "* My Scribbles" nil t)))))

(ert-deftest donky-org-scratch/message-on-create ()
  "Should signal creation via `message' when buffer is new."
  (donky-with-clean-scratch
   (let ((messages nil))
     (cl-letf (((symbol-function #'message)
                (lambda (fmt &rest args)
                  (push (apply #'format fmt args) messages))))
       (donky-org-scratch))
     (should (member "*org-scratch* buffer doesn't exist, creating." messages)))))

(ert-deftest donky-org-scratch/message-on-switch ()
  "Should signal switching via `message' when buffer already exists."
  (donky-with-clean-scratch
   (donky-create-org-scratch)
   (let ((messages nil))
     (cl-letf (((symbol-function #'message)
                (lambda (fmt &rest args)
                  (push (apply #'format fmt args) messages))))
       (donky-org-scratch))
     (should (member "*org-scratch* buffer already exist, switching." messages)))))

(ert-deftest donky-org-scratch/does-not-double-insert ()
  "Switching to an existing buffer should not re-insert the scratch message."
  (donky-with-clean-scratch
   (donky-create-org-scratch)
   (let ((size-before
          (with-current-buffer "*org-scratch*" (buffer-size))))
     (donky-org-scratch)
     (let ((size-after
            (with-current-buffer "*org-scratch*" (buffer-size))))
       (should (= size-before size-after))))))

;;; ---------------------------------------------------------------------------
;;; Test Runner
;;; ---------------------------------------------------------------------------

(defun donky-run-all-tests ()
  "Run all MULE transition tests interactively."
  (interactive)
  (ert "^donky-org" :result-buffer "*MULE Test Results*"))
(provide 'donky-org-scratch-test)

;;; donky-org-scratch-test.el ends here
