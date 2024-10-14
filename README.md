[![REUSE status](https://api.reuse.software/badge/git.sr.ht/~swflint/org-inline-pdfcomment)](https://api.reuse.software/info/git.sr.ht/~swflint/org-inline-pdfcomment)
[![MELPA](https://melpa.org/packages/org-inline-pdfcomment-badge.svg)](https://melpa.org/#/org-inline-pdfcomment)

# org-inline-pdfcomment

This package provides support for exporting org-inlinetask elements as PDF comments using the [pdfcomment.sty](https://ctan.org/pkg/pdfcomment) package for LaTeX.
It may be enabled as follows:

```elisp
(require 'org-inline-pdfcomment)
(org-inline-pdfcomment-insinuate)
```

Inline tasks will then be exported as PDF comments.

**NOTE**: Loading this packages will load `org-inlinetask` if it is not loaded.

## Output Customization

  - `org-inline-pdfcomment-type` can be either of the symbols `inline` or `margin`, or a string which will be used as the comment command.
  - `org-inline-pdfcomment-options` is an alist of pdfcomment options.
    For more information about these, see the docstring or the pdfcomment.sty manual.
  - `org-inline-pdfcomment-format-todo-function` is a function used to format the todo state.
  - `org-inline-pdfcomment-format-tags-function` is a function used to format the task tags.

## Bug Reports and Patches

If you find an error or have a patch to improve these packages, please send an email to `~swflint/emacs-utilities@lists.sr.ht`.
