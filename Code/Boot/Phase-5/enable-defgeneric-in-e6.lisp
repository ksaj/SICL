(cl:in-package #:sicl-boot-phase-5)

(defun ensure-generic-function-phase-5 (boot)
  (with-accessors ((e4 sicl-boot:e4)
                   (e5 sicl-boot:e5)
                   (e6 sicl-boot:e6))
      boot
    (let* ((gf-class-name 'standard-generic-function)
           (gf-class (sicl-genv:find-class gf-class-name e4))
           (method-class-name 'standard-method)
           (method-class (sicl-genv:find-class method-class-name e4))
           (make-instance (sicl-genv:fdefinition 'make-instance e5))
           (method-combination
             (funcall (sicl-genv:fdefinition
                       'sicl-method-combination:find-method-combination e5)
                      'standard '() e5)))
      (setf (sicl-genv:fdefinition 'ensure-generic-function e6)
            (lambda (function-name &rest arguments
                     &key environment
                     &allow-other-keys)
              (let ((args (copy-list arguments)))
                (loop while (remf args :environment))
                (if (sicl-genv:fboundp function-name environment)
                    (sicl-genv:fdefinition function-name environment)
                    (setf (sicl-genv:fdefinition function-name environment)
                          (apply make-instance
                                 gf-class
                                 :name function-name
                                 :method-class method-class
                                 :method-combination method-combination
                                 args)))))))))


(defun enable-defgeneric-in-e6 (boot)
  (with-accessors ((e4 sicl-boot:e4)
                   (e5 sicl-boot:e5)
                   (e6 sicl-boot:e6))
      boot
    (ensure-generic-function-phase-5 boot)
    (import-function-from-host 'sicl-clos:defgeneric-expander e6)
    (load-file "CLOS/defgeneric-defmacro.lisp" e6)))



