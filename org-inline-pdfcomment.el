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



;;; Export Function

(defun org-inline-pdfcomment-export (todo todo-type priority name tags contents info)
  "TODO"
  (let* ((author (or (plist-get info :author) (user-full-name)))
         (options-list (list (cons "author" author)
                             (cons "icon" "Note")
                             (cons "subject" name))))
    ;; TODO Handle subject (name)
    ;; TODO handle TODO & todo-type
    ;; TODO Handle tags
    ;; TODO Color override
    ;; TODO Either pdfcomment or pdfmargincomment
    (format "\\pdfcomment[%s]{%s}"
            (mapconcat (lambda (pair)
                         (format "%s={%s}" (car pair) (cdr pair)))
                       options-list
                       ",")
            (or contents ""))))


;;; Installation Function

(defun org-inline-pdfcomment-insinuate ()
  "Install support for exporting inlinetasks using pdfcomment.sty."
  (setf org-latex-format-inlinetask-function #'org-inline-pdfcomment-export)
  (add-to-list 'org-latex-default-packages-alist '("" "pdfcomment" nil) t))


(provide 'org-inline-pdfcomment)
;;; org-inline-pdfcomment.el ends here
