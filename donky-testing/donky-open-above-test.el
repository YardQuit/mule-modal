;;; donky-open-above-test.el --- Tests for donky-open-above -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'donky)

;; ===========================================================================
;; Section: donky-open-above
;; Selector: (ert "donky-open-above")
;;           runs ALL tests in this file
;; ===========================================================================

;;; --- Basic functionality ---

(ert-deftest donky-open-above-opens-line-above-and-enters-insert ()
  "Moves to beginning of line, inserts newline, moves up, indents,
enters insert mode.
Buffer: \"hello\\n\" — 6 chars.
After: \"\\nhello\\n\" — 7 chars. Point at 1 (on the new empty line).
Expected: donky-enter-insert called, point at 1, buffer has 7 chars."
  (let (entered)
    (with-temp-buffer
      (insert "hello\n")
      (goto-char 3)
      (cl-letf (((symbol-function 'donky-enter-insert)
                 (lambda () (setq entered t))))
        (donky-open-above))
      (should entered)
      (should (= (point) 1))
      (should (= (buffer-size) 7)))))

(ert-deftest donky-open-above-call-order ()
  "Executes in order: deactivate-mark (if region), move-beginning-of-line,
newline-and-indent, forward-line -1, indent-according-to-mode,
donky-enter-insert.
newline-and-indent is fully mocked to prevent it from internally calling
the mocked indent-according-to-mode.
Uses push to track order (newest at front).
Expected: nth 0 = enter, nth 1 = indent, nth 2 = forward-line,
nth 3 = newline, nth 4 = bol."
  (let (order)
    (with-temp-buffer
      (insert "hello\n")
      (goto-char 3)
      (let ((orig-bol (symbol-function 'move-beginning-of-line))
            (orig-forward-line (symbol-function 'forward-line)))
        (cl-letf (((symbol-function 'region-active-p)
                   (lambda () nil))
                  ((symbol-function 'move-beginning-of-line)
                   (lambda (n)
                     (push 'bol order)
                     (funcall orig-bol n)))
                  ((symbol-function 'newline-and-indent)
                   (lambda ()
                     (push 'newline order)
                     (insert "\n")))
                  ((symbol-function 'forward-line)
                   (lambda (n)
                     (push 'forward-line order)
                     (funcall orig-forward-line n)))
                  ((symbol-function 'indent-according-to-mode)
                   (lambda ()
                     (push 'indent order)))
                  ((symbol-function 'donky-enter-insert)
                   (lambda ()
                     (push 'enter order))))
          (donky-open-above))))
    (should (eq (nth 0 order) 'enter))
    (should (eq (nth 1 order) 'indent))
    (should (eq (nth 2 order) 'forward-line))
    (should (eq (nth 3 order) 'newline))
    (should (eq (nth 4 order) 'bol))
    (should (= (length order) 5))))

;;; --- Region handling ---

(ert-deftest donky-open-above-deactivates-active-region ()
  "When region is active, deactivates the mark before proceeding.
Expected: deactivate-mark called."
  (let (deactivated)
    (with-temp-buffer
      (insert "hello\n")
      (goto-char 1)
      (cl-letf (((symbol-function 'region-active-p)
                 (lambda () t))
                ((symbol-function 'deactivate-mark)
                 (lambda () (setq deactivated t)))
                ((symbol-function 'newline-and-indent)
                 (lambda () (insert "\n")))
                ((symbol-function 'forward-line)
                 (lambda (n) (ignore n)))
                ((symbol-function 'indent-according-to-mode)
                 (lambda () nil))
                ((symbol-function 'donky-enter-insert)
                 (lambda () nil)))
        (donky-open-above)))
    (should deactivated)))

(ert-deftest donky-open-above-skips-deactivate-when-no-region ()
  "When no region active, does not call deactivate-mark.
Expected: deactivate-mark not called."
  (let (deactivated)
    (with-temp-buffer
      (insert "hello\n")
      (goto-char 1)
      (cl-letf (((symbol-function 'region-active-p)
                 (lambda () nil))
                ((symbol-function 'deactivate-mark)
                 (lambda () (setq deactivated t)))
                ((symbol-function 'newline-and-indent)
                 (lambda () (insert "\n")))
                ((symbol-function 'forward-line)
                 (lambda (n) (ignore n)))
                ((symbol-function 'indent-according-to-mode)
                 (lambda () nil))
                ((symbol-function 'donky-enter-insert)
                 (lambda () nil)))
        (donky-open-above)))
    (should-not deactivated)))

;;; --- Position after opening ---

(ert-deftest donky-open-above-from-middle-of-line ()
  "Point in middle of line; opens above and places point on new line.
Buffer: \"hello world\\n\" — 12 chars.
After: \"\\nhello world\\n\" — 13 chars. Point at 1 (on new empty line).
Expected: point at 1."
  (with-temp-buffer
    (insert "hello world\n")
    (goto-char 6)
    (cl-letf (((symbol-function 'donky-enter-insert)
               (lambda () nil)))
      (donky-open-above))
    (should (= (point) 1))))

(ert-deftest donky-open-above-from-second-line ()
  "Point on second line; opens above second line.
Buffer: \"one\\ntwo\\n\" — 8 chars.
After: \"one\\n\\ntwo\\n\" — 9 chars. Point at 5 (on the new empty line).
Expected: point at 5."
  (with-temp-buffer
    (insert "one\ntwo\n")
    (goto-char 5)
    (cl-letf (((symbol-function 'donky-enter-insert)
               (lambda () nil)))
      (donky-open-above))
    (should (= (point) 5))))

(ert-deftest donky-open-above-from-beginning-of-line ()
  "Point already at beginning of line; still inserts newline above.
Buffer: \"hello\\n\" — 6 chars.
After: \"\\nhello\\n\" — 7 chars. Point at 1.
Expected: point at 1."
  (with-temp-buffer
    (insert "hello\n")
    (goto-char 1)
    (cl-letf (((symbol-function 'donky-enter-insert)
               (lambda () nil)))
      (donky-open-above))
    (should (= (point) 1))))

(ert-deftest donky-open-above-from-end-of-line ()
  "Point at end of line; moves to beginning first, then opens above.
Buffer: \"hello\\n\" — 6 chars.
After: \"\\nhello\\n\" — 7 chars. Point at 1.
Expected: point at 1."
  (with-temp-buffer
    (insert "hello\n")
    (goto-char 6)
    (cl-letf (((symbol-function 'donky-enter-insert)
               (lambda () nil)))
      (donky-open-above))
    (should (= (point) 1))))

;;; --- Edge cases ---

(ert-deftest donky-open-above-on-empty-buffer ()
  "Empty buffer; creates first line above.
Buffer: \"\" — 0 chars.
After: \"\\n\" — 1 char. Point at 1.
Expected: point at 1, donky-enter-insert called."
  (let (entered)
    (with-temp-buffer
      (cl-letf (((symbol-function 'donky-enter-insert)
                 (lambda () (setq entered t))))
        (donky-open-above))
      (should entered)
      (should (= (point) 1)))))

(ert-deftest donky-open-above-on-line-without-newline ()
  "Buffer without trailing newline; adds newline above.
Buffer: \"hello\" — 5 chars.
After: \"\\nhello\" — 6 chars. Point at 1.
Expected: point at 1."
  (let (entered)
    (with-temp-buffer
      (insert "hello")
      (goto-char 3)
      (cl-letf (((symbol-function 'donky-enter-insert)
                 (lambda () (setq entered t))))
        (donky-open-above))
      (should entered)
      (should (= (point) 1)))))

(ert-deftest donky-open-above-on-empty-line ()
  "Point on an empty line (just newline).
Buffer: \"\\n\" — 1 char.
After: \"\\n\\n\" — 2 chars. Point at 1.
Expected: point at 1."
  (with-temp-buffer
    (insert "\n")
    (goto-char 1)
    (cl-letf (((symbol-function 'donky-enter-insert)
               (lambda () nil)))
      (donky-open-above))
    (should (= (point) 1))))

(ert-deftest donky-open-above-single-char-buffer ()
  "Single character, no newline.
Buffer: \"x\" — 1 char.
After: \"\\nx\" — 2 chars. Point at 1.
Expected: point at 1."
  (with-temp-buffer
    (insert "x")
    (goto-char 1)
    (cl-letf (((symbol-function 'donky-enter-insert)
               (lambda () nil)))
      (donky-open-above))
    (should (= (point) 1))))

(ert-deftest donky-open-above-last-line-with-newline ()
  "Point on last line that has a trailing newline.
Buffer: \"a\\nb\\n\" — 4 chars.
Point at 3 (start of 'b').
After: \"a\\n\\nb\\n\" — 5 chars. Point at 3.
Expected: point at 3."
  (with-temp-buffer
    (insert "a\nb\n")
    (goto-char 3)
    (cl-letf (((symbol-function 'donky-enter-insert)
               (lambda () nil)))
      (donky-open-above))
    (should (= (point) 3))))

;;; --- Buffer integrity ---

(ert-deftest donky-open-above-preserves-existing-content ()
  "Existing content is preserved; only a new line is added above.
Buffer: \"first\\nsecond\\n\" — 13 chars.
After: \"\\nfirst\\nsecond\\n\" — 14 chars.
Expected: 'first' at 2-6, 'second' at 8-13."
  (with-temp-buffer
    (insert "first\nsecond\n")
    (goto-char 3)
    (cl-letf (((symbol-function 'donky-enter-insert)
               (lambda () nil)))
      (donky-open-above))
    (should (string= (buffer-substring 2 7) "first"))
    (should (string= (buffer-substring 8 14) "second"))))

(ert-deftest donky-open-above-calls-newline-and-indent-exactly-once ()
  "newline-and-indent is called exactly once.
Expected: call-count = 1."
  (let ((call-count 0))
    (with-temp-buffer
      (insert "hello\n")
      (goto-char 1)
      (cl-letf (((symbol-function 'newline-and-indent)
                 (lambda ()
                   (cl-incf call-count)
                   (insert "\n")))
                ((symbol-function 'forward-line)
                 (lambda (n) (ignore n)))
                ((symbol-function 'indent-according-to-mode)
                 (lambda () nil))
                ((symbol-function 'donky-enter-insert)
                 (lambda () nil)))
        (donky-open-above)))
    (should (= call-count 1))))

(ert-deftest donky-open-above-calls-enter-insert-exactly-once ()
  "donky-enter-insert is called exactly once.
Expected: call-count = 1."
  (let ((call-count 0))
    (with-temp-buffer
      (insert "hello\n")
      (goto-char 1)
      (cl-letf (((symbol-function 'newline-and-indent)
                 (lambda () (insert "\n")))
                ((symbol-function 'forward-line)
                 (lambda (n) (ignore n)))
                ((symbol-function 'indent-according-to-mode)
                 (lambda () nil))
                ((symbol-function 'donky-enter-insert)
                 (lambda () (cl-incf call-count))))
        (donky-open-above)))
    (should (= call-count 1))))

;;; --- Forward-line direction ---

(ert-deftest donky-open-above-forward-line-called-with-minus-one ()
  "forward-line is called with argument -1 to move up after inserting.
Expected: forward-line receives -1."
  (let (forward-arg)
    (with-temp-buffer
      (insert "hello\n")
      (goto-char 1)
      (let ((orig-forward-line (symbol-function 'forward-line)))
        (cl-letf (((symbol-function 'newline-and-indent)
                   (lambda () (insert "\n")))
                  ((symbol-function 'forward-line)
                   (lambda (n)
                     (setq forward-arg n)
                     (funcall orig-forward-line n)))
                  ((symbol-function 'indent-according-to-mode)
                   (lambda () nil))
                  ((symbol-function 'donky-enter-insert)
                   (lambda () nil)))
          (donky-open-above))))
    (should (eq forward-arg -1))))

;;; --- Interactive call ---

(ert-deftest donky-open-above-call-interactively ()
  "Can be called via call-interactively.
Expected: no error, new line created above, insert entered."
  (let (entered)
    (with-temp-buffer
      (insert "hello\n")
      (goto-char 3)
      (cl-letf (((symbol-function 'donky-enter-insert)
                 (lambda () (setq entered t))))
        (call-interactively #'donky-open-above))
      (should entered)
      (should (= (point) 1)))))

;;; donky-open-above-test.el ends here
