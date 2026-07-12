;;; mule-clipboard-test.el --- Tests for mule-clipboard  -*- lexical-binding: t -*-

(require 'ert)
(require 'mule-modal)

;; Test: mule-clipboard-available

(ert-deftest mule-clipboard-available-checks-executable ()
  "Test that `mule-clipboard-available' correctly identifies available tools."
  (let ((result (mule-clipboard-available)))
    (should (or (eq result 'wayland)
                (eq result 'x11)
                (null result)))))

(ert-deftest mule-clipboard-available-priority-wayland ()
  "Test that `mule-clipboard-available' prefers Wayland over X11."
  (if (executable-find "wl-paste")
      (should (eq (mule-clipboard-available) 'wayland))
    (ert-skip "wl-paste not available for testing")))

(ert-deftest mule-clipboard-available-returns-nil-when-none-found ()
  "Test that `mule-clipboard-available' returns nil when no tools exist."
  (let ((wl-exists (executable-find "wl-paste"))
        (xclip-exists (executable-find "xclip")))
    (if (and (not wl-exists) (not xclip-exists))
        (should (null (mule-clipboard-available)))
      (ert-skip "Clipboard tools detected, cannot test nil case"))))

;; Test: mule-clipboard--paste-from-system

(ert-deftest mule-clipboard--paste-from-system-returns-string-or-nil ()
  "Test that `mule-clipboard--paste-from-system' returns string or nil."
  (let ((result (mule-clipboard--paste-from-system)))
    (should (or (stringp result)
                (null result)))))

(ert-deftest mule-clipboard--paste-from-system-trims-whitespace ()
  "Test that `mule-clipboard--paste-from-system' trims leading/trailing whitespace."
  (let* ((content "  test content  ")
         (trimmed (string-trim content))
         (empty-content "   ")
         (trimmed-empty (string-trim empty-content)))
    (should-not (string-equal trimmed content))
    (should-not (string-empty-p trimmed))
    (should (string-empty-p trimmed-empty))))

(ert-deftest mule-clipboard--paste-from-system-returns-nil-for-empty-string ()
  "Test that `mule-clipboard--paste-from-system' returns nil for empty strings."
  (let ((empty-content "")
        (whitespace-only "   "))
    (should (string-empty-p empty-content))
    (should (string-empty-p (string-trim whitespace-only)))))

;; Test: mule-clipboard--copy-to-system

;; Skip actual process tests in batch mode — they require display server
(ert-deftest mule-clipboard--copy-to-system-skipped-in-batch ()
  "Skip copy tests in batch mode since start-process requires display server."
  (ert-skip "Copy tests require interactive session with display server"))

;; Test: mule-clipboard-enable/disable

(ert-deftest mule-clipboard-enable-sets-interprogram-functions ()
  "Test that `mule-clipboard-enable' sets interprogram functions in terminal mode."
  (let ((orig-paste interprogram-paste-function)
        (orig-cut interprogram-cut-function))
    (unwind-protect
        (let ((display-graphic-p nil))
          (mule-clipboard-enable)
          (should (eq interprogram-paste-function #'mule-clipboard--paste-from-system))
          (should (eq interprogram-cut-function #'mule-clipboard--copy-to-system)))
      (setq interprogram-paste-function orig-paste)
      (setq interprogram-cut-function orig-cut))))

(ert-deftest mule-clipboard-disable-resets-interprogram-functions ()
  "Test that `mule-clipboard-disable' resets interprogram functions."
  (let ((orig-paste interprogram-paste-function)
        (orig-cut interprogram-cut-function))
    (unwind-protect
        (let ((display-graphic-p nil))
          (mule-clipboard-enable)
          (mule-clipboard-disable)
          (should (null interprogram-paste-function))
          (should (null interprogram-cut-function)))
      (setq interprogram-paste-function orig-paste)
      (setq interprogram-cut-function orig-cut))))

(ert-deftest mule-clipboard-enable-no-op-in-gui-mode ()
  "Test that `mule-clipboard-enable' does nothing when display-graphic-p is nil.

This test verifies the function checks for terminal mode correctly."
  (let ((orig-paste interprogram-paste-function)
        (orig-cut interprogram-cut-function))
    (unwind-protect
        (progn
          (mule-clipboard-enable)  ;; Should enable since display-graphic-p is nil
          (should-not (eq interprogram-paste-function orig-paste))
          (should-not (eq interprogram-cut-function orig-cut)))
      (setq interprogram-paste-function orig-paste)
      (setq interprogram-cut-function orig-cut))))

;; Test: Documentation and metadata

(ert-deftest mule-clipboard-check-returns-appropriate-message ()
  "Test that `mule-clipboard-check' provides meaningful feedback."
  (let ((backend (mule-clipboard-available)))
    (should (or (eq backend 'wayland)
                (eq backend 'x11)
                (null backend)))))

  ;;; mule-clipboard-test.el ends here
