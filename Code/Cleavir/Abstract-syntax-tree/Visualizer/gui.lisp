(cl:in-package #:cleavir-ast-visualizer)

(clim:define-application-frame visualizer ()
    ((%ast :initarg :ast :reader ast))
  (:panes (application
           :application
           :scroll-bars nil
           :display-function 'display-ast
           :text-style (clim:make-text-style :sans-serif :roman 12))
          (interactor :interactor :scroll-bars nil))
  (:layouts (default (clim:vertically (:width 1200 :height 900)
                       (4/5 (clim:scrolling () application))
                       (1/5 (clim:scrolling () interactor))))))

(defgeneric label (ast))

(defmethod label (ast)
  (cleavir-ast-graphviz::label ast))

(defmethod label ((ast cleavir-ast:constant-fdefinition-ast))
  "c-fdef")

(defmethod label ((ast cleavir-ast:fdefinition-ast))
  "fdef")

(defmethod label ((ast cleavir-ast:constant-ast))
  "const")

(defmethod label ((ast cleavir-ast:load-time-value-ast))
  "l-t-v")

(defgeneric ast-width (ast))

(defmethod ast-width (ast)
  60)

(defgeneric ast-height (ast))

(defmethod ast-height (ast)
  30)

(defun draw (ast pane x y)
  (let ((width (ast-width ast))
        (height (ast-height ast)))
    (clim:with-output-as-presentation (pane ast 'cleavir-ast:ast)
      (clim:draw-rectangle* pane x y (+ x width) (+ y height) :filled nil)
      (clim:draw-text* pane (label ast)
                       (+ x (/ width 2)) (+ y (/ height 2))
                       :align-x :center :align-y :center))))

(defun display-ast (frame pane)
  (let* ((ast (ast frame))
         (table (make-hash-table :test #'eq)))
    (labels ((draw-ast (ast x y)
               (if (gethash ast table)
                   y
                   (let ((children (cleavir-ast:children ast)))
                     (draw ast pane x y)
                     (setf (gethash ast table) t)
                     (if (null children)
                         (+ y (ast-height ast) 10)
                         (loop for child in children
                               for width = (ast-width child)
                               do (setf y (draw-ast child (+ x width 10) y))
                               finally (return y)))))))
      (draw-ast ast 10 10))))
                 
(defun visualize (ast)
  (clim:run-frame-top-level
   (clim:make-application-frame 'visualizer :ast ast)))

(define-visualizer-command (com-quit :name t) ()
  (clim:frame-exit clim:*application-frame*))

(define-visualizer-command (com-inspect-ast :name t)
    ((ast 'cleavir-ast:ast))
  (clouseau:inspector ast))
