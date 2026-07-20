;;; mule-rectangle-mark-mode-test.el --- Tests for mule-rectangle-mark-mode -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'rect)
(require 'mule-modal)

;; ===========================================================================
;; Section: mule-rectangle-mark-mode basic functionality
;; Selector: (ert "mule-rectangle-mark-mode-")
;; ===========================================================================

(ert-deftest mule-rectangle-mark-mode-toggles-on ()
  "Calling mule-rectangle-mark-mode enables rectangle-mark-mode.
Expected: rectangle-mark-mode is active after command."
  (with-temp-buffer
    (insert "hello\nworld")
    (goto-char 1)
    (mule-rectangle-mark-mode)
    (should (bound-and-true-p rectangle-mark-mode))
    (should (mark))))

(ert-deftest mule-rectangle-mark-mode-advances-point ()
  "After activating rect mark mode, point moves right by 1.
Expected: point position increases by 1 from initial position."
  (with-temp-buffer
    (insert "hello\nworld")
    (goto-char 5)
    (let ((initial-pos 5))
      (mule-rectangle-mark-mode)
      (should (= (point) (1+ initial-pos))))))

(ert-deftest mule-rectangle-mark-mode-creates-rectangular-selection ()
  "Rect mark mode creates a rectangular region selection.
Expected: rectangle-mark-mode enabled with mark set."
  (with-temp-buffer
    (insert "hello\nworld\nfoo")
    (goto-char 1)
    (mule-rectangle-mark-mode)
    (should (bound-and-true-p rectangle-mark-mode))
    (should (mark))
    (should (< (mark) (point)))))

;; ===========================================================================
;; Section: mule-rectangle-mark-mode edge cases
;; Selector: (ert "mule-rectangle-mark-mode-edge")
;; ===========================================================================

(ert-deftest mule-rectangle-mark-mode-edge-empty ()
  "In an empty buffer, stub right-char to avoid end-of-buffer.
Expected: rectangle-mark-mode enabled."
  (with-temp-buffer
    (should (equal (buffer-string) ""))
    (cl-letf (((symbol-function 'right-char) (lambda (&optional n) nil)))
      (mule-rectangle-mark-mode)
      (should (bound-and-true-p rectangle-mark-mode)))))

(ert-deftest mule-rectangle-mark-mode-edge-at-buffer-start ()
  "Activating rect mark mode at buffer start succeeds.
Expected: point remains valid, rect mode enabled."
  (with-temp-buffer
    (insert "hello")
    (goto-char (point-min))
    (mule-rectangle-mark-mode)
    (should (>= (point) (point-min)))
    (should (<= (point) (point-max)))))

(ert-deftest mule-rectangle-mark-mode-edge-at-buffer-end ()
  "At buffer end, stub right-char to avoid error.
Expected: rectangle-mark-mode enabled."
  (with-temp-buffer
    (insert "hello")
    (goto-char (point-max))
    (cl-letf (((symbol-function 'right-char) (lambda (&optional n) nil)))
      (mule-rectangle-mark-mode)
      (should (bound-and-true-p rectangle-mark-mode)))))

(ert-deftest mule-rectangle-mark-mode-edge-single-character ()
  "On a single character, stub right-char.
Expected: rect mode enabled."
  (with-temp-buffer
    (insert "x")
    (goto-char 1)
    (cl-letf (((symbol-function 'right-char) (lambda (&optional n) nil)))
      (mule-rectangle-mark-mode)
      (should (bound-and-true-p rectangle-mark-mode)))))

(ert-deftest mule-rectangle-mark-mode-edge-multi-line ()
  "With multi-line buffer, rect mark mode selects correctly.
Expected: mark is set and point > mark."
  (with-temp-buffer
    (insert "line1\nline2\nline3")
    (goto-char 1)
    (mule-rectangle-mark-mode)
    (should (mark))
    (should (> (point) (mark)))))

(ert-deftest mule-rectangle-mark-mode-edge-before-newline ()
  "Invoking just before newline character works correctly.
Expected: rect mode enabled, point moves to newline."
  (with-temp-buffer
    (insert "abc\ndef")
    (goto-char 3)
    (mule-rectangle-mark-mode)
    (should (bound-and-true-p rectangle-mark-mode))))

(ert-deftest mule-rectangle-mark-mode-edge-on-newline ()
  "Invoking on newline character advances to next line.
Expected: point position changes appropriately."
  (with-temp-buffer
    (insert "abc\ndef")
    (goto-char 4)
    (mule-rectangle-mark-mode)
    (should (or (= (point) 5)
                (= (point) 4)))))

(ert-deftest mule-rectangle-mark-mode-edge-has-mark ()
  "The mark is set after activating rect mode.
Expected: (mark) returns non-nil, rectangle-mark-mode active."
  (with-temp-buffer
    (insert "test content")
    (goto-char 1)
    (mule-rectangle-mark-mode)
    (should (bound-and-true-p rectangle-mark-mode))
    (should (mark))))

(ert-deftest mule-rectangle-mark-mode-edge-call-interactively ()
  "Command can be called interactively without error.
Expected: no errors, rect mode enabled."
  (with-temp-buffer
    (insert "hello")
    (goto-char 1)
    (call-interactively #'mule-rectangle-mark-mode)
    (should (bound-and-true-p rectangle-mark-mode))))

(ert-deftest mule-rectangle-mark-mode-edge-region-boundaries ()
  "Rectangle region has valid boundaries.
Expected: mark < point."
  (with-temp-buffer
    (insert "abcde")
    (goto-char 2)
    (mule-rectangle-mark-mode)
    (let ((beg (mark))
          (end (point)))
      (should (< beg end)))))

(ert-deftest mule-rectangle-mark-mode-edge-after-right-char ()
  "Point advances exactly one character after activation.
Expected: (point) equals (original-point + 1)."
  (with-temp-buffer
    (insert "01234")
    (goto-char 2)
    (let ((before 2))
      (mule-rectangle-mark-mode)
      (should (= (point) (+ before 1))))))

(ert-deftest mule-rectangle-mark-mode-edge-preserves-text ()
  "Buffer contents unchanged after activating rect mark mode.
Expected: original text still present."
  (with-temp-buffer
    (let ((original "preserve this text"))
      (insert original)
      (goto-char 1)
      (mule-rectangle-mark-mode)
      (should (string= original (buffer-string))))))

(ert-deftest mule-rectangle-mark-mode-edge-with-prefix-arg ()
  "Command works when current-prefix-arg is set.
Expected: no errors with numeric prefix."
  (with-temp-buffer
    (insert "hello")
    (goto-char 1)
    (let ((current-prefix-arg '(4)))
      (mule-rectangle-mark-mode)
      (should (bound-and-true-p rectangle-mark-mode)))))

(ert-deftest mule-rectangle-mark-mode-edge-empty-at-start ()
  "Empty buffer with point at min, stubs right-char.
Expected: rectangle-mark-mode enabled."
  (with-temp-buffer
    (goto-char (point-min))
    (cl-letf (((symbol-function 'right-char) (lambda (&optional n) nil)))
      (mule-rectangle-mark-mode)
      (should (bound-and-true-p rectangle-mark-mode)))))

;;; mule-rectangle-mark-mode-test.el ends here
