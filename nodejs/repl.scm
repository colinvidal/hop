;*=====================================================================*/
;*    serrano/prgm/project/hop/3.0.x/nodejs/repl.scm                   */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Sun Oct  6 08:22:43 2013                          */
;*    Last change :  Thu May 15 18:16:56 2014 (serrano)                */
;*    Copyright   :  2013-14 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    NodeJS like REPL                                                 */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __nodejs_repl

   (library hopscript js2scheme)

   (import __nodejs_require)
   
   (export (repljs ::JsGlobalObject ::WorkerHopThread)))

;*---------------------------------------------------------------------*/
;*    prompt ...                                                       */
;*---------------------------------------------------------------------*/
(define (prompt)
   (display "> ")
   (flush-output-port (current-output-port)))

;*---------------------------------------------------------------------*/
;*    repljs ...                                                       */
;*---------------------------------------------------------------------*/
(define (repljs %this %worker)
   (let ((old-intrhdl (get-signal-handler sigint))
	 (mod (eval-module))
	 (console (js-get %this 'console %this)))
      ;; enter the read-eval-print loop
      (unwind-protect
	 (let loop ()
	    (bind-exit (re-enter-internal-repl)
	       ;; we setup ^C interupt
	       (letrec ((intrhdl (lambda (n)
				    (print "CTRL-C")
				    (notify-interrupt n)
				    ;; we flush current input port
				    (reset-console! (current-input-port))
				    ;; we restore signal handling
				    (sigsetmask 0)
				    (re-enter-internal-repl #unspecified))))
		  (signal sigint intrhdl))
	       ;; and we loop until eof
	       (newline)
	       (let luup ()
		  (with-handler
		     (lambda (e)
			(cond
			   ((isa? e JsError)
			    (exception-notify e))
			   ((isa? e &error)
			    (error-notify e)
			    (with-access::&error e (obj)
			       (when (eof-object? obj)
				  (reset-eof (current-input-port))))))
			(sigsetmask 0)
			(luup))
		     (let liip ()
			(prompt)
			(let ((exp (jsread-and-compile)))
			   (if (null? exp)
			       (quit)
			       (let ((v (js-worker-exec %worker
					   (lambda ()
					      (let ((v ((eval! exp) %this)))
						 (jsprint v console %this))))))
				  (liip))))))))
	    (loop))
	 (if (procedure? old-intrhdl)
	     (signal sigint old-intrhdl)
	     (signal sigint (lambda (n) (exit 0)))))))

;*---------------------------------------------------------------------*/
;*    jsprint ...                                                      */
;*---------------------------------------------------------------------*/
(define (jsprint exp console %this)
   (js-call1 %this (js-get console 'log %this) console exp))

;*---------------------------------------------------------------------*/
;*    jsread-and-compile ...                                           */
;*---------------------------------------------------------------------*/
(define (jsread-and-compile)
   (j2s-compile (current-input-port)
      :parser 'repl
      :driver (j2s-eval-driver)
      :filename "repl.js"))   