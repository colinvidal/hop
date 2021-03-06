;*=====================================================================*/
;*    serrano/prgm/project/hop/3.0.x/hopscript/service.scm             */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Thu Oct 17 08:19:20 2013                          */
;*    Last change :  Sun Sep 20 10:00:32 2015 (serrano)                */
;*    Copyright   :  2013-15 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    HopScript service implementation                                 */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __hopscript_service

   (library hop)

   (include "stringliteral.sch")
   
   (import __hopscript_types
	   __hopscript_rts
	   __hopscript_object
	   __hopscript_error
	   __hopscript_private
	   __hopscript_public
	   __hopscript_property
	   __hopscript_function
	   __hopscript_worker
	   __hopscript_json
	   __hopscript_lib
	   __hopscript_array)

   (static (class JsHopFrame::JsObject
	      (%this read-only)
	      (args read-only (default #f))
	      (url read-only)))

   (export (js-init-service! ::JsGlobalObject)
	   (js-make-hopframe ::JsGlobalObject ::obj ::obj)
	   (js-make-service::JsService ::JsGlobalObject ::procedure ::obj ::bool ::int ::obj ::hop-service)))

;*---------------------------------------------------------------------*/
;*    JsStringLiteral begin                                            */
;*---------------------------------------------------------------------*/
(%js-jsstringliteral-begin!)

;*---------------------------------------------------------------------*/
;*    object-serializer ::JsService ...                                */
;*---------------------------------------------------------------------*/
(register-class-serialization! JsService
   (lambda (o)
      (js-raise-type-error (js-initial-global-object)
	 "[[SerializeTypeError]] ~a" o))
   (lambda (o) o))

;*---------------------------------------------------------------------*/
;*    js-tostring ::JsHopFrame ...                                     */
;*---------------------------------------------------------------------*/
(define-method (js-tostring o::JsHopFrame %this)
   (with-access::JsHopFrame o (args url)
      url))

;*---------------------------------------------------------------------*/
;*    js-donate ::JsService ...                                        */
;*---------------------------------------------------------------------*/
(define-method (js-donate obj::JsService worker::WorkerHopThread %_this)
   (with-access::WorkerHopThread worker (%this)
      (let* ((proc (lambda (this . args)
		      (with-access::JsService obj (svc)
			 (with-access::hop-service svc (path)
			    (js-make-hopframe %this path args)))))
	     (nobj (duplicate::JsService obj
		      (procedure proc)
		      (properties '()))))
	 (js-for-in obj
	    (lambda (k)
	       (js-put! nobj k
		  (js-donate (js-get obj k %_this) worker %this)
		  #f %this))
	    %this)
	 nobj)))
   
;*---------------------------------------------------------------------*/
;*    xml-unpack ::JsService ...                                       */
;*---------------------------------------------------------------------*/
(define-method (xml-unpack o::JsService)
   #f)

;*---------------------------------------------------------------------*/
;*    xml-attribute-encode ::JsHopFrame ...                            */
;*---------------------------------------------------------------------*/
(define-method (xml-attribute-encode o::JsHopFrame)
   (with-access::JsHopFrame o (%this)
      (hopframe->string o %this)))

;*---------------------------------------------------------------------*/
;*    hop->javascript ::JsService ...                                  */
;*    -------------------------------------------------------------    */
;*    See runtime/js_comp.scm in the Hop library for the definition    */
;*    of the generic.                                                  */
;*---------------------------------------------------------------------*/
(define-method (hop->javascript o::JsService op compile isexpr)
   (with-access::JsService o (svc)
      (compile svc op)))

;*---------------------------------------------------------------------*/
;*    hop->javascript ::JsHopFrame ...                                 */
;*---------------------------------------------------------------------*/
(define-method (hop->javascript o::JsHopFrame op compile isexpr)
   (display "new HopFrame(\"" op)
   (display (hopframe->string o (js-initial-global-object)) op)
   (display "\")" op))

;*---------------------------------------------------------------------*/
;*    hop-register-value ::object ...                                  */
;*---------------------------------------------------------------------*/
(define-method (hop-register-value o::object register::procedure)
   #t)

;*---------------------------------------------------------------------*/
;*    js-init-service! ...                                             */
;*---------------------------------------------------------------------*/
(define (js-init-service! %this::JsGlobalObject)
   (with-access::JsGlobalObject %this (__proto__ js-function
					 js-service-prototype
					 js-hopframe-prototype)
      (with-access::JsFunction js-function ((js-function-prototype __proto__))
	 
	 ;; service prototype
	 (set! js-service-prototype
	    (instantiate::JsService
	       (__proto__ js-function-prototype)
	       (worker (class-nil WorkerHopThread))
	       (name "service")
	       (alloc (lambda (_) #unspecified))
	       (construct (lambda (constructor args)
			     (js-raise-type-error %this "not a constructor ~s"
				js-function-prototype)))
	       (len -1)
	       (procedure list)
	       (svc #f)
	       (extensible #t)))
	 
	 (js-bind! %this js-service-prototype 'resource
	    :value (js-make-function %this
		      (lambda (this file)
			 (js-string->jsstring
			    (service-resource this (js-jsstring->string file))))
		      1 'resource)
	    :writable #t
	    :configurable #t
	    :enumerable #f)
	 (js-bind! %this js-service-prototype 'unregister
	    :value (js-make-function %this
		      (lambda (this)
			 (when (isa? this JsService)
			    (with-access::JsService this (svc)
			       (unregister-service! svc)))
			 (js-undefined))
		      0 'unregister)
	    :writable #t
	    :configurable #t
	    :enumerable #f)
	 
	 (js-bind! %this js-service-prototype 'timeout
	    :get (js-make-function %this
		    (lambda (this)
		       (with-access::JsService this (svc)
			  (with-access::hop-service svc (timeout)
			     timeout)))
		    0 'timeout))

	 (js-bind! %this js-service-prototype 'ttl
	    :get (js-make-function %this
		    (lambda (this)
		       (with-access::JsService this (svc)
			  (with-access::hop-service svc (ttl)
			     ttl)))
		    0 'ttl)
	    :set (js-make-function %this
		    (lambda (this v)
		       (with-access::JsService this (svc)
			  (with-access::hop-service svc (ttl)
			     (set! ttl (js-tointeger v %this)))))
		    0 'ttl))
	 
	 ;; HopFrame prototype and constructor
	 (set! js-hopframe-prototype
	    (instantiate::JsObject
	       (__proto__ __proto__)
	       (extensible #t)))
	 
	 (js-bind! %this js-hopframe-prototype 'post
	    :value (js-make-function %this
		      (lambda (this::JsHopFrame success opt)
			 (with-access::JsHopFrame this (url args)
			    (post url args success opt %this #f)))
		      2 'post))
	 (js-bind! %this js-hopframe-prototype 'postSync
	    :value (js-make-function %this
		      (lambda (this::JsHopFrame opt)
			 (with-access::JsHopFrame this (url args)
			    (post url args #f opt %this #t)))
		      1 'postSync))
	 (js-bind! %this js-hopframe-prototype 'toString
	    :value (js-make-function %this
		      (lambda (this::JsHopFrame)
			 (js-string->jsstring (hopframe->string this %this)))
		      0 'toString))
	 (js-bind! %this js-hopframe-prototype 'inspect
	    :value (js-make-function %this
		      (lambda (this::JsHopFrame)
			 (js-string->jsstring (hopframe->string this %this)))
		      0 'inspect))

	 (letrec ((js-service (js-make-function %this
				 (lambda (this proc path args)
				    (js-new %this js-service proc path args))
				 3 'Service
				 :__proto__ js-function-prototype
				 :prototype js-service-prototype
				 :construct (lambda (this proc name args)
					       (js-create-service proc name args
						  (js-current-worker) %this))))
		  (js-hopframe (js-make-function %this
				  (lambda (this url args)
				     (js-new %this js-hopframe url args))
				  1 'HopFrame
				  :__proto__ js-function-prototype
				  :prototype js-hopframe-prototype
				  :construct (lambda (this url args)
						(js-make-hopframe %this
						   url args)))))
	    (js-bind! %this %this 'Service
	       :configurable #f :enumerable #f :value js-service)
	    (js-bind! %this %this 'HopFrame
	       :configurable #f :enumerable #f :value js-hopframe))

	 (js-undefined))))

;*---------------------------------------------------------------------*/
;*    js-make-hopframe ...                                             */
;*---------------------------------------------------------------------*/
(define (js-make-hopframe %this::JsGlobalObject url args)
   
   (define (url-frame)
      (with-access::JsGlobalObject %this (js-hopframe-prototype)
	 (instantiate::JsHopFrame
	    (%this %this)
	    (url (hop-apply-url url args))
	    (__proto__ js-hopframe-prototype))))
   
   (define (multipart-frame)
      (with-access::JsGlobalObject %this (js-hopframe-prototype)
	 (instantiate::JsHopFrame
	    (%this %this)
	    (args (unless (eq? args (js-undefined))
		     (map (lambda (val)
			     (cond
				((isa? val JsStringLiteral)
				 `("string" ,(js-jsstring->string val)
				     "hop-encoding: string"))
				((integer? val)
				 `("integer" ,val
				     "hop-encoding: integer"))
				((keyword? val)
				 `("keyword" ,(keyword->string val)
				     "hop-encoding: keyword"))
				((string? val)
				 (error "js-make-hopframe"
				    "Illegal string" val))
				(else
				 `("hop" ,(obj->string val 'hop-to-hop)
				     "hop-encoding: hop"))))
			args)))
	    (url url)
	    (__proto__ js-hopframe-prototype))))

   (cond
      ((null? args)
       (url-frame))
      ((and (null? (cdr args))
	    (string? (car args))
	    (<fx (string-length (car args)) 80))
       (url-frame))
      ((every integer? args)
       (url-frame))
      (else
       (multipart-frame))))

;*---------------------------------------------------------------------*/
;*    hopframe->string ...                                             */
;*---------------------------------------------------------------------*/
(define (hopframe->string::bstring frame::JsHopFrame %this)
   
   (define (hopframe-multipart-arg->arg arg)
      (cond
	 ((string=? (car arg) "hop")
	  (string->obj (cadr arg)))
	 ((string=? (car arg) "keyword")
	  (string->keyword (cadr arg)))
	 (else
	  (cadr arg))))

   (with-access::JsHopFrame frame (url args)
      (if (pair? args)
	  (hop-apply-url url (map hopframe-multipart-arg->arg args))
	  url)))

;*---------------------------------------------------------------------*/
;*    js-string->buffer ...                                            */
;*---------------------------------------------------------------------*/
(define (js-string->buffer str %this)
   str)

;*---------------------------------------------------------------------*/
;*    js-register-service-buffer-finalizer! ...                        */
;*---------------------------------------------------------------------*/
(define (js-register-service-buffer-finalizer! proc)
   (set! js-string->buffer proc))

;*---------------------------------------------------------------------*/
;*    post ...                                                         */
;*---------------------------------------------------------------------*/
(define (post svc::bstring args success opt %this force-sync)

   (let ((host "localhost")
	 (port (hop-port))
	 (user #f)
	 (password #f)
	 (authorization #f)
	 (fail #f)
	 (failjs #f)
	 (asynchronous (not force-sync))
	 (header #f)
	 (scheme 'http)
	 (worker (js-current-worker)))
      (cond
	 ((isa? opt JsFunction)
	  (set! fail
	     (lambda (xhr)
		(with-access::xml-http-request xhr (header)
		   (js-call1 %this opt %this
		      (js-alist->jsobject header %this))))))
	 ((not (eq? opt (js-undefined)))
	  (let ((h (js-get opt 'host %this))
		(p (js-get opt 'port %this))
		(u (js-get opt 'user %this))
		(w (js-get opt 'password %this))
		(a (js-get opt 'authorization %this))
		(f (js-get opt 'fail %this))
		(y (js-get opt 'asynchronous %this))
		(s (js-get opt 'scheme %this))
		(c (js-get opt 'ssl %this))
		(r (js-get opt 'header %this)))
	     (unless (eq? h (js-undefined))
		(set! host (js-tostring h %this)))
	     (unless (eq? p (js-undefined))
		(set! port (js-tointeger p %this)))
	     (unless (eq? u (js-undefined))
		(set! user (js-tostring u %this)))
	     (unless (eq? w (js-undefined))
		(set! password (js-tostring w %this)))
	     (unless (eq? a (js-undefined))
		(set! authorization (js-tostring a %this)))
	     (unless (js-totest y)
		(when (js-in? %this 'asynchronous opt)
		   (set! asynchronous #f)))
	     (when (js-totest c)
		(set! scheme 'https))
	     (unless (eq? s (js-undefined))
		(set! scheme (string->symbol (js-tostring s %this))))
	     (when (isa? f JsFunction)
		(set! failjs f)
		(set! fail
		   (lambda (xhr)
		      (with-access::xml-http-request xhr (header)
			 (if asynchronous
			     (js-worker-push-thunk! worker svc
				(lambda ()
				   (js-call1 %this f %this
				      (js-alist->jsobject header %this))))
			     (js-call1 %this f %this
				(js-alist->jsobject header %this)))))))
	     (when (isa? r JsObject)
		(set! header (js-jsobject->alist r %this))))))

      (define (with-hop callback)
	 (with-hop-remote svc callback fail
	    :scheme scheme
	    :host host :port port 
	    :user user :password password :authorization authorization
	    :header header
	    :ctx %this
	    :args args))

      (define (scheme->js val)
	 ;; a string might be received on internal server error
	 (if (string? val)
	     (js-string->jsstring val)
	     val))

      (if asynchronous
	  (begin
	     (thread-start!
		(instantiate::hopthread
		   (body (lambda ()
			    (with-handler
			       (lambda (e)
				  (if failjs
				      (js-worker-push-thunk! worker svc
					 (lambda ()
					    (js-call1 %this failjs %this e)))
				      (exception-notify e)))
			       (with-hop
				     (if (isa? success JsFunction)
					 (lambda (x)
					    (js-worker-push-thunk! worker svc
					       (lambda ()
						  (js-call1 %this success %this
						     (scheme->js x)))))
					 scheme->js)))))))
	     (js-undefined))
	  (with-hop
	     (if (isa? success JsFunction)
		 (lambda (x) (js-call1 %this success %this (scheme->js x)))
		 scheme->js)))))

;*---------------------------------------------------------------------*/
;*    js-create-service ...                                            */
;*    -------------------------------------------------------------    */
;*    This function is called when the HopScript constructor           */
;*    Service is directly invoked from user programs. The role         */
;*    of this function is to build an internal hop-service that        */
;*    simply calls the HopScript function passed as argument.          */
;*    The complexity of this function comes when the optional          */
;*    "args" arguments is an object, in which case, the function       */
;*    builds a service with optional named arguments.                  */
;*---------------------------------------------------------------------*/
(define (js-create-service proc::JsFunction name args worker %this::JsGlobalObject)
   
   (define js
      "(sc_lambda = function () { return new HopFrame( hop_apply_url( ~s, arguments ) ); },\n sc_lambda.resource = function( file ) { return ~s + \"/\" + file; },\n sc_lambda)")
   
   (define (source::bstring proc)
      (with-access::JsFunction proc (src)
	 (match-case (car src)
	    ((at ?path ?-) path)
	    (else (pwd)))))

   (define (fix-args len)
      (map (lambda (i)
	      (string->symbol (format "a~a" i)))
	 (iota len)))

   (define (dsssl-args args)
      (let ((acc '()))
	 (js-for-in args
	    (lambda (s) (set! acc (cons (string->symbol s) acc))) %this)
	 (cons '#!key (reverse! acc))))
   
   (define (create-fix-service proc name)
      (letrec* ((id (if (string? name) (string->symbol name) (gensym 'svc)))
		(src (source proc))
		(svcp (lambda (this . args)
			 (with-access::JsService svcjs (svc)
			    (with-access::hop-service svc (path)
			       (js-make-hopframe %this path args)))))
		(svcjs (js-make-service %this svcp id #t -1 worker
			  (instantiate::hop-service
			     (ctx %this)
			     (proc (lambda (this . args)
				      (map! (lambda (a)
					       (js-obj->jsobject a %this))
					 args)
				      (js-worker-exec worker
					 (symbol->string! id)
					 (lambda ()
					    (js-apply %this proc this args)))))
			     (javascript js)
			     (path (if (string? name)
				       (make-file-name (hop-service-base) name)
				       (make-hop-url-name
					  (gen-service-url :public #t))))
			     (id id)
			     (wid id)
			     (args (fix-args (js-get proc 'length %this)))
			     (resource (dirname src))
			     (source src)))))
	 svcjs))

   (define (dsssl-actuals defaults objs)
      (if (and (null? (cdr objs)) (isa? (car objs) JsObject))
	  (let ((obj (car objs)))
	     (map (lambda (arg)
		     (let ((k (keyword->symbol (car arg))))
			(if (js-has-property obj k %this)
			    (js-get obj k %this)
			    (cdr arg))))
		defaults))
	  (map (lambda (arg)
		  (let ((c (memq (car arg) objs)))
		     (if (pair? c)
			 (js-obj->jsobject (cadr c) %this)
			 (cdr arg))))
	     defaults)))
   
   (define (create-dsssl-service proc name args)
      (letrec* ((id (if (string? name) (string->symbol name) (gensym 'svc)))
		(src (source proc))
		(svcp (lambda (this . args)
			 (with-access::JsService svcjs (svc)
			    (with-access::hop-service svc (path)
			       (js-make-hopframe %this path args)))))
		(defaults (js-jsobject->alist args %this))
		(svcjs (js-make-service %this svcp id #t -1 worker
			  (instantiate::hop-service
			     (ctx %this)
			     (proc (lambda (this . objs)
				      (js-worker-exec worker
					 (symbol->string! id)
					 (lambda ()
					    (js-apply %this proc this
					       (dsssl-actuals defaults
						  objs))))))
			     (javascript js)
			     (path (if (string? name)
				       (make-file-name (hop-service-base) name)
				       (make-hop-url-name
					  (gen-service-url :public #t))))
			     (id id)
			     (wid id)
			     (args (dsssl-args args))
			     (resource (dirname src))
			     (source src)))))
	 svcjs))

   ;; argument parsing
   (cond
      ((isa? name JsStringLiteral)
       (let ((name (js-jsstring->string name)))
	  (if (eq? args (js-undefined))
	      (create-fix-service proc name)
	      (create-dsssl-service proc name args))))
      ((isa? name JsString)
       (let ((name (js-tostring name %this)))
	  (if (eq? args (js-undefined))
	      (create-fix-service proc name)
	      (create-dsssl-service proc name args))))
      ((isa? name JsObject)
       (create-dsssl-service proc #f name))
      (else
       (create-fix-service proc #f))))

;*---------------------------------------------------------------------*/
;*    js-make-service ...                                              */
;*---------------------------------------------------------------------*/
(define (js-make-service %this proc name register arity worker svc)
   (with-access::JsGlobalObject %this (js-service-prototype)
      (when register (register-service! svc))
      (with-access::WorkerHopThread worker (services)
	 (set! services (cons svc services)))
      (instantiate::JsService
	 (procedure proc)
	 (len arity)
	 (arity arity)
	 (worker worker)
	 (__proto__ js-service-prototype)
	 (name (if (symbol? name) (symbol->string! name) ""))
	 (alloc (lambda (_)
		   (js-raise-type-error %this
		      "service not a constructor" #f)))
	 (construct (lambda (_ arg)
		       (js-raise-type-error %this
			  "service not a constructor" arg)))
	 (properties (list
			(instantiate::JsValueDescriptor
			   (name 'length)
			   (value 0))
			(instantiate::JsAccessorDescriptor
			   (name 'path)
			   (get (js-make-function %this
				   (lambda (o)
				      (with-access::JsService o (svc)
					 (with-access::hop-service svc (path)
					    (js-string->jsstring path))))
				   1 'path))
			   (set (js-make-function %this
				   (lambda (o v)
				      (with-access::JsService o (svc)
					 (when register
					    (unregister-service! svc))
					 (with-access::hop-service svc (path)
					    (set! path (js-tostring v %this))
					    (when register
					       (register-service! svc)))))
				   2 'path)))))
	 (svc svc))))

;*---------------------------------------------------------------------*/
;*    service? ::JsService ...                                         */
;*---------------------------------------------------------------------*/
(define-method (service? obj::JsService)
   #t)

;*---------------------------------------------------------------------*/
;*    service->hop-service ::JsService ...                             */
;*---------------------------------------------------------------------*/
(define-method (service->hop-service obj::JsService)
   (with-access::JsService obj (svc)
      svc))
   
;*---------------------------------------------------------------------*/
;*    JsStringLiteral end                                              */
;*---------------------------------------------------------------------*/
(%js-jsstringliteral-end!)

