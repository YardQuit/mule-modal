;;; donky-mark-outer-test.el --- Tests for donky-mark-outer -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'donky)

(ert-deftest donky-mark-outer-braces ()
  "Marks content including braces."
  (with-temp-buffer
    (insert "{hello}")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "{hello}"))))

(ert-deftest donky-mark-outer-parens ()
  "Marks content including parens."
  (with-temp-buffer
    (insert "(world)")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "(world)"))))

(ert-deftest donky-mark-outer-brackets ()
  "Marks content including brackets."
  (with-temp-buffer
    (insert "[test]")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "[test]"))))

(ert-deftest donky-mark-outer-double-quote ()
  "Marks content including double quotes."
  (with-temp-buffer
    (insert "\"quoted\"")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "\"quoted\""))))

(ert-deftest donky-mark-outer-single-quote ()
  "Marks content including single quotes."
  (with-temp-buffer
    (insert "'quoted'")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "'quoted'"))))

(ert-deftest donky-mark-outer-angle ()
  "Marks content including angle brackets."
  (with-temp-buffer
    (insert "<tag>")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "<tag>"))))

(ert-deftest donky-mark-outer-underscore ()
  "Marks content including underscores."
  (with-temp-buffer
    (insert "_italic_")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "_italic_"))))

(ert-deftest donky-mark-outer-asterisk ()
  "Marks content including asterisks."
  (with-temp-buffer
    (insert "*bold*")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "*bold*"))))

(ert-deftest donky-mark-outer-tilde ()
  "Marks content including tildes."
  (with-temp-buffer
    (insert "~strike~")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "~strike~"))))

(ert-deftest donky-mark-outer-equals ()
  "Marks content including equals signs."
  (with-temp-buffer
    (insert "=math=")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "=math="))))

(ert-deftest donky-mark-outer-plus ()
  "Marks content including plus signs."
  (with-temp-buffer
    (insert "+code+")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "+code+"))))

(ert-deftest donky-mark-outer-dollar ()
  "Marks content including dollar signs."
  (with-temp-buffer
    (insert "$latex$")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "$latex$"))))

(ert-deftest donky-mark-outer-colon ()
  "Marks content including colons."
  (with-temp-buffer
    (insert ":date:")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   ":date:"))))

(ert-deftest donky-mark-outer-slash ()
  "Marks content including slashes."
  (with-temp-buffer
    (insert "/path/")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "/path/"))))

(ert-deftest donky-mark-outer-backtick ()
  "Marks content including backticks."
  (with-temp-buffer
    (insert "`inline`")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "`inline`"))))

(ert-deftest donky-mark-outer-edge-empty ()
  "Empty braces produce minimal selection including both delimiters."
  (with-temp-buffer
    (insert "{}")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "{}"))))

(ert-deftest donky-mark-outer-edge-no-close ()
  "Unclosed delimiter raises error."
  (with-temp-buffer
    (insert "{unclosed")
    (goto-char 1)
    (should-error (donky-mark-outer) :type 'error)))

(ert-deftest donky-mark-outer-edge-nested ()
  "Nested delimiters select innermost pair including delimiters."
  (with-temp-buffer
    (insert "{{inner}}")
    (goto-char 2)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "{inner}"))))

(ert-deftest donky-mark-outer-edge-multiline ()
  "Multiline content including delimiters selected."
  (with-temp-buffer
    (insert "{line1\nline2}")
    (goto-char 1)
    (donky-mark-outer)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "{line1\nline2}"))))

(ert-deftest donky-mark-outer-edge-has-mark ()
  "Mark is set after command."
  (with-temp-buffer
    (insert "{content}")
    (goto-char 1)
    (donky-mark-outer)
    (should (mark))))

(ert-deftest donky-mark-outer-edge-region-valid ()
  "Region beginning is less than region end."
  (with-temp-buffer
    (insert "{valid}")
    (goto-char 1)
    (donky-mark-outer)
    (should (< (region-beginning) (region-end)))))

;;; donky-mark-outer-test.el ends here
