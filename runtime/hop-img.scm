;*=====================================================================*/
;*    serrano/prgm/project/hop/1.9.x/runtime/hop-img.scm               */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Tue Dec 18 08:04:49 2007                          */
;*    Last change :  Tue Feb 26 05:50:53 2008 (serrano)                */
;*    Copyright   :  2007-08 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    Dealing with IMG markups.                                        */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __hop_img

   (library web)

   (include "param.sch"
	    "xml.sch")

   (import  __hop_types
	    __hop_mime
	    __hop_misc
	    __hop_param
	    __hop_configure
	    __hop_xml
	    __hop_hop
	    __hop_user
	    __hop_cache
	    __hop_charset)

   (export  (<IMG> . ::obj)
	    (img-base64-encode::bstring ::bstring)))

;*---------------------------------------------------------------------*/
;*    img-disk-cache ...                                               */
;*---------------------------------------------------------------------*/
(define img-disk-cache #f)
(define img-memory-cache #f)

;*---------------------------------------------------------------------*/
;*    init-img-caches! ...                                             */
;*---------------------------------------------------------------------*/
(define (init-img-caches!)
   (unless img-disk-cache
      (set! img-disk-cache
	    (instantiate::cache-disk
	       (path (make-file-path
		      (hop-rc-directory)
		      "cache"
		      (string-append "img-" (integer->string (hop-port)))))
	       (out display)))
      (set! img-memory-cache
	    (instantiate::cache-memory
	       (max-file-size #e4096)))))

;*---------------------------------------------------------------------*/
;*    inline-base64 ...                                                */
;*---------------------------------------------------------------------*/
(define (inline-base64 src)
   (let ((p (open-input-file src)))
      (when (input-port? p)
	 (unwind-protect
	    (format "data:~a;base64,~a"
		    (mime-type src (format "image/~a" (suffix src)))
		    (base64-encode (read-string p) -1))
	    (close-input-port p)))))
		       
;*---------------------------------------------------------------------*/
;*    img-base64-encode ...                                            */
;*---------------------------------------------------------------------*/
(define (img-base64-encode src)
   (or (inline-base64 src) src))

;*---------------------------------------------------------------------*/
;*    cache-memory-inline-image ...                                    */
;*---------------------------------------------------------------------*/
(define (cache-memory-inline-image path)
   (and (file-exists? path)
	(<elong (file-size path) #e4096)
	(let ((cache (cache-get img-memory-cache path)))
	   (if (string? cache)
	       cache
	       (let ((img (inline-base64 path)))
		  (cache-put! img-memory-cache path img)
		  img)))))

;*---------------------------------------------------------------------*/
;*    cache-disk-inline-image ...                                      */
;*---------------------------------------------------------------------*/
(define (cache-disk-inline-image path)
   (let ((cache (cache-get img-disk-cache path)))
      (if (string? cache)
	  (with-input-from-file cache read-string)
	  (let ((img (inline-base64 path)))
	     (cache-put! img-disk-cache path img)
	     img))))

;*---------------------------------------------------------------------*/
;*    inline-image ...                                                 */
;*---------------------------------------------------------------------*/
(define (inline-image path)
   (init-img-caches!)
   (or (cache-memory-inline-image path) (cache-disk-inline-image path)))

;*---------------------------------------------------------------------*/
;*    IMG ...                                                          */
;*---------------------------------------------------------------------*/
(define-xml-compound <IMG> ((id #unspecified string)
			    (inline #f boolean)
			    (alt #f)
			    (src #unspecified)
			    (attributes)
			    body)
   
   (define (plain-img src cssrc)
      (instantiate::xml-empty-element
	 (markup 'img)
	 (id (xml-make-id id 'img))
	 (attributes (cons* `(src . ,cssrc)
			    `(alt . ,(or alt (basename src)))
			    attributes))
	 (body '())))
   
   (define (onerror-img attributes src)
      (let* ((val (format "if( !this.onhoperror ) { this.onhoperror = true; hop_deinline_image(this, ~s) }" src))
	     (onerror (when (pair? attributes) (assq 'onerror attributes)))
	     (oval (when (pair? onerror) (cdr onerror))))
	 (cond
	    ((string? oval)
	     (set-cdr! onerror (string-append oval "; " val))
	     attributes)
	    ((xml-tilde? oval)
	     (let ((tilde (string->tilde val)))
		(set-cdr! onerror (tilde-compose oval tilde)))
	     attributes)
	    (else
	     (cons `(onerror . ,val) attributes)))))
   
   (define (inline-img src cssrc)
      (let ((isrc (inline-image src)))
	 (if isrc
	     (instantiate::xml-empty-element
		(markup 'img)
		(id (xml-make-id id 'img))
		(attributes (cons* `(src . ,isrc)
				   `(alt . ,(or alt (basename src)))
				   (onerror-img attributes src)))
		(body '()))
	     (plain-img src cssrc))))
   
   (cond
      ((xml-tilde? src)
       (instantiate::xml-empty-element
	  (markup 'img)
	  (id (xml-make-id id 'img))
	  (attributes (cons* `(alt . ,alt) attributes))
	  (initializations (list (cons 'src src)))
	  (body '())))
      ((string? src)
       (let ((cssrc (charset-convert src (hop-locale) (hop-charset))))
	  (if (not inline)
	      (plain-img src cssrc)
	      (let ((req (current-request)))
		 (if (or (not req) (authorized-path? (current-request) src))
		     (inline-img src cssrc)
		     (plain-img src cssrc))))))
      (else
       (error '<IMG> "Illegal image src" src))))