;*=====================================================================*/
;*    serrano/prgm/project/hop/3.0.x/runtime/zeroconf.scm              */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Thu Dec 15 09:00:54 2011                          */
;*    Last change :  Sat Sep 19 20:23:20 2015 (serrano)                */
;*    Copyright   :  2011-15 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    Hop Zeroconf support                                             */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __hop_zeroconf

   (include "zeroconf_dummy.sch")
   
   (cond-expand
      ((and enable-avahi (library avahi))
       (include "zeroconf_avahi.sch")))

   (include "service.sch")
   
   (import __hop_configure
	   __hop_service
	   __hop_types
	   __hop_hop
	   __hop_param
	   __hop_misc
	   __hop_read
	   __hop_event
	   __hop_user)
   
   (export (abstract-class zeroconf
	      (zeroconf-init!)
	      (hostname::bstring (default ""))
	      (onready::procedure (default list)))

	   (class zeroconf-service-event::server-event
	      (interface::int read-only)
	      (protocol::bstring read-only)
	      (type::bstring read-only)
	      (domain::bstring read-only)
	      (hostname::bstring read-only)
	      (port::int read-only (default 0))
	      (address::bstring read-only (default ""))
	      (options::pair-nil read-only (default '())))

	   (generic zeroconf-init! ::zeroconf)
	   (zeroconf-register-backend! ::zeroconf)
	   
	   (generic zeroconf-backend-start ::zeroconf)
	   (generic zeroconf-backend-stop ::zeroconf)
	   
	   (generic zeroconf-backend-publish-service! ::zeroconf
	      ::bstring ::int ::bstring ::pair-nil)
	   (generic zeroconf-backend-add-service-event-listener! ::zeroconf
	      ::obj ::procedure)

	   ;; public api
	   (zeroconf-backend)
	   (zeroconf-started?)
	   (zeroconf-start)
	   (zeroconf-publish! #!key name port type #!rest opts)))

;*---------------------------------------------------------------------*/
;*    *zeroconf-backend* ...                                           */
;*---------------------------------------------------------------------*/
(define *zeroconf-backend* (instantiate::zeroconf-dummy))

;*---------------------------------------------------------------------*/
;*    zeroconf-register-backend! ...                                   */
;*---------------------------------------------------------------------*/
(define (zeroconf-register-backend! o::zeroconf)
   (when (or (not (isa? *zeroconf-backend* zeroconf))
	     (isa? *zeroconf-backend* zeroconf-dummy))
      (set! *zeroconf-backend* o)))

;*---------------------------------------------------------------------*/
;*    zeroconf-backend ...                                             */
;*---------------------------------------------------------------------*/
(define (zeroconf-backend)
   *zeroconf-backend*)

;*---------------------------------------------------------------------*/
;*    zeroconf-init! ::zeroconf ...                                    */
;*---------------------------------------------------------------------*/
(define-generic (zeroconf-init! o::zeroconf)
   o)

;*---------------------------------------------------------------------*/
;*    *zeroconf-started* ...                                           */
;*---------------------------------------------------------------------*/
(define *zeroconf-started* #f)
(define *zeroconf-mutex* (make-mutex))

;*---------------------------------------------------------------------*/
;*    zeroconf-started? ...                                            */
;*---------------------------------------------------------------------*/
(define (zeroconf-started?)
   *zeroconf-started*)

;*---------------------------------------------------------------------*/
;*    zeroconf-start ...                                               */
;*---------------------------------------------------------------------*/
(define (zeroconf-start)
   (synchronize *zeroconf-mutex*
      (unless *zeroconf-started*
	 (set! *zeroconf-started* #t)
	 (zeroconf-backend-start (zeroconf-backend))
	 (register-exit-function!
	    (lambda (ret)
	       (synchronize *zeroconf-mutex*
		  (when *zeroconf-started*
		     (set! *zeroconf-started* #f)
		     (zeroconf-backend-stop (zeroconf-backend)))))))))

;*---------------------------------------------------------------------*/
;*    zeroconf-backend-start ...                                       */
;*---------------------------------------------------------------------*/
(define-generic (zeroconf-backend-start o::zeroconf)
   (with-access::zeroconf o (hostname)
      (when (string=? hostname "")
	 (let* ((h (hop-server-hostname))
		(i (and (not (pregexp-match "(?:[0-9]{1,3}[.]){3}[0-9]{1,3}" h))
			(string-index h #\.))))
	    (set! hostname (if i (substring h 0 i) h)))))
   #f)

;*---------------------------------------------------------------------*/
;*    zeroconf-backend-stop ::zeroconf ...                             */
;*---------------------------------------------------------------------*/
(define-generic (zeroconf-backend-stop o::zeroconf)
   #f)
   
;*---------------------------------------------------------------------*/
;*    zeroconf-backend-add-service-event-listener! ::zeroconf ...      */
;*---------------------------------------------------------------------*/
(define-generic (zeroconf-backend-add-service-event-listener! o::zeroconf evt proc)
   #f)

;*---------------------------------------------------------------------*/
;*    add-event-listener! ...                                          */
;*---------------------------------------------------------------------*/
(define-method (add-event-listener! o::zeroconf evt proc . capture)
   (zeroconf-backend-add-service-event-listener! o evt proc))

;*---------------------------------------------------------------------*/
;*    zeroconf-backend-publish-service! ::zeroconf ...                 */
;*---------------------------------------------------------------------*/
(define-generic (zeroconf-backend-publish-service! o::zeroconf name port type opts)
   #f)

;*---------------------------------------------------------------------*/
;*    zeroconf-publish! ...                                            */
;*---------------------------------------------------------------------*/
(define (zeroconf-publish! #!key name port type #!rest opts)
   (with-access::zeroconf (zeroconf-backend) (hostname)
      (zeroconf-backend-publish-service! (zeroconf-backend)
	 (string-append name "@" hostname)
	 port type opts)))

