(in-package :cepl.context)

;;----------------------------------------------------------------------

(defclass cepl-context nil
  ((gl-context :initform nil) (uninitialized-resources :initform nil)
   ;;- - - - - - - - - - - - - - - - - - - - - - - -
   (vao-binding-id :initform +unknown-gl-id+ :type vao-id)
   ;;- - - - - - - - - - - - - - - - - - - - - - - -
   (current-viewport :initform nil :type (or null viewport))
   (default-viewport :initform nil :type (or null viewport))
   ;;- - - - - - - - - - - - - - - - - - - - - - - -
   (default-framebuffer :initform nil :type (or null fbo))
   ;;- - - - - - - - - - - - - - - - - - - - - - - -
   (read-fbo-binding-id :initform +unknown-gl-id+ :type gl-id)
   (draw-fbo-binding-id :initform +unknown-gl-id+ :type gl-id)
   (fbos :initform (make-array 0 :element-type 'fbo :initial-element +null-fbo+
                               :adjustable t :fill-pointer 0))
   ;;- - - - - - - - - - - - - - - - - - - - - - - -
   (array-of-bound-gpu-buffer-ids
    :initform (make-array 12 :element-type 'gl-id :initial-element
                          +null-gl-id+))
   (array-of-gpu-buffers
    :initform (make-array 0 :element-type 'gpu-buffer :initial-element
                          +null-gpu-buffer+ :adjustable t :fill-pointer 0))
   ;;- - - - - - - - - - - - - - - - - - - - - - - -
   ;; {TODO} Init this at context time using max data. Then remove extend
   ;;        from bind func
   (array-of-ubo-bindings-buffer-ids
    :initform (make-array 0 :element-type 'gl-id :initial-element
                          +null-gl-id+ :adjustable t :fill-pointer 0))
   ;;- - - - - - - - - - - - - - - - - - - - - - - -
   ;; {TODO} Init this at context time using max data. Then remove extend
   ;;        from bind func
   (array-of-transform-feedback-bindings-buffer-ids
    :initform (make-array 0 :element-type 'gl-id :initial-element
                          +null-gl-id+ :adjustable t :fill-pointer 0))
   ;;- - - - - - - - - - - - - - - - - - - - - - - -
   (array-of-bound-texture-ids
    :initform (make-array 11 :element-type 'gl-id :initial-element
                          +null-gl-id+))
   (array-of-textures
    :initform (make-array 0 :element-type 'texture :initial-element
                          +null-texture+ :adjustable t :fill-pointer 0))
   ;;- - - - - - - - - - - - - - - - - - - - - - - -
   (map-of-pipeline-names-to-gl-ids
    :initform (make-hash-table :test #'eq))
   ;;- - - - - - - - - - - - - - - - - - - - - - - -
   (depth-func :initform :unknown)
   (depth-mask :initform :unknown)
   ;;- - - - - - - - - - - - - - - - - - - - - - - -
   (depth-range :initform :unknown)
   (depth-clamp :initform :unknown)
   ;;- - - - - - - - - - - - - - - - - - - - - - - -
   (cull-face :initform :unknown)
   (front-face :initform :unknown)
   ;;- - - - - - - - - - - - - - - - - - - - - - - -
   (clear-color :initform :unknown)))

(defvar *cepl-context*
  (make-instance 'cepl-context))

;;----------------------------------------------------------------------

(defun register-gpu-buffer (cepl-context gpu-buffer)
  (with-slots (array-of-gpu-buffers)
      cepl-context
    (let ((id (gpu-buffer-id gpu-buffer)))
      (assert (> id 0) (id)
              "Attempted to register ~s before id fully initialized"
              'gpu-buffer)
      (ensure-vec-index array-of-gpu-buffers id +null-gpu-buffer+)
      (setf (aref array-of-gpu-buffers id) gpu-buffer))))

(defun register-texture (cepl-context texture)
  (with-slots (array-of-textures)
      cepl-context
    (let ((id (texture-id texture)))
      (assert (> id 0) (id)
              "Attempted to register ~s before id fully initialized" 'texture)
      (ensure-vec-index array-of-textures id +null-texture+)
      (setf (aref array-of-textures id) texture))))

(defun register-fbo (cepl-context fbo)
  (with-slots (fbos) cepl-context
    (let ((id (%fbo-id fbo)))
      (ensure-vec-index fbos id +null-fbo+)
      (setf (aref fbos id) fbo))))

;;----------------------------------------------------------------------
;; GPU-Buffers

;; Raw Cache indexed part

(defn-inline gpu-buffer-bound-id ((ctx cepl-context) (index (integer 0 11)))
    gl-id
  (with-slots (array-of-bound-gpu-buffer-ids) ctx
    (declare (type (simple-array gl-id) array-of-bound-gpu-buffer-ids))
    (aref array-of-bound-gpu-buffer-ids index)))

(let ((cache-id->enum-id
       #(34962 37568 36662 36663 37102 36671 34963 35051 35052 37266 37074
         35882)))
  (defun set-gpu-buffer-bound-id (ctx index id)
    (with-slots (array-of-bound-gpu-buffer-ids gl-context) ctx
      (let ((current (gpu-buffer-bound-id ctx index))
            (bind-id (if (unknown-gl-id-p id)
                         0
                         id)))
        (unless (= id current)
          (gl:bind-buffer (aref cache-id->enum-id index) bind-id)
          (setf (aref array-of-bound-gpu-buffer-ids index) id))
        id))))

;; User friendly part

(defn buffer-kind->cache-index ((kind keyword))
    (integer 0 11)
  (ecase kind
    (:array-buffer 0)
    (:atomic-counter-buffer 1)
    (:copy-read-buffer 2)
    (:copy-write-buffer 3)
    (:dispatch-indirect-buffer 4)
    (:draw-indirect-buffer 5)
    (:element-array-buffer 6)
    (:pixel-pack-buffer 7)
    (:pixel-unpack-buffer 8)
    (:query-buffer 9)
    (:shader-storage-buffer 10)
    (:texture-buffer 11)))

;; {TODO}
;; :atomic-counter-buffer
;; :shader-storage-buffer

(defun gpu-buffer-bound (ctx target)
  (let ((index (buffer-kind->cache-index target)))
    (with-slots (array-of-gpu-buffers gl-context)
        ctx
      (let* ((id (gpu-buffer-bound-id ctx index))
             (id
              (if (unknown-gl-id-p id)
                  (set-gpu-buffer-bound-id ctx index (gl:get* target))
                  id)))
        (when (and (>= id 0) (< (length array-of-gpu-buffers)))
          (aref array-of-gpu-buffers id))))))

(defun (setf gpu-buffer-bound) (val ctx target)
  (let ((index (buffer-kind->cache-index target)))
    (set-gpu-buffer-bound-id ctx index (gpu-buffer-id val))))

;;----------------------------------------------------------------------
;; Uniform Buffer Objects
;;
;; UBOs don't exist as a true GLObjects. There are a number of bindings points
;; which you can attach regions of a gpu-buffer to so that pipelines can read
;; from them as uniforms.
;;
;; Although this is really about gpu-buffers we choose to keep this seperate
;; from the gpu-buffer section above as the GL context has multiple ubo
;; binding-points trying to mix them in the cache above was more confusing than
;; helpful.

(defun ubo-bind-buffer-id-range
    (ctx id ubo-binding-point offset size)
  (assert (and offset size))
  ;; don't worry about checking cache for avoiding rebinding as we dont want to
  ;; cache ranges (yet?)
  (with-slots (array-of-ubo-bindings-buffer-ids) ctx
    (ensure-vec-index array-of-ubo-bindings-buffer-ids ubo-binding-point
                      +null-gl-id+)
    (let ((bind-id (if (unknown-gl-id-p id) 0 id)))
      (%gl:bind-buffer-range
       :uniform-buffer ubo-binding-point bind-id offset size)
      (setf (aref array-of-ubo-bindings-buffer-ids ubo-binding-point) id)
      id)))

;;----------------------------------------------------------------------
;; Transform Feedback Buffers
;;
;; Although this is really about gpu-buffers we choose to keep this seperate
;; from the gpu-buffer section above as the GL context has multiple tfb
;; binding-points trying to mix them in the cache above was more confusing than
;; helpful.

(defun transform-feedback-bind-buffer-id-range
    (ctx id tfb-binding-point offset size)
  (assert (and offset size))
  ;; don't worry about checking cache for avoiding rebinding as we dont want to
  ;; cache ranges (yet?)
  (with-slots (array-of-transform-feedback-bindings-buffer-ids) ctx
    (ensure-vec-index array-of-transform-feedback-bindings-buffer-ids
                      tfb-binding-point
                      +null-gl-id+)
    (let ((bind-id (if (unknown-gl-id-p id) 0 id)))
      (%gl:bind-buffer-range
       :uniform-buffer tfb-binding-point bind-id offset size)
      (setf (aref array-of-transform-feedback-bindings-buffer-ids
                  tfb-binding-point)
            id)
      id)))

;;----------------------------------------------------------------------

;; GL binding part

;; (mapcar (lambda (x) (cffi:foreign-enum-value '%gl::enum x))
;;         '(:texture-binding-1d :texture-binding-2d :texture-binding-3d
;;           :texture-binding-1d-array :texture-binding-2d-array
;;           :texture-binding-rectangle :texture-binding-cube-map
;;           :texture-binding-cube-map-array :texture-binding-buffer
;;           :texture-binding-2d-multisample
;;           :texture-binding-2d-multisample-array))

(let ((cache-id->enum-id
       #(32872 32873 32874 35868 35869 34038 34068 36874 35884 37124 37125)))
  (defun %texture-binding (gl-ctx index)
    (declare (ignore gl-ctx))
    (let ((enum-val (aref cache-id->enum-id index)))
      (cl-opengl:get-integer enum-val 1))))

;; (mapcar (lambda (x) (cffi:foreign-enum-value '%gl::enum x))
;;         '(:texture-1d :texture-2d :texture-3d :texture-1d-array
;;           :texture-2d-array :texture-rectangle :texture-cube-map
;;           :texture-cube-map-array :texture-buffer :texture-2d-multisample
;;           :texture-2d-multisample-array))
(let ((cache-id->enum-id
       #(3552 3553 32879 35864 35866 34037 34067 36873 35882 37120 37122)))
  (defun (setf %texture-binding) (id gl-ctx index)
    (declare (ignore gl-ctx))
    (let ((target-val (aref cache-id->enum-id index)))
      ;; {TODO} we have already calculated the enum, try and remove the
      ;;        condition checking if keyword
      (gl:bind-texture target-val id))
    id))

;; Raw cached index part

(declaim (inline texture-bound-id))
(defun texture-bound-id (ctx index)
  (with-slots (array-of-bound-texture-ids) ctx
    (aref array-of-bound-texture-ids index)))

(defun set-texture-bound-id (ctx index id)
  (with-slots (array-of-bound-texture-ids gl-context)
      ctx
    (let ((current (texture-bound-id ctx index))
          (bind-id
           (if (unknown-gl-id-p id)
               0
               id)))
      (unless (= id current)
        (setf (%texture-binding gl-context index) bind-id)
        (setf (aref array-of-bound-texture-ids index) id))
      id)))

;; human friendly part

(defun tex-kind->cache-index (kind)
  (ecase kind
    (:texture-1d 0)
    (:texture-2d 1)
    (:texture-3d 2)
    (:texture-1d-array 3)
    (:texture-2d-array 4)
    (:texture-rectangle 5)
    (:texture-cube-map 6)
    (:texture-cube-map-array 7)
    (:texture-buffer 8)
    (:texture-2d-multisample 9)
    (:texture-2d-multisample-array 10)))

(defun texture-bound (ctx target)
  (let ((index (tex-kind->cache-index target)))
    (with-slots (array-of-textures gl-context)
        ctx
      (let* ((id (texture-bound-id ctx index))
             (id
              (if (unknown-gl-id-p id)
                  (set-texture-bound-id ctx index
                                        (%texture-binding gl-context index))
                  id)))
        (when (and (>= id 0) (< (length array-of-textures)))
          (aref array-of-textures id))))))

(defun (setf texture-bound) (val ctx target)
  (let ((index (tex-kind->cache-index target)))
    (set-texture-bound-id ctx index (texture-id val))))


;;----------------------------------------------------------------------

;; GL_READ_FRAMEBUFFER_BINDING (name, intially 0, see glBindFramebuffer)
;;     The framebuffer object currently bound to the GL_READ_FRAMEBUFFER target. If the default framebuffer is bound, this value will be zero.
(defun read-framebuffer-binding (context)
  (declare (ignore context))
  (cl-opengl:get* :read-framebuffer-binding))

(defun (setf read-framebuffer-binding) (id context)
  (declare (ignore context))
  (gl:bind-framebuffer :read-framebuffer id)
  id)

;; GL_DRAW_FRAMEBUFFER_BINDING (name, initially 0, see glBindFramebuffer)
;;     The framebuffer object currently bound to the GL_DRAW_FRAMEBUFFER target. If the default framebuffer is bound, this value will be zero.
(defun draw-framebuffer-binding (context)
  (declare (ignore context))
  (cl-opengl:get* :draw-framebuffer-binding))

(defun (setf draw-framebuffer-binding) (id context)
  (declare (ignore context))
  (gl:bind-framebuffer :draw-framebuffer id)
  id)

;; The GL_FRAMEBUFFER target sets both the read and the write to the same FBO.
(defun framebuffer-binding (context)
  (cons (read-framebuffer-binding context)
        (draw-framebuffer-binding context)))

(defun (setf framebuffer-binding) (id context)
  (declare (ignore context))
  (gl:bind-framebuffer :framebuffer id)
  id)

(defun read-fbo-bound (cepl-context)
  (with-slots (gl-context fbos read-fbo-binding-id) cepl-context
    (let* ((id (if (= read-fbo-binding-id +unknown-gl-id+)
                   (setf read-fbo-binding-id
                         (read-framebuffer-binding gl-context))
                   read-fbo-binding-id))
           (fbo (when (>= id 0) (aref fbos id))))
      (assert (not (eq fbo +null-fbo+)))
      fbo)))

(defun (setf read-fbo-bound) (fbo cepl-context)
  (with-slots (gl-context fbos read-fbo-binding-id) cepl-context
    (let ((id (if fbo
                  (%fbo-id fbo)
                  0)))
      (when (/= id read-fbo-binding-id)
        (setf (read-framebuffer-binding gl-context) id
              read-fbo-binding-id id))
      fbo)))

(defun draw-fbo-bound (cepl-context)
  (with-slots (gl-context fbos draw-fbo-binding-id) cepl-context
    (let* ((id (if (= draw-fbo-binding-id +unknown-gl-id+)
                   (setf draw-fbo-binding-id
                         (draw-framebuffer-binding gl-context))
                   draw-fbo-binding-id))
           (fbo (when (>= id 0) (aref fbos id))))
      (assert (not (eq fbo +null-fbo+)))
      fbo)))

(defun (setf draw-fbo-bound) (fbo cepl-context)
  (with-slots (gl-context fbos draw-fbo-binding-id) cepl-context
    (let ((id (if fbo
                  (%fbo-id fbo)
                  0)))
      (when (/= id draw-fbo-binding-id)
        (setf (draw-framebuffer-binding gl-context) id
              draw-fbo-binding-id id))
      fbo)))

(defun fbo-bound (cepl-context)
  (cons (read-fbo-bound cepl-context)
        (draw-fbo-bound cepl-context)))

(defun (setf fbo-bound) (fbo cepl-context)
  (assert (typep fbo 'fbo))
  (with-slots (gl-context fbos read-fbo-binding-id draw-fbo-binding-id)
      cepl-context
    (let* ((id (if fbo
                   (%fbo-id fbo)
                   0))
           (r-dif (/= id read-fbo-binding-id))
           (d-dif (/= id draw-fbo-binding-id)))
      (cond
        ((and r-dif d-dif) (setf (framebuffer-binding gl-context) id))
        (r-dif (setf (read-framebuffer-binding gl-context) id))
        (d-dif (setf (draw-framebuffer-binding gl-context) id)))
      (setf draw-fbo-binding-id id
            read-fbo-binding-id id)
      fbo)))

;;----------------------------------------------------------------------

;; GL_VERTEX_ARRAY_BINDING (GLint, initially 0, see glBindVertexArray)
;; The name of the vertex array object currently bound to the context, or 0 if
;; none is bound.

(defun vertex-array-binding (context)
  (declare (ignore context))
  (cl-opengl:get* :vertex-array-binding))

(defun (setf vertex-array-binding) (id context)
  (declare (ignore context))
  (gl:bind-vertex-array id)
  id)

(defun vao-bound (cepl-context)
  (with-slots (gl-context vao-binding-id) cepl-context
    (if (= vao-binding-id +unknown-gl-id+)
        (setf vao-binding-id (vertex-array-binding gl-context))
        vao-binding-id)))

(defun (setf vao-bound) (vao cepl-context)
  (with-slots (gl-context vao-binding-id) cepl-context
    (when (/= vao-binding-id vao)
      (setf (vertex-array-binding gl-context) vao)
      (setf vao-binding-id vao)))
  vao)

;;----------------------------------------------------------------------
