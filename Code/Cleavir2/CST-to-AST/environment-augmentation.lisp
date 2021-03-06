(cl:in-package #:cleavir-cst-to-ast)

;;; Take an environment and the CST of a single function definition,
;;; and return a new environment which is like the one passed as an
;;; argument except that it has been augmented by the local function
;;; name.
(defun augment-environment-from-fdef (lexical-environment definition-cst)
  (cst:db origin (name . rest) definition-cst
    (declare (ignore rest))
    (let* ((raw-name (cst:raw name))
           (var-ast (make-instance 'cleavir-ast:lexical-ast
                      :name raw-name)))
      (cleavir-env:add-local-function lexical-environment raw-name var-ast))))

;;; Take an environment, a CST representing list of function
;;; definitions, and return a new environment which is like the one
;;; passed as an argument, except that is has been augmented by the
;;; local function names in the list.
(defun augment-environment-from-fdefs (lexical-environment definitions-cst)
  (loop with result = lexical-environment
        for definition-cst = definitions-cst then (cst:rest definition-cst)
        until (cst:null definition-cst)
        do (setf result
                 (augment-environment-from-fdef result definition-cst))
        finally (return result)))

;;; Augment the environment with a single canonicalized declaration
;;; specifier.
(defgeneric augment-environment-with-declaration
    (declaration-identifier
     declaration-identifier-cst
     declaration-data-cst
     lexical-environment))

(defmethod augment-environment-with-declaration
    (declaration-identifier
     declaration-identifier-cst
     declaration-data-cst
     lexical-environment)
  (warn "Unable to handle declarations specifier: ~s"
        declaration-identifier)
  lexical-environment)

(defmethod augment-environment-with-declaration
    ((declaration-identifier (eql 'dynamic-extent))
     declaration-identifier-cst
     declaration-data-cst
     lexical-environment)
  (let ((var-or-function (cst:first declaration-data-cst)))
    (if (cst:consp var-or-function)
        ;; (dynamic-extent (function foo))
        (cleavir-env:add-function-dynamic-extent
         lexical-environment (cst:second var-or-function))
        ;; (dynamic-extent foo)
        (cleavir-env:add-variable-dynamic-extent
         lexical-environment var-or-function))))

(defmethod augment-environment-with-declaration
    ((declaration-identifier (eql 'ftype))
     declaration-identifier-cst
     declaration-data-cst
     lexical-environment)
  (cleavir-env:add-function-type
   lexical-environment (second declaration-data-cst) (first declaration-data-cst)))

(defmethod augment-environment-with-declaration
    ((declaration-identifier (eql 'ignore))
     declaration-identifier-cst
     declaration-data-cst
     lexical-environment)
  (if (cst:consp (cst:first declaration-data-cst))
      (cleavir-env:add-function-ignore
       lexical-environment
       (cst:second (cst:first declaration-data-cst))
       declaration-identifier-cst)
      (cleavir-env:add-variable-ignore
       lexical-environment
       (cst:first declaration-data-cst)
       declaration-identifier-cst)))

(defmethod augment-environment-with-declaration
    ((declaration-identifier (eql 'ignorable))
     declaration-identifier-cst
     declaration-data-cst
     lexical-environment)
  (if (cst:consp (cst:first declaration-data-cst))
      (cleavir-env:add-function-ignore
       lexical-environment
       (cst:second (cst:first declaration-data-cst))
       declaration-identifier-cst)
      (cleavir-env:add-variable-ignore
       lexical-environment
       (cst:first declaration-data-cst)
       declaration-identifier-cst)))

(defmethod augment-environment-with-declaration
    ((declaration-identifier (eql 'inline))
     declaration-identifier-cst
     declaration-data-cst
     lexical-environment)
  (cleavir-env:add-inline
   lexical-environment (cst:first declaration-data-cst) declaration-identifier-cst))

(defmethod augment-environment-with-declaration
    ((declaration-identifier (eql 'notinline))
     declaration-identifier-cst
     declaration-data-cst
     lexical-environment)
  (cleavir-env:add-inline
   lexical-environment (cst:first declaration-data-cst) declaration-identifier-cst))

(defmethod augment-environment-with-declaration
    ((declaration-identifier (eql 'special))
     declaration-identifier-cst
     declaration-data-cst
     lexical-environment)
  ;; This case is a bit tricky, because if the
  ;; variable is globally special, nothing should
  ;; be added to the environment.
  (let ((info (cleavir-env:variable-info
               lexical-environment (cst:raw (cst:first declaration-data-cst)))))
    (if (and (typep info 'cleavir-env:special-variable-info)
             (cleavir-env:global-p info))
        lexical-environment
        (cleavir-env:add-special-variable
         lexical-environment (cst:raw (cst:first declaration-data-cst))))))

(defmethod augment-environment-with-declaration
    ((declaration-identifier (eql 'type))
     declaration-identifier-cst
     declaration-data-cst
     lexical-environment)
  (cst:db source (type-cst variable-cst) declaration-data-cst
          (cleavir-env:add-variable-type lexical-environment variable-cst type-cst)))

(defmethod augment-environment-with-declaration
    ((declaration-identifier (eql 'optimize))
     declaration-identifier-cst
     declaration-data-cst
     lexical-environment)
  (declare (ignore declaration-identifier-cst declaration-data-cst))
  ;; OPTIMIZE is handled specially, so we do nothing here.
  ;; This method is just for ensuring that the default method,
  ;; which signals a warning, isn't called.
  lexical-environment)

;;; Augment the environment with an OPTIMIZE specifier.
(defun augment-environment-with-optimize (optimize lexical-environment)
  (cleavir-env:add-optimize lexical-environment optimize nil))

;;; Extract any OPTIMIZE information from a set of canonicalized
;;; declaration specifiers.
(defun extract-optimize (canonicalized-dspecs)
  (loop for spec in canonicalized-dspecs
        when (eq (cst:raw (cst:first spec)) 'optimize)
          append (mapcar #'cst:raw (cst:listify (cst:rest spec)))))

;;; Augment the environment with a list of canonical declartion
;;; specifiers.
(defun augment-environment-with-declarations (lexical-environment canonical-dspecs)
  (let ((new-env
          ;; handle OPTIMIZE specially.
          (let ((optimize (extract-optimize canonical-dspecs)))
            (if optimize
                (augment-environment-with-optimize optimize lexical-environment)
                lexical-environment))))
    (loop for spec in canonical-dspecs
          for declaration-identifier-cst = (cst:first spec)
          for declaration-identifier = (cst:raw declaration-identifier-cst)
          ;; FIXME: this is probably wrong.  The data may be contained
          ;; in more than one element.  We need to wrap it in a CST or
          ;; change the interface to a-e-w-d.
          for declaration-data-cst = (cst:rest spec)
          do (setf new-env
                   (augment-environment-with-declaration
                    declaration-identifier
                    declaration-identifier-cst
                    declaration-data-cst
                    new-env)))
    new-env))

;;; Given a single variable bound by some binding form, a list of
;;; canonicalized declaration specifiers, and an environment in which
;;; the binding form is compiled, return true if and only if the
;;; variable to be bound is special.  Return a second value indicating
;;; whether the variable is globally special.
(defun variable-is-special-p (variable declarations lexical-environment)
  (let* ((existing-var-info (cleavir-env:variable-info lexical-environment variable))
         (special-var-p
           (typep existing-var-info 'cleavir-env:special-variable-info)))
    (cond ((loop for declaration in declarations
                 thereis (and (eq (cst:raw (cst:first declaration)) 'special)
                              (eq (cst:raw (cst:second declaration)) variable)))
           ;; If it is declared special it is.
           (values t
                   (and special-var-p
                        (cleavir-env:global-p existing-var-info))))
          ((and special-var-p
            (cleavir-env:global-p existing-var-info))
           ;; It is mentioned in the environment as globally special.
           ;; if it's only special because of a local declaration,
           ;; this binding is not special.
           (values t t))
          (t
           (values nil nil)))))

;;; Given a list of canonicalized declaration specifiers for a single
;;; varible.  Return a type specifier resulting from all the type
;;; declarations present in the list.
(defun declared-type (declarations)
  `(and ,@(loop for declaration in declarations
                when (eq (cst:raw (cst:first declaration)) 'type)
                  collect (cst:raw (cst:second declaration)))))

;;; Given a single variable bound by some binding form like LET or
;;; LET*, and a list of canonical declaration specifiers
;;; concerning that variable, return a new environment that contains
;;; information about that variable.
;;;
;;; LEXICAL-ENVIRONMENT is the environment to be augmented.  If the binding form has
;;; several bindings, it will contain entries for the variables
;;; preceding the one that is currently treated.
;;;
;;; ORIG-ENV is the environment in which we check whether the variable
;;; is globally special.  For a LET form, this is the environment in
;;; which the entire LET form was converted.  For a LET* form, it is
;;; the same as ENV.
(defun augment-environment-with-variable
    (variable-cst declarations lexical-environment orig-env)
  (let ((new-env lexical-environment)
        (raw-variable (cst:raw variable-cst))
        (raw-declarations (mapcar #'cst:raw declarations)))
    (multiple-value-bind (special-p globally-p)
        (variable-is-special-p raw-variable declarations orig-env)
      (if special-p
          (unless globally-p
            (setf new-env
                  (cleavir-env:add-special-variable new-env raw-variable)))
          (let ((var-ast (make-instance 'cleavir-ast:lexical-ast
                           :name raw-variable)))
            (setf new-env
                  (cleavir-env:add-lexical-variable
                   new-env raw-variable var-ast)))))
    (let ((type (declared-type declarations)))
      (unless (equal type '(and))
        (setf new-env
              (cleavir-env:add-variable-type new-env raw-variable type))))
    (when (member 'ignore raw-declarations :test #'eq :key #'car)
      (setf new-env
            (cleavir-env:add-variable-ignore new-env raw-variable 'ignore)))
    (when (member 'ignorable raw-declarations :test #'eq :key #'car)
      (setf new-env
            (cleavir-env:add-variable-ignore new-env raw-variable 'ignorable)))
    (when (member 'dynamic-extent raw-declarations :test #'eq :key #'car)
      (setf new-env
            (cleavir-env:add-variable-dynamic-extent new-env raw-variable)))
    new-env))

;;; The only purpose of this function is to call the function
;;; AUGMENT-ENVIRONMENT-WITH-VARIABLE twice, once for the parameter
;;; variable and once for its associated supplied-p parameter, except
;;; that it also tests whether the supplied-p parameter is NIL,
;;; indicating that no supplied-p parameter was given.  This function
;;; returns the augmented environment.
(defun augment-environment-with-parameter (var-cst supplied-p-cst dspecs lexical-environment)
  (let ((new-env (augment-environment-with-variable
                  var-cst dspecs lexical-environment lexical-environment)))
    (if (null supplied-p-cst)
        new-env
        (augment-environment-with-variable
         supplied-p-cst dspecs new-env new-env))))

(defun augment-environment-with-local-function-name (name-cst lexical-environment)
  (let* ((name (cst:raw name-cst))
         (var-ast (make-instance 'cleavir-ast:lexical-ast :name name)))
    (cleavir-env:add-local-function lexical-environment name var-ast)))
