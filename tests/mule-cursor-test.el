;;; mule-cursor-test.el --- Tests for cursor management and DECSCUSR  -*- lexical-binding: t -*-

(require 'ert)
(require 'cl-lib)
(require 'mule-modal)

;;; ---------------------------------------------------------------------------
;;; Cursor Type to DECSCUSR: mule--cursor-type-to-decscusr
;;; ---------------------------------------------------------------------------

(ert-deftest mule-cursor-type-to-decscusr-box ()
  "Test box cursor maps to DECSCUSR steady block sequence.
Expected: \"\\e[2 q\" for box."
  (should (string= (mule--cursor-type-to-decscusr 'box) "\e[2 q")))

(ert-deftest mule-cursor-type-to-decscusr-hollow ()
  "Test hollow cursor maps to DECSCUSR blinking block sequence.
Expected: \"\\e[0 q\" for hollow."
  (should (string= (mule--cursor-type-to-decscusr 'hollow) "\e[0 q")))

(ert-deftest mule-cursor-type-to-decscusr-bar ()
  "Test bar cursor maps to DECSCUSR steady bar sequence.
Expected: \"\\e[6 q\" for bar."
  (should (string= (mule--cursor-type-to-decscusr 'bar) "\e[6 q")))

(ert-deftest mule-cursor-type-to-decscusr-bar-with-width ()
  "Test (bar . N) cursor maps to DECSCUSR steady bar sequence.
Expected: \"\\e[6 q\" for (bar . 2), width ignored."
  (should (string= (mule--cursor-type-to-decscusr '(bar . 2)) "\e[6 q")))

(ert-deftest mule-cursor-type-to-decscusr-hbar ()
  "Test (hbar . N) cursor maps to DECSCUSR steady underline.
Expected: \"\\e[4 q\" for (hbar . 2)."
  (should (string= (mule--cursor-type-to-decscusr '(hbar . 2)) "\e[4 q")))

(ert-deftest mule-cursor-type-to-decscusr-unknown-type-fallback ()
  "Test unknown cursor type maps to DECSCUSR default sequence.
Expected: \"\\e[0 q\" for unrecognized type."
  (should (string= (mule--cursor-type-to-decscusr 'unknown-shape) "\e[0 q")))

;;; ---------------------------------------------------------------------------
;;; Terminal DECSCUSR Support: mule--terminal-supports-decscusr-p
;;; ---------------------------------------------------------------------------

(ert-deftest mule-terminal-supports-decscusr-p-returns-nil-in-gui ()
  "Test DECSCUSR support is nil when display-graphic-p returns t.
Expected: nil in GUI mode, even if terminal type would otherwise qualify."
  (cl-letf (((symbol-function 'display-graphic-p) (lambda () t)))
    (should (null (mule--terminal-supports-decscusr-p)))))

(ert-deftest mule-terminal-supports-decscusr-p-returns-nil-when-tty-type-is-dumb ()
  "Test DECSCUSR support is nil for dumb terminals.
Expected: nil when tty-type returns 'dumb'."
  (cl-letf (((symbol-function 'display-graphic-p) (lambda () nil))
            ((symbol-function 'tty-type) (lambda () "dumb")))
    (should (null (mule--terminal-supports-decscusr-p)))))

(ert-deftest mule-terminal-supports-decscusr-p-returns-nil-when-tty-type-is-linux ()
  "Test DECSCUSR support is nil for Linux framebuffer console.
Expected: nil when tty-type returns 'linux'."
  (cl-letf (((symbol-function 'display-graphic-p) (lambda () nil))
            ((symbol-function 'tty-type) (lambda () "linux")))
    (should (null (mule--terminal-supports-decscusr-p)))))

(ert-deftest mule-terminal-supports-decscusr-p-returns-nil-for-cons25 ()
  "Test DECSCUSR support is nil for cons25 terminals.
Expected: nil when tty-type returns 'cons25'."
  (cl-letf (((symbol-function 'display-graphic-p) (lambda () nil))
            ((symbol-function 'tty-type) (lambda () "cons25")))
    (should (null (mule--terminal-supports-decscusr-p)))))

(ert-deftest mule-terminal-supports-decscusr-p-returns-nil-for-unknown ()
  "Test DECSCUSR support is nil for unknown terminal type.
Expected: nil when tty-type returns 'unknown'."
  (cl-letf (((symbol-function 'display-graphic-p) (lambda () nil))
            ((symbol-function 'tty-type) (lambda () "unknown")))
    (should (null (mule--terminal-supports-decscusr-p)))))

(ert-deftest mule-terminal-supports-decscusr-p-returns-t-for-xterm ()
  "Test DECSCUSR support is non-nil for xterm.
Expected: non-nil when tty-type returns 'xterm-256color'."
  (cl-letf (((symbol-function 'display-graphic-p) (lambda () nil))
            ((symbol-function 'tty-type) (lambda () "xterm-256color")))
    (should (mule--terminal-supports-decscusr-p))))

(ert-deftest mule-terminal-supports-decscusr-p-falls-back-to-TERM-env ()
  "Test DECSCUSR support uses TERM env var when tty-type returns nil.
Expected: non-nil when tty-type is nil but TERM is 'xterm-256color'."
  (cl-letf (((symbol-function 'display-graphic-p) (lambda () nil))
            ((symbol-function 'tty-type) (lambda () nil))
            ((symbol-function 'getenv) (lambda (var) "xterm-256color")))
    (should (mule--terminal-supports-decscusr-p))))

(ert-deftest mule-terminal-supports-decscusr-p-returns-nil-when-both-tty-and-term-nil ()
  "Test DECSCUSR support is nil when both tty-type and TERM are nil.
Expected: nil when no terminal type can be determined."
  (cl-letf (((symbol-function 'display-graphic-p) (lambda () nil))
            ((symbol-function 'tty-type) (lambda () nil))
            ((symbol-function 'getenv) (lambda (var) nil)))
    (should (null (mule--terminal-supports-decscusr-p)))))

(ert-deftest mule-terminal-supports-decscusr-p-accepts-terms-that-contain-denied-prefix ()
  "Test DECSCUSR allows terminal types that don't match denylist prefix.
Expected: non-nil for 'xterm-dumb' which contains but doesn't start with 'dumb'."
  (cl-letf (((symbol-function 'display-graphic-p) (lambda () nil))
            ((symbol-function 'tty-type) (lambda () "xterm-dumb")))
    (should (mule--terminal-supports-decscusr-p))))

;;; ---------------------------------------------------------------------------
;;; Send Cursor Sequence: mule--send-cursor-sequence
;;; ---------------------------------------------------------------------------

(ert-deftest mule-send-cursor-sequence-noop-in-gui ()
  "Test `mule--send-cursor-sequence' is a no-op in GUI mode.
Expected: send-string-to-terminal not called."
  (let ((send-called nil))
    (cl-letf (((symbol-function 'display-graphic-p) (lambda () t))
              ((symbol-function 'send-string-to-terminal)
               (lambda (&rest _) (setq send-called t))))
      (mule--send-cursor-sequence 'box)
      (should-not send-called))))

(ert-deftest mule-send-cursor-sequence-sends-in-supported-terminal ()
  "Test `mule--send-cursor-sequence' sends sequence in supported terminal.
Expected: send-string-to-terminal called twice (double-send for reliability)."
  (let ((send-count 0))
    (cl-letf (((symbol-function 'display-graphic-p) (lambda () nil))
              ((symbol-function 'tty-type) (lambda () "xterm-256color"))
              ((symbol-function 'send-string-to-terminal)
               (lambda (&rest _) (cl-incf send-count)))
              ((symbol-function 'sit-for) (lambda (&rest _) t)))
      (mule--send-cursor-sequence 'box)
      (should (= send-count 2)))))

(ert-deftest mule-send-cursor-sequence-suppressed-for-denied-terminal ()
  "Test `mule--send-cursor-sequence' is suppressed for denied terminals.
Expected: send-string-to-terminal not called for 'dumb' terminal."
  (let ((send-called nil))
    (cl-letf (((symbol-function 'display-graphic-p) (lambda () nil))
              ((symbol-function 'tty-type) (lambda () "dumb"))
              ((symbol-function 'send-string-to-terminal)
               (lambda (&rest _) (setq send-called t))))
      (mule--send-cursor-sequence 'box)
      (should-not send-called))))

(ert-deftest mule-send-cursor-sequence-swallows-io-errors ()
  "Test `mule--send-cursor-sequence' silently absorbs I/O errors.
Expected: no error propagated when send-string-to-terminal signals."
  (cl-letf (((symbol-function 'display-graphic-p) (lambda () nil))
            ((symbol-function 'tty-type) (lambda () "xterm-256color"))
            ((symbol-function 'send-string-to-terminal)
             (lambda (&rest _) (signal 'file-error "I/O failure")))
            ((symbol-function 'sit-for) (lambda (&rest _) t)))
    (should-not (mule--send-cursor-sequence 'box))))

(ert-deftest mule-send-cursor-sequence-sends-correct-sequence-for-bar ()
  "Test correct DECSCUSR sequence sent for bar cursor.
Expected: \"\\e[6 q\" sent when cursor type is bar."
  (let ((sent-sequences nil))
    (cl-letf (((symbol-function 'display-graphic-p) (lambda () nil))
              ((symbol-function 'tty-type) (lambda () "xterm-256color"))
              ((symbol-function 'send-string-to-terminal)
               (lambda (seq) (push seq sent-sequences)))
              ((symbol-function 'sit-for) (lambda (&rest _) t)))
      (mule--send-cursor-sequence 'bar)
      (should (= (length sent-sequences) 2))
      (should (cl-every (lambda (s) (string= s "\e[6 q")) sent-sequences)))))

;;; ---------------------------------------------------------------------------
;;; Apply Cursor Setting: mule--apply-cursor-setting
;;; ---------------------------------------------------------------------------

(ert-deftest mule-apply-cursor-setting-sets-local-when-non-nil ()
  "Test `mule--apply-cursor-setting' sets cursor-type buffer-local
when given a non-nil setting.
Expected: cursor-type is buffer-local and equals the provided setting."
  (with-temp-buffer
    (mule--apply-cursor-setting 'bar)
    (should (local-variable-p 'cursor-type))
    (should (eq cursor-type 'bar))))

(ert-deftest mule-apply-cursor-setting-kills-local-when-nil ()
  "Test `mule--apply-cursor-setting' kills local cursor-type when
given nil setting.
Expected: cursor-type is not buffer-local after nil setting."
  (with-temp-buffer
    (setq-local cursor-type 'bar)
    (should (local-variable-p 'cursor-type))
    (mule--apply-cursor-setting nil)
    (should-not (local-variable-p 'cursor-type))))

(ert-deftest mule-apply-cursor-setting-sends-decscusr-in-terminal ()
  "Test `mule--apply-cursor-setting' sends DECSCUSR in terminal mode.
Expected: send-string-to-terminal called with correct sequence."
  (let ((send-called nil))
    (cl-letf (((symbol-function 'display-graphic-p) (lambda () nil))
              ((symbol-function 'tty-type) (lambda () "xterm-256color"))
              ((symbol-function 'send-string-to-terminal)
               (lambda (&rest _) (setq send-called t)))
              ((symbol-function 'sit-for) (lambda (&rest _) t)))
      (with-temp-buffer
        (mule--apply-cursor-setting 'bar))
      (should send-called))))

;;; ---------------------------------------------------------------------------
;;; Update Cursor: mule--update-cursor
;;; ---------------------------------------------------------------------------

(ert-deftest mule-update-cursor-applies-normal-settings ()
  "Test `mule--update-cursor' applies normal mode cursor settings.
Expected: cursor updated according to mule-cursor-normal value."
  (let ((original-value mule-cursor-normal))
    (unwind-protect
        (progn
          (setq mule-cursor-normal 'hollow)
          (mule-enter-normal)
          (should (or (eq cursor-type 'hollow)
                      (not (local-variable-p 'cursor-type)))))
      (setq mule-cursor-normal original-value))))

(ert-deftest mule-update-cursor-applies-insert-settings ()
  "Test `mule--update-cursor' applies insert mode cursor settings.
Expected: cursor updated according to mule-cursor-insert value."
  (let ((original-value mule-cursor-insert))
    (unwind-protect
        (progn
          (setq mule-cursor-insert 'box)
          (mule-enter-insert)
          (should (or (eq cursor-type 'box)
                      (not (local-variable-p 'cursor-type)))))
      (setq mule-cursor-insert original-value))))

;;; ---------------------------------------------------------------------------
;;; Terminal Denylist: mule--decscusr-denied-terminals
;;; ---------------------------------------------------------------------------

(ert-deftest mule-decscusr-denied-terminals-default-contains-dumb-and-linux ()
  "Test `mule--decscusr-denied-terminals' contains default entries.
Expected: list includes 'dumb' and 'linux' by default."
  (should (member "dumb" mule--decscusr-denied-terminals))
  (should (member "linux" mule--decscusr-denied-terminals)))

;;; mule-cursor-test.el ends here
