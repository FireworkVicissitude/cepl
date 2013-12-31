(in-package :primitives)

;; [TODO] Add Cone & Cylinder

(defun primitive-data (type &key (size 1.0))
  (case type
    (:plain (plain-data :size size))
    ((:box :cube) (box-data :width size :height size :depth size))
    (:sphere (sphere-data :radius size))
    (t (error "Do not have data for that primitive"))))

(defun plain-data (&key (size 1.0) (colors t) (normals t))
  (list (list `(,(v! (- size) (- size) 0.0) 	
                    ,@(when colors `(,(v! 0.0 0.0 1.0)))
                    ,@(when normals `(,(v! 0.0 1.0)))) 			
              `(,(v! size (- size) 0.0) 
                    ,@(when colors `(,(v! 0.0 0.0 1.0)))
                    ,@(when normals `(,(v! 1.0 1.0))))
              `(,(v! size size 0.0)
                    ,@(when colors `(,(v! 0.0 0.0 1.0)))
                    ,@(when normals `(,(v! 1.0 0.0))))
              `(,(v! (- size) size 0.0)
                    ,@(when colors `(,(v! 0.0 0.0 1.0)))
                    ,@(when normals `(,(v! 0.0 0.0)))))
        nil))

(defun box-data (&key (width 1.0) (height 1.0) (depth 1.0)
                   (colors t) (normals t))
  (let ((width (/ width 2.0))
        (height (/ height 2.0))
        (depth (/ depth 2.0)))
    ;; [TODO] why is each side a seperate list?
    (list (list  `(,(v! (- width) (- height) depth)
                       ,@(when colors `(,(v! 0.0 0.0 1.0)))
                       ,@(when normals `(,(v! 0.0 1.0)))) 
                 `(,(v! width (- height) depth)
                       ,@(when colors `(,(v! 0.0 0.0 1.0)))
                       ,@(when normals `(,(v! 1.0 1.0))))
                 `(,(v! width height depth)
                       ,@(when colors `(,(v! 0.0 0.0 1.0)))
                       ,@(when normals `(,(v! 1.0 0.0))))
                 `(,(v! (- width) height depth)
                       ,@(when colors `(,(v! 0.0 0.0 1.0)))
                       ,@(when normals `(,(v! 0.0 0.0))))
                 `(,(v! width (- height) (- depth))
                       ,@(when colors `(,(v! 0.0 0.0 -1.0)))
                       ,@(when normals `(,(v! 0.0 1.0))))
                 `(,(v! (- width) (- height) (- depth))
                       ,@(when colors `(,(v! 0.0 0.0 -1.0)))
                       ,@(when normals `(,(v! 1.0 1.0))))
                 `(,(v! (- width) height (- depth))
                       ,@(when colors `(,(v! 0.0 0.0 -1.0)))
                       ,@(when normals `(,(v! 1.0 0.0))))
                 `(,(v! width height (- depth))
                       ,@(when colors `(,(v! 0.0 0.0 -1.0)))
                       ,@(when normals `(,(v! 0.0 0.0))))
                 `(,(v! (- width) (- height) (- depth))
                       ,@(when colors `(,(v! -1.0 0.0 0.0)))
                       ,@(when normals `(,(v! 0.0 1.0))))
                 `(,(v! (- width) (- height) depth)
                       ,@(when colors `(,(v! -1.0 0.0 0.0)))
                       ,@(when normals `(,(v! 1.0 1.0))))
                 `(,(v! (- width) height depth)
                       ,@(when colors `(,(v! -1.0 0.0 0.0)))
                       ,@(when normals `(,(v! 1.0 0.0))))
                 `(,(v! (- width) height (- depth))
                       ,@(when colors `(,(v! -1.0 0.0 0.0)))
                       ,@(when normals `(,(v! 0.0 0.0))))
                 `(,(v! width (- height) depth)
                       ,@(when colors `(,(v! 1.0 0.0 0.0)))
                       ,@(when normals `(,(v! 0.0 1.0))))
                 `(,(v! width (- height) (- depth))
                       ,@(when colors `(,(v! 1.0 0.0 0.0)))
                       ,@(when normals `(,(v! 1.0 1.0))))
                 `(,(v! width height (- depth))
                       ,@(when colors `(,(v! 1.0 0.0 0.0)))
                       ,@(when normals `(,(v! 1.0 0.0))))
                 `(,(v! width height depth)
                       ,@(when colors `(,(v! 1.0 0.0 0.0)))
                       ,@(when normals `(,(v! 0.0 0.0))))
                 `(,(v! (- width) height depth)
                       ,@(when colors `(,(v! 0.0 1.0 0.0)))
                       ,@(when normals `(,(v! 0.0 1.0))))
                 `(,(v! width height depth)
                       ,@(when colors `(,(v! 0.0 1.0 0.0)))
                       ,@(when normals `(,(v! 1.0 1.0))))
                 `(,(v! width height (- depth))
                       ,@(when colors `(,(v! 0.0 1.0 0.0)))
                       ,@(when normals `(,(v! 1.0 0.0))))
                 `(,(v! (- width) height (- depth))
                       ,@(when colors `(,(v! 0.0 1.0 0.0)))
                       ,@(when normals `(,(v! 0.0 0.0))))
                 `(,(v! (- width) (- height) (- depth))
                       ,@(when colors `(,(v! 0.0 -1.0 0.0)))
                       ,@(when normals `(,(v! 0.0 1.0))))
                 `(,(v! width (- height) (- depth))
                       ,@(when colors `(,(v! 0.0 -1.0 0.0)))
                       ,@(when normals `(,(v! 1.0 1.0))))
                 `(,(v! width (- height) depth)
                       ,@(when colors `(,(v! 0.0 -1.0 0.0)))
                       ,@(when normals `(,(v! 1.0 0.0))))
                 `(,(v! (- width) (- height) depth)
                       ,@(when colors `(,(v! 0.0 -1.0 0.0)))
                       ,@(when normals `(,(v! 0.0 0.0)))))
          (list 0 1 2 0 2 3 4 5 6 4 6 7 8 9 10 8 10 11 12 13 14 12 14 15 16 17
                18 16 18 19 20 21 22 20 22 23))))

