;*=====================================================================*/
;*    serrano/prgm/project/hop/share/hop-canvas.scm                    */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Sat Nov  3 08:24:25 2007                          */
;*    Last change :  Tue Nov  6 09:26:19 2007 (serrano)                */
;*    Copyright   :  2007 Manuel Serrano                               */
;*    -------------------------------------------------------------    */
;*    HOP Canvas interface                                             */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    canvas-get-context ...                                           */
;*---------------------------------------------------------------------*/
(define (canvas-get-context canvas context)
   (canvas.getContext context))

;*---------------------------------------------------------------------*/
;*    canvas-properties ...                                            */
;*---------------------------------------------------------------------*/
(define (canvas-properties ctx)
   `(:fill-style ,ctx.fillStyle
		 :global-alpha ,ctx.globalAlpha
		 :global-composite-operation ,ctx.globalCompositeOperation
		 :line-cap ,ctx.lineCap
		 :line-join ,ctx.lineJoin
		 :line-width ,ctx.lineWidth
		 :miter-limit ,ctx.miterLimit
		 :shadow-blur ,ctx.shadowBlue
		 :shadow-color ,ctx.shadowColor
		 :shadow-offset-x ,ctx.shadowOffsetX
		 :shadow-offset-y ,ctx.shadowOffsetY
		 :stroke-style  ,ctx.strokeStyle))
		 
;*---------------------------------------------------------------------*/
;*    canvas-properties-set! ...                                       */
;*---------------------------------------------------------------------*/
(define (canvas-properties-set! ctx . props)
   (let loop ((props props))
      (when (pair? props)
	 (cond
	    ((null? (cdr props))
	     (error 'canvas-property-set! "Illegal property attribute" props))
	    ((not (keyword? (car props)))
	     (error 'canvas-property-set! "Illegal property keyword" props))
	    (else
	     (case (car props)
		((:fill-style)
		 (set! ctx.fillStyle (cadr props)))
		((:global-alpha)
		 (set! ctx.globalAlpha (cadr props)))
		((:global-composition-operation)
		 (set! ctx.globalCompositionOperation (cadr props)))
		((:line-cap)
		 (set! ctx.lineCap (cadr props)))
		((:line-join)
		 (set! ctx.lineJoin (cadr props)))
		((:line-width)
		 (set! ctx.lineWidth (cadr props)))
		((:miter-limit)
		 (set! ctx.miterLimit (cadr props)))
		((:shadow-blur)
		 (set! ctx.shadowBlue (cadr props)))
		((:shadow-color)
		 (set! ctx.shadowColor (cadr props)))
		((:shadow-offset-x)
		 (set! ctx.shadowOffsetX (cadr props)))
		((:shadow-offset-y)
		 (set! ctx.shadowOffsetY (cadr props)))
		((:stroke-style)
		 (set! ctx.strokeStyle (cadr props))))))
	 (loop (cddr props)))))

;*---------------------------------------------------------------------*/
;*    canvas-restore ...                                               */
;*---------------------------------------------------------------------*/
(define (canvas-restore ctx)
   (ctx.restore))

;*---------------------------------------------------------------------*/
;*    canvas-save ...                                                  */
;*---------------------------------------------------------------------*/
(define (canvas-save ctx)
   (ctx.save))

;*---------------------------------------------------------------------*/
;*    canvas-rotate ...                                                */
;*---------------------------------------------------------------------*/
(define (canvas-rotate ctx angle)
   (ctx.rotate angle))

;*---------------------------------------------------------------------*/
;*    canvas-scale ...                                                 */
;*---------------------------------------------------------------------*/
(define (canvas-scale ctx sx sy)
   (ctx.scale sx sy))

;*---------------------------------------------------------------------*/
;*    canvas-translate ...                                             */
;*---------------------------------------------------------------------*/
(define (canvas-translate ctx tx ty)
   (ctx.translate tx ty))

;*---------------------------------------------------------------------*/
;*    canvas-arc ...                                                   */
;*---------------------------------------------------------------------*/
(define (canvas-arc ctx x y radius sa ea clockwise)
   (ctx.arc x y radius sa ea clockwise))

;*---------------------------------------------------------------------*/
;*    canvas-arc-to ...                                                */
;*---------------------------------------------------------------------*/
(define (canvas-arc-to ctx x0 y0 x1 y1 radius)
   (ctx.arc-to x0 y0 x1 y1 radius))

;*---------------------------------------------------------------------*/
;*    canvas-begin-path ...                                            */
;*---------------------------------------------------------------------*/
(define (canvas-begin-path ctx)
   (ctx.beginPath))

;*---------------------------------------------------------------------*/
;*    canvas-close-path ...                                            */
;*---------------------------------------------------------------------*/
(define (canvas-close-path ctx)
   (ctx.closePath))

;*---------------------------------------------------------------------*/
;*    canvas-stroke ...                                                */
;*---------------------------------------------------------------------*/
(define (canvas-stroke ctx)
   (ctx.stroke))

;*---------------------------------------------------------------------*/
;*    canvas-fill ...                                                  */
;*---------------------------------------------------------------------*/
(define (canvas-fill ctx)
   (ctx.fill))

;*---------------------------------------------------------------------*/
;*    canvas-clip ...                                                  */
;*---------------------------------------------------------------------*/
(define (canvas-clip ctx)
   (ctx.clip))

;*---------------------------------------------------------------------*/
;*    canvas-line ...                                                  */
;*---------------------------------------------------------------------*/
(define (canvas-line ctx x0 y0 . rest)
   (ctx.moveTo x0 y0)
   (let loop ((rest rest))
      (when (pair? rest)
	 (if (null? (cdr rest))
	     (error 'canvas-line "Illegal number of arguments" rest)
	     (begin
		(ctx.moveTo (car rest) (cadr rest))
		(loop (cddr rest)))))))
   
;*---------------------------------------------------------------------*/
;*    canvas-line-to ...                                               */
;*---------------------------------------------------------------------*/
(define (canvas-line-to ctx x y)
   (ctx.lineTo x y))

;*---------------------------------------------------------------------*/
;*    canvas-move-to ...                                               */
;*---------------------------------------------------------------------*/
(define (canvas-move-to ctx x y)
   (ctx.moveTo x y))

;*---------------------------------------------------------------------*/
;*    canvas-fill ...                                                  */
;*---------------------------------------------------------------------*/
(define (canvas-fill ctx)
   (ctx.fill))
		       
;*---------------------------------------------------------------------*/
;*    canvas-move-to ...                                               */
;*---------------------------------------------------------------------*/
(define (canvas-move-to ctx x y)
   (ctx.moveTo x y))

;*---------------------------------------------------------------------*/
;*    canvas-bezier-curve-to ...                                       */
;*---------------------------------------------------------------------*/
(define (canvas-bezier-curve-to ctx x0 y0 x1 y1 x y)
   (ctx.bezierCurveTo x0 y0 x1 y1 x y))

;*---------------------------------------------------------------------*/
;*    canvas-bezier-curve ...                                          */
;*---------------------------------------------------------------------*/
(define (canvas-bezier-curve ctx x0 y0 . rest)
   (ctx.moveTo x0 y0)
   (let loop ((r rest))
      (when (pair? r)
	 (let* ((cp1x (car r))
		(cp1y (cadr r))
		(r (cddr r))
		(cp2x (car r))
		(cp2y (cadr r))
		(r (cddr r)))
	    (ctx.bezierCurveTo cp1x cp1y cp2x cp2y (car r) (cadr r))
	    (loop (cddr r))))))

;*---------------------------------------------------------------------*/
;*    canvas-quadratic-curve-to ...                                    */
;*---------------------------------------------------------------------*/
(define (canvas-quadratic-curve-to ctx x0 y0 x1 y1)
   (ctx.quadraticCurveTo x0 y0 x1 y1))

;*---------------------------------------------------------------------*/
;*    canvas-quadratic-curve ...                                       */
;*---------------------------------------------------------------------*/
(define (canvas-quadratic-curve ctx x0 y0 . rest)
   (ctx.moveTo x0 y0)
   (let loop ((r rest))
      (when (pair? r)
	 (ctx.quadraticCurveTo (car r) (cadr r) (caddr r) (cadddr r))
	 (loop (cddddr r)))))

;*---------------------------------------------------------------------*/
;*    canvas-clear-rect ...                                            */
;*---------------------------------------------------------------------*/
(define (canvas-clear-rect ctx x0 y0 x1 y1)
   (ctx.clearRect x0 y0 x1 y1))

;*---------------------------------------------------------------------*/
;*    canvas-fill-rect ...                                             */
;*---------------------------------------------------------------------*/
(define (canvas-fill-rect ctx x0 y0 x1 y1)
   (ctx.fillRect x0 y0 x1 y1))

;*---------------------------------------------------------------------*/
;*    canvas-stroke-rect ...                                           */
;*---------------------------------------------------------------------*/
(define (canvas-stroke-rect ctx x0 y0 x1 y1)
   (ctx.strokeRect x0 y0 x1 y1))

;*---------------------------------------------------------------------*/
;*    canvas-create-linear-gradient ...                                */
;*---------------------------------------------------------------------*/
(define (canvas-create-linear-gradient ctx x1 y1 x2 y2)
   (ctx.createLinearGradient x1 y1 x2 y2))

;*---------------------------------------------------------------------*/
;*    canvas-create-radial-gradient ...                                */
;*---------------------------------------------------------------------*/
(define (canvas-create-radial-gradient ctx x1 y1 r1 x2 y2 r2)
   (ctx.createRadialGradient x1 y1 r1 x2 y2 r2))

;*---------------------------------------------------------------------*/
;*    canvas-add-color-stop ...                                        */
;*---------------------------------------------------------------------*/
(define (canvas-add-color-stop gradient position color)
   (gradient.addColorStop position color))

;*---------------------------------------------------------------------*/
;*    canvas-create-pattern ...                                        */
;*---------------------------------------------------------------------*/
(define (canvas-create-pattern ctx img type)
   (ctx.createPattern img type))

;*---------------------------------------------------------------------*/
;*    canvas-draw-image ...                                            */
;*---------------------------------------------------------------------*/
(define (canvas-draw-image ctx image x y . rest)
   (if (null? rest)
       (ctx.drawImage image x y)
       (if (and (pair? rest) (pair? (cdr rest)))
	   (if (null? (cdr rest))
	       (ctx.drawImage image x y (car rest) (cadr rest))
	       (let* ((sw (car rest))
		      (sh (cadr rest))
		      (rest (cddr rest)))
		  (ctx.drawImage image x y sw sh
				 (car rest) (cadr rest)
				 (caddr rest) (cadddr rest))))
	   (error 'canvas-draw-image "Illegal number of arguments"  rest))))

;*---------------------------------------------------------------------*/
;*    canvas-arrow-to ...                                              */
;*---------------------------------------------------------------------*/
(define (canvas-arrow-to ctx x0 y0 x1 y1 . args)
   (let* ((len (* 5 ctx.lineWidth))
	  (an 0.4)
	  (head #t)
	  (tail #f))
      ;; arguments parsing
      (let loop ((args args))
	 (when (pair? args)
	    (if (null? (cdr args))
		(error 'canvas-arrow-to "Illegal arguments" args)
		(cond
		   ((eq? (car args) :angle)
		    (set! an (cadr args))
		    (loop (cddr args)))
		   ((eq? (car args) :length)
		    (set! len (cadr args))
		    (loop (cddr args)))
		   ((eq? (car args) :to)
		    (set! head (cadr args))
		    (loop (cddr args)))
		   ((eq? (car args) :from)
		    (set! tail (cadr args))
		    (loop (cddr args)))
		   (else
		    (error 'canvas-arrow-to "Illegal arguments" args))))))
      (let* ((d (sqrt (+ (* (- x1 x0) (- x1 x0)) (* (- y1 y0) (- y1 y0)))))
	     (ah (let ((acos (Math.acos (/ (- x1 x0) d))))
		    (if (> y1 y0)
			acos
			(- acos))))
	     (at (+ ah Math.PI))
	     (x1a (- x1 (* len (cos (+ ah an)))))
	     (y1a (- y1 (* len (sin (+ ah an)))))
	     (x1b (- x1 (* len (cos (- ah an)))))
	     (y1b (- y1 (* len (sin (- ah an)))))
	     (x0a (- x0 (* len (cos (+ at an)))))
	     (y0a (- y0 (* len (sin (+ at an)))))
	     (x0b (- x0 (* len (cos (- at an)))))
	     (y0b (- y0 (* len (sin (- at an))))))
	 ;; the line
	 (let ((lx0 (if tail (+ x0a (/ (- x0b x0a) 2)) x0))
	       (ly0 (if tail (+ y0a (/ (- y0b y0a) 2)) y0))
	       (lx1 (if head (+ x1a (/ (- x1b x1a) 2)) x1))
	       (ly1 (if head (+ y1a (/ (- y1b y1a) 2)) y1)))
	    (ctx.beginPath)
	    (ctx.moveTo lx0 ly0)
	    (ctx.lineTo lx1 ly1)
	    (ctx.stroke))
	 ;; the head
	 (when head
	    (ctx.beginPath)
	    (ctx.moveTo x1 y1)
	    (ctx.lineTo x1a y1a)
	    (ctx.lineTo x1b y1b)
	    (ctx.closePath)
	    (ctx.fill))
	 ;; the tail
	 (when tail
	    (ctx.beginPath)
	    (ctx.moveTo x0 y0)
	    (ctx.lineTo x0a y0a)
	    (ctx.lineTo x0b y0b)
	    (ctx.closePath)
	    (ctx.fill)))))

;*---------------------------------------------------------------------*/
;*    canvas-quadratic-arrow-to ...                                    */
;*---------------------------------------------------------------------*/
(define (canvas-quadratic-arrow-to ctx x0 y0 cpx cpy x1 y1 . args)
   (let* ((len (* 5 ctx.lineWidth))
	  (an 0.4)
	  (head #t)
	  (tail #f))
      ;; arguments parsing
      (let loop ((args args))
	 (when (pair? args)
	    (if (null? (cdr args))
		(error 'canvas-arrow-to "Illegal arguments" args)
		(cond
		   ((eq? (car args) :angle)
		    (set! an (cadr args))
		    (loop (cddr args)))
		   ((eq? (car args) :length)
		    (set! len (cadr args))
		    (loop (cddr args)))
		   ((eq? (car args) :to)
		    (set! head (cadr args))
		    (loop (cddr args)))
		   ((eq? (car args) :from)
		    (set! tail (cadr args))
		    (loop (cddr args)))
		   (else
		    (error 'canvas-arrow-to "Illegal arguments" args))))))
      (let* ((dh (sqrt (+ (* (- x1 cpx) (- x1 cpx)) (* (- y1 cpy) (- y1 cpy)))))
	     (ah (let ((acos (Math.acos (/ (- x1 cpx) dh))))
		    (if (> y1 cpy)
			acos
			(- acos))))
	     (dt (sqrt (+ (* (- x0 cpx) (- x0 cpx)) (* (- y0 cpy) (- y0 cpy)))))
	     (at (let ((acos (Math.acos (/ (- x0 cpx) dt))))
		    (if (> y0 cpy)
			acos
			(- acos))))
	     (x1a (- x1 (* len (cos (+ ah an)))))
	     (y1a (- y1 (* len (sin (+ ah an)))))
	     (x1b (- x1 (* len (cos (- ah an)))))
	     (y1b (- y1 (* len (sin (- ah an)))))
	     (x0a (- x0 (* len (cos (+ at an)))))
	     (y0a (- y0 (* len (sin (+ at an)))))
	     (x0b (- x0 (* len (cos (- at an)))))
	     (y0b (- y0 (* len (sin (- at an))))))
	 ;; the curve
	 (let ((cx0 (if tail (+ x0a (/ (- x0b x0a) 2)) x0))
	       (cy0 (if tail (+ y0a (/ (- y0b y0a) 2)) y0))
	       (cx1 (if head (+ x1a (/ (- x1b x1a) 2)) x1))
	       (cy1 (if head (+ y1a (/ (- y1b y1a) 2)) y1)))
	    (ctx.beginPath)
	    (ctx.moveTo cx0 cy0)
	    (ctx.quadraticCurveTo cpx cpy cx1 cy1)
	    (ctx.stroke))
	 ;; the head
	 (when head
	    (ctx.beginPath)
	    (ctx.moveTo x1 y1)
	    (ctx.lineTo x1a y1a)
	    (ctx.lineTo x1b y1b)
	    (ctx.closePath)
	    (ctx.fill))
	 ;; the tail
	 (when tail
	    (ctx.beginPath)
	    (ctx.moveTo x0 y0)
	    (ctx.lineTo x0a y0a)
	    (ctx.lineTo x0b y0b)
	    (ctx.closePath)
	    (ctx.fill)))))
      