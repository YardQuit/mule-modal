;;; mule-mark-inner-test.el --- Tests for mule-mark-inner -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'mule-modal)

(ert-deftest mule-mark-inner-braces ()
  "Marks content inside braces, excluding delimiters."
  (with-temp-buffer
    (insert "{hello}")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "hello"))))

(ert-deftest mule-mark-inner-parens ()
  "Marks content inside parens, excluding delimiters."
  (with-temp-buffer
    (insert "(world)")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "world"))))

(ert-deftest mule-mark-inner-brackets ()
  "Marks content inside brackets, excluding delimiters."
  (with-temp-buffer
    (insert "[test]")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "test"))))

(ert-deftest mule-mark-inner-double-quote ()
  "Marks content inside double quotes, excluding quotes."
  (with-temp-buffer
    (insert "\"quoted\"")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "quoted"))))

(ert-deftest mule-mark-inner-single-quote ()
  "Marks content inside single quotes, excluding quotes."
  (with-temp-buffer
    (insert "'quoted'")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "quoted"))))

(ert-deftest mule-mark-inner-angle ()
  "Marks content inside angle brackets, excluding brackets."
  (with-temp-buffer
    (insert "<tag>")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "tag"))))

(ert-deftest mule-mark-inner-underscore ()
  "Marks content inside underscores, excluding underscores."
  (with-temp-buffer
    (insert "_italic_")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "italic"))))

(ert-deftest mule-mark-inner-asterisk ()
  "Marks content inside asterisks, excluding asterisks."
  (with-temp-buffer
    (insert "*bold*")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "bold"))))

(ert-deftest mule-mark-inner-tilde ()
  "Marks content inside tildes, excluding tildes."
  (with-temp-buffer
    (insert "~strike~")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "strike"))))

(ert-deftest mule-mark-inner-equals ()
  "Marks content inside equals signs, excluding equals."
  (with-temp-buffer
    (insert "=math=")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "math"))))

(ert-deftest mule-mark-inner-plus ()
  "Marks content inside plus signs, excluding pluses."
  (with-temp-buffer
    (insert "+code+")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "code"))))

(ert-deftest mule-mark-inner-dollar ()
  "Marks content inside dollar signs, excluding dollars."
  (with-temp-buffer
    (insert "$latex$")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "latex"))))

(ert-deftest mule-mark-inner-colon ()
  "Marks content inside colons, excluding colons."
  (with-temp-buffer
    (insert ":date:")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "date"))))

(ert-deftest mule-mark-inner-slash ()
  "Marks content inside slashes, excluding slashes."
  (with-temp-buffer
    (insert "/path/")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "path"))))

(ert-deftest mule-mark-inner-backtick ()
  "Marks content inside backticks, excluding backticks."
  (with-temp-buffer
    (insert "`inline`")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "inline"))))

(ert-deftest mule-mark-inner-edge-empty ()
  "Empty braces produce no selectable content, raising error."
  (with-temp-buffer
    (insert "{}")
    (goto-char 1)
    (should-error (mule-mark-inner) :type 'error)))

(ert-deftest mule-mark-inner-edge-no-close ()
  "Unclosed delimiter raises error."
  (with-temp-buffer
    (insert "{unclosed")
    (goto-char 1)
    (should-error (mule-mark-inner) :type 'error)))

(ert-deftest mule-mark-inner-edge-nested ()
  "Nested delimiters select innermost pair content."
  (with-temp-buffer
    (insert "{{inner}}")
    (goto-char 2)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "inner"))))

(ert-deftest mule-mark-inner-edge-multiline ()
  "Multiline content between delimiters selected."
  (with-temp-buffer
    (insert "{line1\nline2}")
    (goto-char 1)
    (mule-mark-inner)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "line1\nline2"))))

(ert-deftest mule-mark-inner-edge-has-mark ()
  "Mark is set after command."
  (with-temp-buffer
    (insert "{content}")
    (goto-char 1)
    (mule-mark-inner)
    (should (mark))))

(ert-deftest mule-mark-inner-edge-region-valid ()
  "Region beginning is less than region end."
  (with-temp-buffer
    (insert "{valid}")
    (goto-char 1)
    (mule-mark-inner)
    (should (< (region-beginning) (region-end)))))

;;; mule-mark-inner-test.el ends here
