;*=====================================================================*/
;*    serrano/prgm/project/hop/3.0.x/etc/hopjs.el                      */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Sun May 25 13:05:16 2014                          */
;*    Last change :  Wed Sep 16 19:32:34 2015 (serrano)                */
;*    Copyright   :  2014-15 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    HOPJS customization of the standard js-mode                      */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The package                                                      */
;*---------------------------------------------------------------------*/
(provide 'hopjs)
(require 'js)

(defcustom hopjs-indent-level-html 2
  "Number of spaces for each indentation step in `js-mode'."
  :type 'integer
  :safe 'integerp
  :group 'js)

;*---------------------------------------------------------------------*/
;*    hopjs-mode-hook ...                                              */
;*---------------------------------------------------------------------*/
(defun hopjs-mode-hook ()
  ;; syntax
  (hopjs-syntax)
  ;; key bindings
  (hopjs-key-bindings)
  ;; font lock
  (font-lock-add-keywords nil hopjs-font-lock-keywords)
  ;; custom beginning of defun
;*   (setq beginning-of-defun-function 'hopjs-beginning-of-defun)      */
;*   (setq end-of-defun-function 'hopjs-end-of-defun)                  */
  ;; user hooks
  (run-hooks 'hopjs-mode-hook))

;*---------------------------------------------------------------------*/
;*    hopjs-syntax ...                                                 */
;*---------------------------------------------------------------------*/
(defun hopjs-syntax ()
  "Syntax table for `hopjs-mode'."
  (let ((table (syntax-table)))
    (modify-syntax-entry ?\` "\"    " table)
    table))

;*---------------------------------------------------------------------*/
;*    font-lock ...                                                    */
;*---------------------------------------------------------------------*/
(defconst hopjs-font-lock-keywords
  (list (list "^\\s-*\\(service\\)\\(?:\\s-+\\|(\\)" 1 'font-lock-keyword-face)
	(cons ".post\\(Sync\\)?" 'font-lock-face-2)
	(cons "</?[a-zA-Z0-9_.]+[ ]*>\\|[ ]*/>\\|<[^ /]*/>" 'font-lock-face-9)
	(list "\\(</?[a-zA-Z0-9_.:]+\\)[ ]+[a-zA-Z0-9_]" 1 'font-lock-face-9)
	(cons "<!--\\([^-]\\|-[^-]\\|--[^>]\\)+-[-]+>" 'font-lock-comment-face)
	(list "[}\"][ ]*\\(>\\)" 1 'font-lock-face-9)
	(cons "$\{[^ \t\r\n{}]*\}" 'font-lock-face-2)
	(list "\\([$]\\){" 1 'font-lock-face-2)
	(list "\\([~]\\){" 1 'font-lock-face-3)
	(cons "[0-9a-zA-Z_-]*:" 'font-lock-face-10)
	(list (concat "^\\s-*\\(?:service\\)\\s-+\\(" js--name-re "\\)") 1 'font-lock-function-name-face)))

;*---------------------------------------------------------------------*/
;*    hopjs-key-bindings ...                                           */
;*---------------------------------------------------------------------*/
(defun hopjs-key-bindings ()
  (let ((map (current-local-map)))
    (define-key map "\C-m" 'hopjs-return)
    (define-key map "\e\C-m" 'newline)
    (local-unset-key "\ee")
    (define-key map "\e\C-q" 'hopjs-indent-statement)
    (local-unset-key "}")
    (define-key map "}" 'hopjs-electric-brace)
    (local-unset-key ")")
    (define-key map ")" 'hopjs-electric-paren)
    (local-unset-key ">")
    (define-key map ">" 'hopjs-electric-abra)))

;*---------------------------------------------------------------------*/
;*    hopjs-re-open-tag ...                                            */
;*---------------------------------------------------------------------*/
(defconst hopjs-re-open-tag
  "<[a-zA-Z_$][a-zA-Z_$0-9.]*[^<>/{]*")
(defconst hopjs-re-close-tag
  "</[a-zA-Z_$][a-zA-Z_$0-9.]*[ ]*>")
(defconst hopjs-re-end-tag
  "/>")
(defconst hopjs-re-code
  "{")
(defconst hopjs-re-tag
  (concat hopjs-re-open-tag
	  "\\|" hopjs-re-close-tag
	  "\\|" hopjs-re-end-tag
	  "\\|" hopjs-re-code))

(defconst hopjs-re-entering-html
  "\\(var[ \t ]*\\)?[a-zA-Z_$][:.0-9a-zA-Z_$]+[ \t]*[(= ]?[ \t]*<\\([^>]\\|[^/]>\\)")

(defconst hopjs-re-special-tag
  "<\\(link\\|LINK\\)")
  
;*---------------------------------------------------------------------*/
;*    debugging                                                        */
;*---------------------------------------------------------------------*/
(defun hopjs-debug (fmt &rest l)
  (when hopjs-debug (apply 'message fmt l)))

(defconst hopjs-debug t)

;*---------------------------------------------------------------------*/
;*    call-sans-debug ...                                              */
;*---------------------------------------------------------------------*/
(defun call-sans-debug (f &rest l)
  (let ((dbg hopjs-debug))
    (setq hopjs-debug nil)
    (let ((tmp (apply f l)))
      (setq hopjs-debug dbg)
      tmp)))

;*---------------------------------------------------------------------*/
;*    hopjs-electric-brace ...                                         */
;*---------------------------------------------------------------------*/
(defun hopjs-electric-brace ()
  "Insert and indent line."
  (interactive)
  (insert "}")
  (indent-for-tab-command))

;*---------------------------------------------------------------------*/
;*    hopjs-electric-paren ...                                         */
;*---------------------------------------------------------------------*/
(defun hopjs-electric-paren ()
  "Insert and indent line."
  (interactive)
  (insert ")")
  (indent-for-tab-command))

;*---------------------------------------------------------------------*/
;*    hopjs-electric-abra ...                                          */
;*---------------------------------------------------------------------*/
(defun hopjs-electric-abra ()
  "Insert and indent line."
  (interactive)
  (insert ">")
  (indent-for-tab-command))

;*---------------------------------------------------------------------*/
;*    hopjs-indent-statement ...                                       */
;*---------------------------------------------------------------------*/
(defun hopjs-indent-statement ()
  "Indent curent statement."
  (interactive)
  (save-excursion
    (c-beginning-of-statement
     0
     (save-excursion
       (hopjs-beginning-of-defun)
       (point))
     nil)
    (let ((start (point)))
      (c-forward-sexp)
      (let ((end (point)))
	(indent-region start end)))))

;*---------------------------------------------------------------------*/
;*    hopjs-return ...                                                 */
;*---------------------------------------------------------------------*/
(defun hopjs-return (&optional dummy)
   "On indent automatiquement sur un RET.
usage: (js-return)  -- [RET]"
   (interactive)
   (if (= (point) 1)
       (newline)
     (newline-and-indent)))

;* {*---------------------------------------------------------------------*} */
;* {*    hopjs-beginning-of-defun ...                                     *} */
;* {*---------------------------------------------------------------------*} */
;* (defun hopjs-beginning-of-defun (pos)                               */
;*   (interactive "d")                                                 */
;*   (let ((res 'loop))                                                */
;*     (while (eq res 'loop)                                           */
;*       (beginning-of-defun)                                          */
;*       (let ((defpos (point)))                                       */
;* 	(cond                                                          */
;* 	 ((<= defpos (point-min))                                      */
;* 	  (setq res nil))                                              */
;* 	 ((search-forward "{" pos t)                                   */
;* 	  (forward-char -1)                                            */
;* 	  (condition-case nil                                          */
;* 	      (progn                                                   */
;* 		(forward-sexp 1)                                       */
;* 		(if (> (point) pos)                                    */
;* 		    (progn                                             */
;* 		      (goto-char defpos)                               */
;* 		      (setq res t))                                    */
;* 		  (goto-char defpos)))                                 */
;* 	    (error                                                     */
;* 	     (progn                                                    */
;* 	       (goto-char defpos)                                      */
;* 	       (setq res t)                                            */
;* 	       nil))))                                                 */
;* 	 (t                                                            */
;* 	  (setq res nil)))))                                           */
;*     res))                                                           */
	      
;*---------------------------------------------------------------------*/
;*    hopjs--indent-operator-re ...                                    */
;*---------------------------------------------------------------------*/
(defconst hopjs--indent-operator-re 
  (concat "[-+*/%=&^|?:.]\\([^-+*/]\\|$\\)\\|^<$\\|^>$\\|"
          (js--regexp-opt-symbol '("in" "instanceof")))
  "Regexp matching operators that affect indentation of continued expressions.")

(defun js--looking-at-operator-p ()
  "Return non-nil if point is on a JavaScript operator, other than a comma."
  (save-match-data
    (and (looking-at hopjs--indent-operator-re)
         (or (not (looking-at ":"))
             (save-excursion
               (and (js--re-search-backward "[?:{]\\|\\_<case\\_>" nil t)
                    (looking-at "?")))))))

(defun js--proper-indentation (parse-status)
  "Return the proper indentation for the current line."
  (save-excursion
    (back-to-indentation)
    (cond ((nth 4 parse-status)    ; inside comment
           (js--get-c-offset 'c (nth 8 parse-status)))
          ((nth 3 parse-status) 0) ; inside string
          ((eq (char-after) ?#) 0)
          ((save-excursion (js--beginning-of-macro)) 4)
          ;; Indent array comprehension continuation lines specially.
          ((let ((bracket (nth 1 parse-status))
                 beg)
             (and bracket
                  (not (js--same-line bracket))
                  (setq beg (js--indent-in-array-comp bracket))
                  ;; At or after the first loop?
                  (>= (point) beg)
                  (js--array-comp-indentation bracket beg))))
	  ((js--html-statement-indentation))
          ((js--ctrl-statement-indentation))
          ((js--multi-line-declaration-indentation))
          ((nth 1 parse-status)
	   ;; A single closing paren/bracket should be indented at the
	   ;; same level as the opening statement. Same goes for
	   ;; "case" and "default".
           (let ((same-indent-p (looking-at "[]})]"))
                 (switch-keyword-p (looking-at "default\\_>\\|case\\_>[^:]"))
                 (continued-expr-p (js--continued-expression-p)))
             (goto-char (nth 1 parse-status)) ; go to the opening char
             (if (looking-at "[({[]\\s-*\\(/[/*]\\|$\\)")
                 (progn ; nothing following the opening paren/bracket
                   (skip-syntax-backward " ")
                   (when (eq (char-before) ?\)) (backward-list))
                   (back-to-indentation)
                   (let* ((in-switch-p (unless same-indent-p
                                         (looking-at "\\_<switch\\_>")))
                          (same-indent-p (or same-indent-p
                                             (and switch-keyword-p
                                                  in-switch-p)))
                          (indent
                           (cond (same-indent-p
                                  (current-column))
                                 (continued-expr-p
                                  (+ (current-column) (* 2 js-indent-level)
                                     js-expr-indent-offset))
                                 (t
                                  (+ (current-column) js-indent-level
                                     (pcase (char-after (nth 1 parse-status))
                                       (?\( js-paren-indent-offset)
                                       (?\[ js-square-indent-offset)
                                       (?\{ js-curly-indent-offset)))))))
                     (if in-switch-p
                         (+ indent js-switch-indent-offset)
                       indent)))
               ;; If there is something following the opening
               ;; paren/bracket, everything else should be indented at
               ;; the same level.
               (unless same-indent-p
                 (forward-char)
                 (skip-chars-forward " \t"))
               (current-column))))

          ((js--continued-expression-p)
           (+ js-indent-level js-expr-indent-offset))
          (t 0))))

;*---------------------------------------------------------------------*/
;*    hopjs-html-p ...                                                 */
;*---------------------------------------------------------------------*/
(defun hopjs-html-p (pos)
  (interactive "d")
  (hopjs-debug ">>> hopjs-html-p pos=%d" pos)
  (save-excursion
    (let ((loop 'loop)
	  (open 0)
	  (be (progn (hopjs-beginning-of-defun) (point))))
      (hopjs-debug "~~~ hopjs-html-p be=%s" be)
      (hopjs-debug "~~~ hopjs-html-p, loop=%s be=%d" loop be)
      (when (eq loop 'loop)
	(goto-char be)
	(while (eq loop 'loop)
	  (if (re-search-forward hopjs-re-tag pos t)
	      (let ((next (match-end 0)))
		(hopjs-debug "--- hopjs-html-p open=%d point=%s next=%d match=\"%s\""
			     open (point) next
			 (buffer-substring
			  (match-beginning 0) (match-end 0)))
		(goto-char (match-beginning 0))
		(cond
		 ((memq (get-text-property (point) 'face)
			'(font-lock-comment-face font-lock-string-face))
		  (hopjs-debug "     (in-comment/string)")
		  (goto-char next))
		 ((looking-at hopjs-re-code)
		  (condition-case ()
		      (let ((p (save-excursion (forward-sexp 1) (point))))
			(hopjs-debug "    (re-code p=%s pos=%s)" p pos)
			(if (> p pos)
			    (progn
			      (setq open 0)
			      (forward-char 1))
			  (goto-char p)))
		    (error
		     (forward-char 1))))
		 ((looking-at hopjs-re-open-tag)
		  (setq open (+ open 1))
		  (hopjs-debug "    (re-open-tag)")
		  (goto-char next))
		 ((looking-at hopjs-re-close-tag)
		  (hopjs-debug "    (re-close-tag)")
		  (setq open (- open 1))
		  (goto-char next))
		 ((looking-at hopjs-re-end-tag)
		  (hopjs-debug "    (re-end-tag)")
		  (setq open (- open 1))
		  (goto-char next))
		 (t
		  (forward-char 1)
		  (forward-sexp 1)
		  (hopjs-debug "!!! hopjs-html-p forward=%s" (point)))))
	    (setq loop nil))))
      (hopjs-debug "<<< hopjs-html-p pos=%d open=%s %s -> %s" pos open hopjs-debug
		   (> open 0))
      (> open 0))))

;*---------------------------------------------------------------------*/
;*    hopjs-html-line-type ...                                         */
;*---------------------------------------------------------------------*/
(defun hopjs-html-line-type ()
  (interactive)
  (save-excursion
    (beginning-of-line)
    (back-to-indentation)
    (cond
     ((looking-at "$")
      ;; empty
      'newline)
     ((looking-at "[ \t]+$")
      ;; empty line
      'blank)
     ((looking-at hopjs-re-entering-html)
      ;; entering
      'entering)
     ((looking-at "<\\([^>/\n]\\|/[^>]\\)*/>[ \t]*$")
      ;; standlone tag
      'tag)
     ((looking-at "<[a-zA-Z_$][:.0-9a-zA-Z_$]*[ ]+\\([^>\n]\\)[^>]*$")
      ;; open tag + attribute
      (if (looking-at hopjs-re-special-tag) 'tag 'otag-attr))
     ((looking-at "\\([^<>\n=]+=[^<>\n=]+[ \t]*\\)+/>[ \t]*$")
      ;; attribute + closing
      'attr-tag)
     ((looking-at "\\([^<>\n=]+=[^<>\n=]+[ \t]*\\)+>[ \t]*$")
      ;; attribute + tag
      'attr-otag)
     ((looking-at "\\([^<>\n]+=[^<>\n]+[ \t]*\\)+$")
      ;; attribute
      'attr)
     ((looking-at "</[^>]*>[ \t;)}]*$")
      ;; closing
      'ctag)
     ((looking-at "<\\([a-zA-Z_$][:.0-9a-zA-Z_$]*\\).*</\\1>[ \t]*$")
      ;; single line open/closing
      'tag)
     ((looking-at "<!--\\([^-]\\|-[^-]\\|--[^>]\\)+-->[ \t]*$")
      ;; comment
      'comment)
     ((looking-at "<!--")
      ;; open comment
      'ocomment)
     ((looking-at "-->[ \t]*$")
      ;; close comment
      'comment)
     ((looking-at "<\\([^/<>]\\|/[^>]\\)+\\(>\\| \\)$")
      ;; opening
      (if (looking-at hopjs-re-special-tag) 'tag 'otag))
     ((looking-at "<\\([^/<>]\\|/[^>]\\)+>\\([^/]\\|/[^>]\\)*$")
      ;; opening with content
      (if (looking-at hopjs-re-special-tag) 'tag 'otag))
     ((looking-at "~{")
      ;; script code
      'script)
     (t
      (save-excursion
	(let ((min (point)))
	  (end-of-line)
	  (if (re-search-backward "<" min t)
	      (progn
		;; check of a closing tag at eol
		(goto-char (match-beginning 0))
		(cond
		 ((looking-at "</[^>]*>[ \t;]*$") 'ctag)
		 (t 'text)))
	    ;; plain text
	    'text)))))))

;*---------------------------------------------------------------------*/
;*    hopjs-goto-html-line ...                                         */
;*---------------------------------------------------------------------*/
(defun hopjs-goto-html-line (types pmin attr-or-tag goto-prev in-attr-tag)
  (hopjs-debug "### hopjs-goto-html-line point=%s pmin=%s attr-or-tag=%s types=%s"
	       (point) pmin attr-or-tag types)
  (if (> (point) pmin)
      (progn
	(when goto-prev (previous-line))
	(beginning-of-line)
	(back-to-indentation)
	(cond
	 ((call-sans-debug 'hopjs-html-p (point))
	  (let ((type (hopjs-html-line-type)))
	    (hopjs-debug "###### hopjs-goto-html-line point=%s type=%s attr-or-tag=%s"
			 (point) type attr-or-tag)
	    (cond
	     ((memq type types)
	      (goto-char (match-beginning attr-or-tag))
	      (if (and in-attr-tag (memq type '(otag otag-attr))) 'tag type))
	     ((eq type 'attr-tag)
	      (hopjs-goto-html-line types pmin attr-or-tag t t))
	     (t
	      (hopjs-goto-html-line types pmin attr-or-tag t in-attr-tag)))))
	 ((eq (hopjs-html-line-type) 'entering)
	  (hopjs-debug "###### hopjs-goto-html-line entering...")
	  (if (memq 'entering types)
	      (progn
		(goto-char (match-beginning attr-or-tag))
		'entering)
	    (hopjs-goto-html-line types pmin attr-or-tag t nil)))
	 (t
	  (hopjs-debug "###### hopjs-goto-html-line else...")
	  (condition-case nil
	      (progn
		(end-of-line)
		(backward-sexp 1)
		(hopjs-goto-html-line types pmin attr-or-tag nil nil))
	    (error
	     (hopjs-debug "!!!hopjs-goto-html-line: cannot forward sexp %s" (point))
	     'text)))))
    'text))

;*---------------------------------------------------------------------*/
;*    hopjs-html-statement-indentation-text ...                        */
;*---------------------------------------------------------------------*/
(defun hopjs-html-statement-indentation-text ()
  (save-excursion
    (beginning-of-line)
    (previous-line)
    (back-to-indentation)
    (current-column)))

;*---------------------------------------------------------------------*/
;*    hopjs-html-statement-indentation-tag ...                         */
;*---------------------------------------------------------------------*/
(defun hopjs-html-statement-indentation-tag (ptype pmin)
  (case ptype
    ((attr-tag)
     (hopjs-goto-html-line '(otag otag-attr entering) pmin 0 t nil)
     (current-column))
    ((ctag)
     (current-column))
    ((tag)
     (current-column))
    (t
     (+ (current-column) hopjs-indent-level-html))))

;*---------------------------------------------------------------------*/
;*    js--html-statement-indentation ...                               */
;*---------------------------------------------------------------------*/
(defun js--html-statement-indentation ()
  (hopjs-debug ">>> js--html-statement-indentation %s" (point))
  (when (call-sans-debug 'hopjs-html-p (point))
    (let ((pmin (save-excursion (hopjs-beginning-of-defun) (point))))
      (save-excursion
	(let ((ltype (hopjs-html-line-type)))
	  (hopjs-debug "--- js--html-statement-indentation... in HTML %s type=%s"
		       (point) ltype)
	  (case ltype
	    ((text blank entering)
	     (back-to-indentation)
	     (hopjs-debug "<<<.1 js--html-statement-indentation... text -> %s"
			  (current-column))
	     (current-column))
	    ((newline)
	     (let ((ptype (hopjs-goto-html-line
			   '(otag otag-attr entering ctag ctag-attr tag text)
			   pmin 0 t nil)))
	       (hopjs-debug "<<<.2 js--html-statement-indentation... ltype=%s ptype=%s col=%s:%s"
			    ltype ptype (current-column) (point))
	       (if (eq ptype 'text)
		   ;; a newline after plain text
		   (hopjs-html-statement-indentation-text)
		 (hopjs-html-statement-indentation-tag ptype pmin))))
	    ((tag otag otag-attr script)
	     (let ((ptype (hopjs-goto-html-line
			   '(ctag otag otag-attr tag entering attr-tag)
			   pmin 0 t nil)))
	       (hopjs-debug "<<<.3 js--html-statement-indentation... ltype=%s ptype=%s col=%s:%s"
			    ltype ptype (current-column) (point))
	       (hopjs-html-statement-indentation-tag ptype pmin)))
	    ((ctag)
	     (let ((ptype (hopjs-goto-html-line
			   '(otag otag-attr entering ctag ctag-attr tag)
			   pmin 0 t nil)))
	       (hopjs-debug "<<<.4 js--html-statement-indentation... ltype=%s ptype=%s col=%s:%s"
			    ltype ptype (current-column) (point))
	       (case ptype
		 ((tag ctag ctag-attr tag)
		  (- (current-column) hopjs-indent-level-html))
		 ((otag otag-attr)
		  (current-column))
		 (t
		  (current-column)))))
	    ((comment ocomment)
	     (hopjs-debug "<<<.5 js--html-statement-indentation... ltype=%s ptype=%s col=%s:%s"
			  ltype ptype (current-column) (point))
	     (let ((ptype (hopjs-goto-html-line
			   '(otag otag-attr entering ctag attr-tag ctag-attr tag
				  comment ocomment comment)
			   pmin 0 t nil)))
	       (case ptype
		 ((comment ocomment tag)
		  (current-column))
		 ((otag attr-tag)
		  (+ (current-column) hopjs-indent-level-html))
		 (else
		  (current-column)))))
	    (t
	     (current-column))))))))

;*---------------------------------------------------------------------*/
;*    hopjs-search-code-regexp ...                                     */
;*---------------------------------------------------------------------*/
(defun hopjs-search-code-regexp (regexp search key)
  (save-excursion
    (let ((res '_)
	  (pos (point)))
      (while (eq res '_)
	(if (funcall search regexp nil t)
	    (let ((beg (match-beginning 0)))
	      (cond
	       ((eq (get-text-property beg 'face) key)
		(setq res t))
	       ((> pos (point))
		;; backward search
		(if (> (point) (point-min))
		    (goto-char (1- beg))
		  (setq res nil)))
	       (t
		;; forward search
		(if (< (point) (point-max))
		    (forward-char)
		  (setq res nil)))))
	  (setq res nil)))
      res)))
      
;*---------------------------------------------------------------------*/
;*    hopjs-search-previous-function ...                               */
;*---------------------------------------------------------------------*/
(defun hopjs-search-previous-function ()
  (when (hopjs-search-code-regexp
	 "\\_<\\(function\\|service\\)\\_>"
	 're-search-backward 
	 'font-lock-keyword-face)
    (let ((beg (match-beginning 0)))
      (goto-char beg)
      (if (hopjs-search-code-regexp "{" 're-search-forward nil)
	  ;; and we have found a open bracket
	  (condition-case nil
	      (progn
		(goto-char (match-beginning 0))
		(forward-sexp 1)
		(cons beg (point)))
	    (error
	     (cons beg beg)))
	;; no bracket found...
	nil))))

;*---------------------------------------------------------------------*/
;*    hopjs-goto-defun ...                                             */
;*---------------------------------------------------------------------*/
(defun hopjs-goto-defun (ref pos)
  (let ((loop t))
    (while loop
      (let ((fun (hopjs-search-previous-function)))
	(cond
	   ((not fun)
	    (setq loop nil))
	   ((> (cdr fun) pos)
	    (progn
	      (setq loop nil)
	      (goto-char (funcall ref fun))))
	   ((> (car fun) (point-min))
	    (goto-char (1- (car fun))))
	   (t
	    (setq loop nil)))))))

;*---------------------------------------------------------------------*/
;*    hopjs-beginning-of-defun ...                                     */
;*---------------------------------------------------------------------*/
(defun hopjs-beginning-of-defun (&optional arg)
  (unless arg (setq arg 1))
  (while (> arg 0)
    (setq arg (1- arg))
    (hopjs-goto-defun 'car (point))))

;*---------------------------------------------------------------------*/
;*    hopjs-end-of-defun ...                                           */
;*---------------------------------------------------------------------*/
(defun hopjs-end-of-defun (&optional arg)
  (unless arg (setq arg 1))
  (while (> arg 0)
    (setq arg (1- arg))
    (hopjs-goto-defun 'cdr (point))))
  
;*---------------------------------------------------------------------*/
;*    init                                                             */
;*---------------------------------------------------------------------*/
;; (autoload 'hopjs-mode-hook "hopjs" "Hop.js javascript mode hook" t)
;; (add-hook 'js-mode-hook 'hopjs-mode-hook)
