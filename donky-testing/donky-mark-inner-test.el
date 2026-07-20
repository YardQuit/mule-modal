;;; donky-mark-inner-test.el --- Tests for donky-mark-inner -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'donky)

(ert-deftest donky-mark-inner-braces ()
  "Marks content inside braces, excluding delimiters."
  (with-temp-buffer
    (insert "{hello}")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "hello"))))

(ert-deftest donky-mark-inner-parens ()
  "Marks content inside parens, excluding delimiters."
  (with-temp-buffer
    (insert "(world)")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "world"))))

(ert-deftest donky-mark-inner-brackets ()
  "Marks content inside brackets, excluding delimiters."
  (with-temp-buffer
    (insert "[test]")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "test"))))

(ert-deftest donky-mark-inner-double-quote ()
  "Marks content inside double quotes, excluding quotes."
  (with-temp-buffer
    (insert "\"quoted\"")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "quoted"))))

(ert-deftest donky-mark-inner-single-quote ()
  "Marks content inside single quotes, excluding quotes."
  (with-temp-buffer
    (insert "'quoted'")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "quoted"))))

(ert-deftest donky-mark-inner-angle ()
  "Marks content inside angle brackets, excluding brackets."
  (with-temp-buffer
    (insert "<tag>")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "tag"))))

(ert-deftest donky-mark-inner-underscore ()
  "Marks content inside underscores, excluding underscores."
  (with-temp-buffer
    (insert "_italic_")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "italic"))))

(ert-deftest donky-mark-inner-asterisk ()
  "Marks content inside asterisks, excluding asterisks."
  (with-temp-buffer
    (insert "*bold*")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "bold"))))

(ert-deftest donky-mark-inner-tilde ()
  "Marks content inside tildes, excluding tildes."
  (with-temp-buffer
    (insert "~strike~")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "strike"))))

(ert-deftest donky-mark-inner-equals ()
  "Marks content inside equals signs, excluding equals."
  (with-temp-buffer
    (insert "=math=")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "math"))))

(ert-deftest donky-mark-inner-plus ()
  "Marks content inside plus signs, excluding pluses."
  (with-temp-buffer
    (insert "+code+")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "code"))))

(ert-deftest donky-mark-inner-dollar ()
  "Marks content inside dollar signs, excluding dollars."
  (with-temp-buffer
    (insert "$latex$")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "latex"))))

(ert-deftest donky-mark-inner-colon ()
  "Marks content inside colons, excluding colons."
  (with-temp-buffer
    (insert ":date:")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "date"))))

(ert-deftest donky-mark-inner-slash ()
  "Marks content inside slashes, excluding slashes."
  (with-temp-buffer
    (insert "/path/")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "path"))))

(ert-deftest donky-mark-inner-backtick ()
  "Marks content inside backticks, excluding backticks."
  (with-temp-buffer
    (insert "`inline`")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "inline"))))

(ert-deftest donky-mark-inner-edge-empty ()
  "Empty braces produce no selectable content, raising error."
  (with-temp-buffer
    (insert "{}")
    (goto-char 1)
    (should-error (donky-mark-inner) :type 'error)))

(ert-deftest donky-mark-inner-edge-no-close ()
  "Unclosed delimiter raises error."
  (with-temp-buffer
    (insert "{unclosed")
    (goto-char 1)
    (should-error (donky-mark-inner) :type 'error)))

(ert-deftest donky-mark-inner-edge-nested ()
  "Nested delimiters select innermost pair content."
  (with-temp-buffer
    (insert "{{inner}}")
    (goto-char 2)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "inner"))))

(ert-deftest donky-mark-inner-edge-multiline ()
  "Multiline content between delimiters selected."
  (with-temp-buffer
    (insert "{line1\nline2}")
    (goto-char 1)
    (donky-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "line1\nline2"))))

(ert-deftest donky-mark-inner-edge-has-mark ()
  "Mark is set after command."
  (with-temp-buffer
    (insert "{content}")
    (goto-char 1)
    (donky-mark-inner)
    (should (mark))))

(ert-deftest donky-mark-inner-edge-region-valid ()
  "Region beginning is less than region end."
  (with-temp-buffer
    (insert "{valid}")
    (goto-char 1)
    (donky-mark-inner)
    (should (< (region-beginning) (region-end)))))

;;; donky-mark-inner-test.el ends here
