;*=====================================================================*/
;*    serrano/prgm/project/hop/1.9.x/src/scheduler.scm                 */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Fri Feb 22 11:19:21 2008                          */
;*    Last change :  Sat Mar 29 08:09:00 2008 (serrano)                */
;*    Copyright   :  2008 Manuel Serrano                               */
;*    -------------------------------------------------------------    */
;*    Specification of the various Hop schedulers                      */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module hop_scheduler

   (library hop)

   (cond-expand
      (enable-threads
       (library pthread)))
   
   (cond-expand
      (enable-threads
       (export (class hopthread::pthread
		  (proc::procedure (default (lambda (t) #f)))
		  (condv::condvar read-only (default (make-condition-variable)))
		  (mutex::mutex read-only (default (make-mutex)))
		  (scheduler::scheduler (default (scheduler-nil)))
		  (info::obj (default #unspecified))
		  (request::obj (default #f)))))
      (else
       (export (class hopthread::thread
		  (proc::procedure (default (lambda (t) #f)))
		  (condv::condvar read-only (default (make-condition-variable)))
		  (mutex::mutex read-only (default (make-mutex)))
		  (scheduler::scheduler (default (scheduler-nil)))
		  (info::obj (default #unspecified))
		  (request::obj (default #f))))))

   (export (abstract-class scheduler
	      (scheduler-init!)
	      (size::int read-only (default 0)))

	   (generic scheduler-init! ::scheduler)
	   (generic scheduler-stat ::scheduler)
	   (generic scheduler-load::int ::scheduler)
	   
	   (generic schedule-start ::scheduler ::procedure ::obj)
	   (generic schedule ::scheduler ::procedure ::obj)

	   (generic thread-info ::obj)
	   (generic thread-info-set! ::obj ::obj)

	   (scheduler-default-handler ::obj)))

;*---------------------------------------------------------------------*/
;*    scheduler-init! ::scheduler ...                                  */
;*---------------------------------------------------------------------*/
(define-generic (scheduler-init! scd::scheduler) scd)

;*---------------------------------------------------------------------*/
;*    scheduler-stat ::scheduler ...                                   */
;*---------------------------------------------------------------------*/
(define-generic (scheduler-stat scd::scheduler))

;*---------------------------------------------------------------------*/
;*    scheduler-load ::scheduler ...                                   */
;*---------------------------------------------------------------------*/
(define-generic (scheduler-load scd::scheduler) 100)

;*---------------------------------------------------------------------*/
;*    schedule-start ...                                               */
;*---------------------------------------------------------------------*/
(define-generic (schedule-start scd::scheduler proc::procedure msg)
   (schedule scd proc msg))

;*---------------------------------------------------------------------*/
;*    schedule ...                                                     */
;*---------------------------------------------------------------------*/
(define-generic (schedule scd::scheduler proc::procedure msg))

;*---------------------------------------------------------------------*/
;*    *thread-info* ...                                                */
;*---------------------------------------------------------------------*/
(define *thread-info* #f)

;*---------------------------------------------------------------------*/
;*    thread-info ...                                                  */
;*---------------------------------------------------------------------*/
(define-generic (thread-info thread)
   *thread-info*)

;*---------------------------------------------------------------------*/
;*    thread-info-set! ...                                             */
;*---------------------------------------------------------------------*/
(define-generic (thread-info-set! thread info)
   (set! *thread-info* info))
	  
;*---------------------------------------------------------------------*/
;*    thread-info ::hopthread ...                                      */
;*---------------------------------------------------------------------*/
(define-method (thread-info th::hopthread)
   (hopthread-info th))

;*---------------------------------------------------------------------*/
;*    thread-info ::hopthread ...                                      */
;*---------------------------------------------------------------------*/
(define-method (thread-info-set! th::hopthread info)
   (hopthread-info-set! th info))

;*---------------------------------------------------------------------*/
;*    thread-request ::hopthread ...                                   */
;*---------------------------------------------------------------------*/
(define-method (thread-request th::hopthread)
   (hopthread-request th))

;*---------------------------------------------------------------------*/
;*    thread-request ::hopthread ...                                   */
;*---------------------------------------------------------------------*/
(define-method (thread-request-set! th::hopthread req)
   (hopthread-request-set! th req))

;*---------------------------------------------------------------------*/
;*    scheduler-default-handler ...                                    */
;*---------------------------------------------------------------------*/
(define (scheduler-default-handler e)
   (if (&exception? e)
       (exception-notify e)
       (fprint (current-error-port) "*** INTERNAL ERROR"
	       "uncaught exception: "
	       (find-runtime-type e)))
   (let ((th (current-thread)))
      (when (thread? th)
	 (fprint (current-error-port) "Thread: " th " " (thread-info th)))))

	  