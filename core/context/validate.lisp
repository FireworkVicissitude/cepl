(in-package :cepl.context)

;;----------------------------------------------------------------------

(defvar *validate-error-message-pattern*
  "CEPL: The CEPL context has been found to be invalid:~{~%~a~}")

(defun validate-cepl-context (cepl-context)
  (let* ((ctx cepl-context)
         (failure-messages
          (append (check-buffer-bindings ctx))))
    (when failure-messages
      (error *validate-error-message-pattern*
             failure-messages))))

(defun id-valid (predicted actual)
  (not (null (or (unknown-gl-id-p predicted)
                 (= predicted actual)))))

(defun check-buffer-bindings (ctx)
  (loop :for target :in '(:array-buffer
                          :atomic-counter-buffer
                          :copy-read-buffer
                          :copy-write-buffer
                          :dispatch-indirect-buffer
                          :draw-indirect-buffer
                          :element-array-buffer
                          :pixel-pack-buffer
                          :pixel-unpack-buffer
                          :query-buffer
                          :shader-storage-buffer
                          :texture-buffer)
     :for cache-id := (buffer-kind->cache-index target)
     :for cached-val := (gpu-buffer-bound-id ctx cache-id)
     :for actual-val := (gl:get* target)
     :for valid := (id-valid cache-id actual-val)
     :unless valid
     :collect (list :buffer-bindings target cached-val actual-val)))
