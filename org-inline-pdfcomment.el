;;; org-inline-pdfcomment.el --- Export Support for Inline Tasks as PDF Comments  -*- lexical-binding: t; -*-

;; Author: Samuel W. Flint <me@samuelwflint.com>
;; Version: 1.0.2
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

;; This package provides support for exporting org-inlinetask elements
;; as PDF comments using the pdfcomment.sty package for LaTeX
;; (https://ctan.org/pkg/pdfcomment).  It may be enabled as follows:
;;
;;     (require 'org-inline-pdfcomment)
;;     (org-inline-pdfcomment-insinuate)
;;
;; Inline tasks will then be exported as PDF comments.
;;
;; **NOTE**: Loading this packages will load `org-inlinetask' if it is
;; not loaded.
;;
;;;; Output Customization
;;
;;  - `org-inline-pdfcomment-type' can be either of the symbols
;;    `inline' or `margin', or a string which will be used as the
;;    comment command.
;;  - `org-inline-pdfcomment-options' is an alist of pdfcomment
;;    options.  For more information about these, see the docstring or
;;    the pdfcomment.sty manual.
;;  - `org-inline-pdfcomment-format-todo-function' is a function used
;;    to format the todo state.
;;  - `org-inline-pdfcomment-format-tags-function' is a function used
;;    to format the task tags.

;;; Code:

(require 'ox-latex)
(require 'org-inlinetask)


;;; Customizations

(defgroup org-inline-pdfcomment nil
  "Inline Task Export as PDF Comments."
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

 - avatar: an avatar defined with \\defineavatar.  This requires
   header commands in the export.
 - style: a style defined with \\definestyle.  This is similar to
   avatar.
 - subject: the subject of the note.  Autogenerated from the
   inline task, generally not worth setting manually.
 - author: The author of the note.  Taken from document author
   information first, then this value, and finally the variable
   `user-full-name'.
 - icon: which icon to use in the PDF to represent the
   comment.  Values which are known to work for all readers
   include:
    - Comment
    - Help
    - Paragraph
    - Key
    - NewParagraph
    - Insert
    - Note
 - color: an RGB triple ({R, G, B} as decimal values of 1) or
   xcolor name, representing the color of the annotation.
 - opacity: how opaque the annotation is (0 is transparent, 1.0
   is fully opaque, default value is 1.0).
 - open: Whether or not the pop up annotation is shown by
   default; default is \"false\".
 - hspace: horizontal space after PDF text annotations.
 - voffset, hoffset: vertical and horizontal offsets for the
   annotation.
 - disable: switches off an annotation, default is \"false\"."
  :group 'org-inline-pdfcomment
  :type '(alist :key-type (string :tag "Option")
                :value-type (string :tag "Value")
                :options (((const :tag "Avatar" "avatar") string)
                          ((const :tag "Style" "style") string)
                          ((const :tag "Subject" "subject") string)
                          ((const :tag "Author" "author") string)
                          ((const :tag "Icon" "icon") (choice (const "Comment")
                                                              (const "Help")
                                                              (const "Paragraph")
                                                              (const "Key")
                                                              (const "NewParagraph")
                                                              (const "Insert")
                                                              (const "Note")
                                                              (string :tag "Other Icon")))
                          ((const :tag "Color" "color") string)
                          ((const :tag "Opacity" "opacity") string)
                          ((const :tag "Open" "open") string)
                          ((const :tag "Hspace" "hspace") string)
                          ((const :tag "Voffset" "voffset") string)
                          ((const :tag "Hoffset" "hoffset") string)
                          ((const :tag "Disable" "disable") string)))
  :link '(url-link :tag "pdfcomment.sty documentation" "https://texdoc.org/serve/pdfcomment/0"))

(defcustom org-inline-pdfcomment-format-todo-function #'org-inline-pdfcomment-format-todo
  "Format todo information for export.

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

Comment type will be determined based on
`org-inline-pdfcomment-type'.  If it is `inline', \\pdfcomment
will be used; if it is `margin', \\pdfmargincomment will be used;
if it is a string, the string will be used directly.

The comment's subject will be generated by concatenating any todo
information with SUBJECT.  Todo information is formatted from
TODO-STATE, TODO-TYPE and PRIORITY using
`org-inline-pdfcomment-format-todo-function'.

The author of the comment will be based on either the `:author'
keyword in INFO or from the variable `user-full-name'.

The content of the comment will be generated by concatenating the
formatted subject (suffixed with \\=': \\='), CONTENTS, and
formatted tag information.  Tag information is formatted from
TAGS using `org-inline-pdfcomment-format-tags-function'.

Finally, comment export options will be generated by merging the
author and subject information with
`org-inline-pdfcomment-options'.  The locally generated options
will take precedence over this variable.

For more information, see the option
`org-latex-format-inline-task-function'."
  (let* ((todo-string (funcall org-inline-pdfcomment-format-todo-function
                               todo-state todo-type priority))
         (tags-string (funcall org-inline-pdfcomment-format-tags-function
                               tags))
         (author (or (mapconcat #'substring-no-properties
                                (plist-get info :author)
                                " and ")
                     (assoc "author" org-inline-pdfcomment-options #'string=)
                     user-full-name))
         (subject (concat todo-string subject))
         (options-list (org-inline-pdfcomment--merge-options
                        (list (cons "author" author)
                              (cons "subject" subject))))
         (contents (concat subject ": " (or contents "") tags-string)))
    (format "\\%s[%s]{%s}"
            (cond
             ((eq org-inline-pdfcomment-type 'inline) "pdfcomment")
             ((eq org-inline-pdfcomment-type 'margin) "pdfmargincomment")
             ((stringp org-inline-pdfcomment-type) org-inline-pdfcomment-type)
             (t "pdfcomment"))
            (mapconcat (lambda (pair)
                         (format (if (string-match-p (rx space) (cdr pair))
                                     "%s={%s}"
                                   "%s=%s")
                                 (car pair)
                                 (cdr pair)))
                       options-list
                       ",")
            contents)))


;;; Installation Function

(defun org-inline-pdfcomment-insinuate ()
  "Install support for exporting inlinetasks using pdfcomment.sty.

This will set `org-latex-format-inline-task-function' to
`org-inline-pdfcomment-export', and will append the pdfcomment
package to `org-latex-default-packages-alist' (without options,
and not required for snippet export)."
  (setf org-latex-format-inlinetask-function #'org-inline-pdfcomment-export)
  (add-to-list 'org-latex-default-packages-alist '("" "pdfcomment" nil) t))


(provide 'org-inline-pdfcomment)
;;; org-inline-pdfcomment.el ends here
