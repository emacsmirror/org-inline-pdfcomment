;;; org-inline-pdfcomment.el --- Export Support for Inline Tasks as PDF Comments  -*- lexical-binding: t; -*-

;; Author: Samuel W. Flint <me@samuelwflint.com>
;; Version: 0.0.1
;; Homepage: https://git.sr.ht/~swflint/org-inline-pdfcomment
;; Keywords: docs, text
;; Package-Requires: ((emacs "24.4"))
;; SPDX-License-Identifier: GPL-3.0-or-later
;; SPDX-FileCopyrightText: 2024 Samuel W. Flint <me@samuelwflint.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; TODO

;;; Code:

(require 'ox-latex)


;;; Customizations

(defgroup org-inline-pdfcomment nil
  "TODO"
  :group 'org-export-latex
  :prefix "org-inline-pdfcomment-"
  :link '(url-link :tag "Sourcehut" "https://git.sr.ht/~swflint/org-inline-pdfcomment")
  :link '(emacs-library-link :tag "Library Source" "org-inline-pdfcomment.el"))

(defcustom org-inline-pdfcomment-type 'inline
  "Type of pdfcomment to make.

Either `inline' (corresponding to \\pdfcomment),
`margin' (\\pdfmargincomment), or a string representing the name
of the command to use."
  :group 'org-inline-pdfcomment
  :type '(choice (const :tag "Inline Comment" inline)
                 (const :tag "Margin Comment" margin)
                 (string :tag "Custom Command")))

(defcustom org-inline-pdfcomment-options (list (cons "icon" "Note"))
  "Comment options.

These are options to the pdfcomment command.  Some of
these (subject in particular) may be overridden by values from
the document.

Known options are:

TODO Document me better...

 - avatar
 - style
 - subject
 - author
 - icon
 - color
 - opacity
 - open
 - hspace
 - voffset
 - hoffset
 - disable
 - date
 - timezone."
  :group 'org-inline-pdfcomment
  :type '(alist :key-type (string :tag "Option")
                :value-type (string :tag "Value")
                :options (((const :tag "avatar" "avatar") string)
                          ((const :tag "style" "style") string)
                          ((const :tag "subject" "subject") string)
                          ((const :tag "author" "author") string)
                          ((const :tag "icon" "icon") string)
                          ((const :tag "color" "color") string)
                          ((const :tag "opacity" "opacity") string)
                          ((const :tag "open" "open") string)
                          ((const :tag "hspace" "hspace") string)
                          ((const :tag "voffset" "voffset") string)
                          ((const :tag "hoffset" "hoffset") string)
                          ((const :tag "disable" "disable") string)
                          ((const :tag "date" "date") string)
                          ((const :tag "timezone" "timezone") string))))

(defcustom org-inline-pdfcomment-format-todo-function #'org-inline-pdfcomment-format-todo
  "Format TODO information for export.

This function should take three arguments, the todo state, the
type (symbols `todo', `done' or nil), and the priority (as a
number/character), and return a string representing them.  Note:
this should include any necessary separating suffix, as none is
provided during final comment formatting."
  :group 'org-inline-pdfcomment
  :type '(choice (function-item org-inline-pdfcomment-format-todo)
                 function))

(defcustom org-inline-pdfcomment-format-tags-function #'org-inline-pdfcomment-format-tags
  "Format tags for export.

This function should take a list of tags (or nil) and return a
string.  Note: this should include any separating prefix as
necessary, as none is provided during final comment formatting."
  :group 'org-inline-pdfcomment
  :type '(choice (function-item org-inline-pdfcomment-format-tags)
                 function))


;;; Export Function

(defun org-inline-pdfcomment-format-todo (state _type priority)
  "Format todo STATE given (numeric, character) PRIORITY for export.

Formatting is performed as follows:

 - If both STATE and PRIORITY are provided, format as
   \\='STATE (PRIORITY): \\='.
 - If only STATE is provided, format as \\='STATE: \\='
 - If only PRIORITY is provided, format as \\='(PRIORITY): \\='
 - In all other cases, return an empty string."
  (cond
   ((and (stringp state) (numberp priority)) (format "%s (%c): " state priority))
   ((stringp state) (format "%s: " state))
   ((numberp priority) (format "(%c): " priority))
   (t "")))

(defun org-inline-pdfcomment-format-tags (tags)
  "Format TAGS for export.

If no tags are given, an empty string will be returned.
Otherwise, format as: \\=' (tag1, tag2, ..., tagn)\\='."
  (if (null tags)
      ""
    (format " (%s)" (mapconcat #'identity tags ", "))))

(defun org-inline-pdfcomment--merge-options (options)
  "Merge OPTIONS with `org-inline-pdfcomment-options'."
  (let ((new-options (cl-copy-seq options)))
    (dolist (option org-inline-pdfcomment-options new-options)
      (unless (cl-member (car option) new-options :test #'string= :key #'car)
        (push option new-options)))))

(defun org-inline-pdfcomment-export (todo-state todo-type priority subject tags contents info)
  "Export inlinetask as PDF comment.

The PDF comment's subject will be taken from SUBJECT.  The author
will be taken from INFO if `:author' is present, otherwise from
the variable `user-full-name'.  This information will be merged
with `org-inline-pdf-comment-options' with local values taking
precendence.

TODO-STATE, TODO-TYPE, and PRIORITY will be formatted using
`org-inline-pdfcomment-format-todo-function'.

TAGS will be formatted using
`org-inline-pdf-comment-format-tags-function'.

The final comment will be formatted by concatenating todo
information (if present), the CONTENTS, and the tag
information (if present).

See also `org-latex-format-inline-task-function'."
  (let* ((todo-string (funcall org-inline-pdfcomment-format-todo-function
                               todo-state todo-type priority))
         (tags-string (funcall org-inline-pdfcomment-format-tags-function
                               tags))
         (author (or (plist-get info :author) user-full-name))
         (options-list (list (cons "author" author)
                             (cons "subject" subject)))
         (contents (concat todo-string (or contents "") tags-string)))
    (format "\\%s[%s]{%s}"
            (cond
             ((eq org-inline-pdfcomment-type 'inline) "pdfcomment")
             ((eq org-inline-pdfcomment-type 'margin) "pdfmargincomment")
             ((stringp org-inline-pdfcomment-type) org-inline-pdfcomment-type)
             (t "pdfcomment"))
            (mapconcat (lambda (pair)
                         (format "%s={%s}" (car pair) (cdr pair)))
                       options-list
                       ",")
            contents)))


;;; Installation Function

(defun org-inline-pdfcomment-insinuate ()
  "Install support for exporting inlinetasks using pdfcomment.sty."
  (setf org-latex-format-inlinetask-function #'org-inline-pdfcomment-export)
  (add-to-list 'org-latex-default-packages-alist '("" "pdfcomment" nil) t))


(provide 'org-inline-pdfcomment)
;;; org-inline-pdfcomment.el ends here