(defun sphere-data (&key (radius 1.0) (lines-of-latitude 10)
                      (lines-of-longitude 10) (colors t) (normals t))
  (declare ((unsigned-byte 8) lines-of-longitude lines-of-latitude))
  ;; latitude  -  horizontal
  ;; longitude -  vertical
  (let ((faces (make-array (* 6 lines-of-latitude (* (1+ lines-of-longitude)))))
        (lat-angle (/ +pi+ lines-of-latitude))
        (lon-angle (/ (* 2.0 +pi+) lines-of-longitude))
        (f-index 0) (v-index 0))
    (list (loop :for lat :upto lines-of-latitude :append
             (let* ((part (* lat lat-angle))
                    (carry (* radius (sin part)))
                    (y (* radius (cos part))))
               (loop :for lon :upto (1- lines-of-longitude) :collect
                  (let* ((part (* lon lon-angle))
                         (x (* carry (sin part)))
                         (z (* carry (cos part)))
                         (pos (v! x y z)))
                    (when (not (eql lat lines-of-latitude))
                      (let ((part (+ v-index lines-of-longitude)))
                        (setf (aref faces f-index) (1+ part)
                              (aref faces (+ f-index 1))  v-index
                              (aref faces (+ f-index 2)) part
                              (aref faces (+ f-index 3)) (1+ part)
                              (aref faces (+ f-index 4)) (1+ v-index)
                              (aref faces (+ f-index 5)) v-index
                              f-index (+ 6 f-index)
                              v-index (1+ v-index))))
                    `(,(v3:v* pos radius)
                       ,@(when colors `(,(v3:normalize pos)))
                       ,@(when normals
                               `(,(v! (/ lon lines-of-longitude)
                                      (/ lat lines-of-latitude)))))))))
          (coerce faces 'list))))
