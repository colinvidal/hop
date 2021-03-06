;*=====================================================================*/
;*    serrano/prgm/project/hop/2.4.x/src/oto_scheduler.scm             */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Tue Feb 26 06:41:38 2008                          */
;*    Last change :  Fri Mar 29 10:51:24 2013 (serrano)                */
;*    Copyright   :  2008-13 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    One to one scheduler                                             */
;*    -------------------------------------------------------------    */
;*    The characteristics of this scheduler are:                       */
;*      - each accept is handled by a new single thread.               */
;*      - on heavy load the new request waits for an old request to    */
;*        complete.                                                    */
;*    This is the simplest and most naive multi-threaded scheduler.    */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module hop_scheduler-one-to-one

   (library hop)
   
   (import  hop_scheduler
	    hop_param)

   (export  (class one-to-one-scheduler::row-scheduler
	       (mutex::mutex read-only (default (make-mutex)))
	       (condv::condvar read-only (default (make-condition-variable)))
	       (cur::int (default 0)))))

;*---------------------------------------------------------------------*/
;*    dummy-mutex ...                                                  */
;*---------------------------------------------------------------------*/
(define dummy-mutex (make-mutex))
(define dummy-condv (make-condition-variable))

;*---------------------------------------------------------------------*/
;*    scheduler-stat ::one-to-one-scheduler ...                        */
;*---------------------------------------------------------------------*/
(define-method (scheduler-stat scd::one-to-one-scheduler)
   (with-access::one-to-one-scheduler scd (size cur)
      (format " (~a/~a)" cur size)))

;*---------------------------------------------------------------------*/
;*    scheduler-load ::one-to-one-scheduler ...                        */
;*---------------------------------------------------------------------*/
(define-method (scheduler-load scd::one-to-one-scheduler)
   (with-access::one-to-one-scheduler scd (cur size)
      (flonum->fixnum
       (*fl 100. (/fl (fixnum->flonum cur) (fixnum->flonum size))))))

;*---------------------------------------------------------------------*/
;*    spawn ::one-to-one-scheduler ...                                 */
;*---------------------------------------------------------------------*/
(define-method (spawn scd::one-to-one-scheduler proc . args)
   (with-access::one-to-one-scheduler scd (mutex condv cur size)
      (let ((thread #f))
	 (synchronize mutex
	    (let loop ()
	       (when (>=fx cur size)
		  ;; we have to wait for a thread to complete
		  (condition-variable-wait! condv mutex)
		  (loop)))
	    (set! thread (instantiate::scdthread
			    (condv dummy-condv)
			    (mutex dummy-mutex)
			    (scheduler scd)
			    (body (lambda ()
				     (with-handler
					(make-scheduler-error-handler thread)
					(apply proc scd thread args))
				     (mutex-lock! mutex)
				     (set! cur (-fx cur 1))
				     (condition-variable-signal! condv)
				     (mutex-unlock! mutex)))))
	    (set! cur (+fx cur 1)))
	 (thread-start! thread))))

;*---------------------------------------------------------------------*/
;*    spawn4 ::one-to-one-scheduler ...                                */
;*---------------------------------------------------------------------*/
(define-method (spawn4 scd::one-to-one-scheduler proc a0 a1 a2 a3)
   (with-access::one-to-one-scheduler scd (mutex condv cur size)
      (let ((thread #f))
	 (synchronize mutex
	    (let loop ()
	       (when (>=fx cur size)
		  ;; we have to wait for a thread to complete
		  (condition-variable-wait! condv mutex)
		  (loop)))
	    (set! thread (instantiate::scdthread
			    (condv dummy-condv)
			    (mutex dummy-mutex)
			    (scheduler scd)
			    (body (lambda ()
				     (with-handler
					(make-scheduler-error-handler thread)
					(proc scd thread a0 a1 a2 a3))
				     (mutex-lock! mutex)
				     (set! cur (-fx cur 1))
				     (condition-variable-signal! condv)
				     (mutex-unlock! mutex)))))
	    (set! cur (+fx cur 1)))
	 (thread-start! thread))))



