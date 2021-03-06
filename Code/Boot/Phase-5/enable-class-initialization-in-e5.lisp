(cl:in-package #:sicl-boot-phase-5)

(defun define-add-remove-direct-subclass (e5)
  ;; REMOVE is called by REMOVE-DIRECT-SUBCLASS in order to remove a
  ;; class from the list of subclasses of some class.
  (import-function-from-host 'remove e5)
  (load-file "CLOS/add-remove-direct-subclass-support.lisp" e5)
  (load-file "CLOS/add-remove-direct-subclass-defgenerics.lisp" e5)
  (load-file "CLOS/add-remove-direct-subclass-defmethods.lisp" e5))

(defun define-add-remove-method (e5)
  (load-file "CLOS/add-remove-method-defgenerics.lisp" e5)
  ;; MAKE-LIST is called when a method is removed and a new
  ;; specializer profile must be computed.
  (import-function-from-host 'make-list e5)
  ;; FIND-IF is called by ADD-METHOD in order to find and existing
  ;; method with the same specializers and the same qualifiers, so
  ;; that that existing method can be removed first.
  (import-function-from-host 'find-if e5)
  (load-file-protected "CLOS/add-remove-method-support.lisp" e5)
  (load-file "CLOS/add-remove-method-defmethods.lisp" e5))

(defun define-add-remove-direct-method (e5)
  ;; ADJOIN is called by ADD-DIRECT-METHOD.
  ;; REMOVE is called by REMOVE-DIRECT-METHOD.
  (import-functions-from-host '(adjoin remove) e5)
  (load-file "CLOS/add-remove-direct-method-defgenerics.lisp" e5)
  (load-file "CLOS/add-remove-direct-method-support.lisp" e5)
  (load-file "CLOS/add-remove-direct-method-defmethods.lisp" e5))

(defun define-reader/writer-method-class (e4 e5)
  (setf (sicl-genv:fdefinition 'sicl-clos:reader-method-class e5)
        (lambda (&rest arguments)
          (declare (ignore arguments))
          (sicl-genv:find-class 'sicl-clos:standard-reader-method e4)))
  (setf (sicl-genv:fdefinition 'sicl-clos:writer-method-class e5)
        (lambda (&rest arguments)
          (declare (ignore arguments))
          (sicl-genv:find-class 'sicl-clos:standard-writer-method e4))))

(defun define-direct-slot-definition-class (e4 e5)
  (setf (sicl-genv:fdefinition 'sicl-clos:direct-slot-definition-class e5)
        (lambda (&rest arguments)
          (declare (ignore arguments))
          (sicl-genv:find-class 'sicl-clos:standard-direct-slot-definition e4))))

(defun define-find-or-create-generic-function (e5 e6)
  (setf (sicl-genv:fdefinition 'sicl-clos::find-or-create-generic-function e5)
        (lambda (name lambda-list)
          (declare (ignore lambda-list))
          (sicl-genv:fdefinition name e6))))

(defun define-validate-superclass (e5)
  (setf (sicl-genv:fdefinition 'sicl-clos:validate-superclass e5)
        (constantly t)))

(defun define-dependent-protocol (e5)
  (setf (sicl-genv:fdefinition 'sicl-clos:map-dependents e5)
        (constantly nil))
  (setf (sicl-genv:fdefinition 'sicl-clos:update-dependent e5)
        (constantly nil)))

(defun define-ensure-class (e5)
  (load-file "CLOS/ensure-class-using-class-support.lisp" e5)
  ;; When we loaded the support code, we defined
  ;; FIND-SUPERCLASS-OR-NIL to call FIND-CLASS, but that's wrong
  ;; during bootstrapping, so we redifine it here.
  (setf (sicl-genv:fdefinition 'sicl-clos::find-superclass-or-nil e5)
        (lambda (name)
          (sicl-genv:find-class name e5)))
  ;; Uncomment this code once we have the class NULL.
  ;; (load-file "CLOS/ensure-class-using-class-defgenerics.lisp" e5)
  ;; (load-file "CLOS/ensure-class-using-class-defmethods.lisp" e5)
  (setf (sicl-genv:fdefinition 'sicl-clos:ensure-class e5)
        (lambda (&rest arguments)
          (apply (sicl-genv:fdefinition
                  'sicl-clos::ensure-class-using-class-null e5)
                 nil arguments))))

(defun enable-class-initialization-in-e5 (e4 e5 e6)
  (import-functions-from-host '(sicl-genv:typep) e5)
  (setf (sicl-genv:fdefinition 'typep e5)
        (lambda (object type)
          (sicl-genv:typep object type e5)))
  (define-validate-superclass e5)
  (define-direct-slot-definition-class e4 e5)
  (define-add-remove-direct-subclass e5)
  (setf (sicl-genv:special-variable 'sicl-clos::*class-t* e5 t) nil)
  (define-add-remove-method e5)
  (load-file-protected "CLOS/add-accessor-method.lisp" e5)
  (define-find-or-create-generic-function e5 e6)
  (setf (sicl-genv:fdefinition 'sicl-clos::find-superclass e5)
        (lambda (name)
          (sicl-genv:find-class name e5)))
  (load-file "CLOS/default-superclasses-defgeneric.lisp" e5)
  (load-file "CLOS/default-superclasses-defmethods.lisp" e5)
  (load-file "CLOS/class-initialization-support.lisp" e5)
  (load-file "CLOS/class-initialization-defmethods.lisp" e5)
  (setf (sicl-genv:fdefinition '(setf find-class) e5)
        (lambda (new-class symbol &optional errorp)
          (declare (ignore errorp))
          (setf (sicl-genv:find-class symbol e5) new-class)))
  (define-error-function 'change-class e5)
  (load-file "CLOS/reinitialize-instance-defgenerics.lisp" e5)
  (define-ensure-class e5)
  (import-function-from-host 'sicl-clos:defclass-expander e5)
  (load-file "CLOS/defclass-defmacro.lisp" e5)
  (import-function-from-host '(setf sicl-genv:special-variable) e5)
  (define-error-function 'slot-value e5)
  (define-error-function '(setf slot-value) e5)
  (import-functions-from-host
   '(equal set-exclusive-or sicl-genv:find-class)
   e5)
  ;; FIXME: load files containing the definition instead.
  (setf (sicl-genv:fdefinition 'sicl-clos:add-direct-method e5)
        (constantly nil))
  (define-dependent-protocol e5)
  (define-reader/writer-method-class e4 e5))
