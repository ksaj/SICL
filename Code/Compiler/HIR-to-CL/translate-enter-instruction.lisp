(cl:in-package #:sicl-hir-to-cl)

(defun make-let-bindings (lambda-list)
  (loop for item in lambda-list
        unless (member item lambda-list-keywords)
          append (cond ((atom item)
                        (list (cleavir-ir:name item)))
                       ((= (length item) 2)
                        (list (cleavir-ir:name (first item))
                              (cleavir-ir:name (second item))))
                       (t
                        (list (cleavir-ir:name (second item))
                              (cleavir-ir:name (third item)))))))

;;; Return 4 values:
;;;
;;;   * A list of reuqired parameters, each one represented as a
;;;     single lexical location
;;;
;;;   * A list of &OPTIONAL parameters, each one represented as a
;;;     list of two lexical locations, one for the parameter and
;;;     one for the supplied-p parameter.
;;;
;;;   * A &REST parameter represented as a single lexical location,
;;;     or NIL of there is no &REST parameter.
;;;
;;;   * A list of &KEY parameters, each one represented as a list
;;;     of three elements, a symbol and two lexical locations.
(defun split-lambda-list (lambda-list)
  (let ((pos (position-if (lambda (x) (member x lambda-list-keywords))
                          lambda-list)))
    (when (null pos)
      (return-from split-lambda-list
        (values lambda-list '() nil '())))
    (let ((required-parameters (subseq lambda-list 0 pos))
          (remaining (subseq lambda-list pos))
          (optional-parameters '())
          (rest-parameter nil)
          (key-parameters '()))
      (loop for item in remaining
            do (cond ((member item lambda-list-keywords)
                      nil)
                     ((atom item)
                      (setq rest-parameter item))
                     ((= (length item) 2)
                      (push item optional-parameters))
                     (t
                      (push item key-parameters))))
      (values required-parameters
              (reverse optional-parameters)
              rest-parameter
              (reverse key-parameters)))))

(defun translate-enter-instruction (enter-instruction context)
  (let* ((lambda-list (cleavir-ir:lambda-list enter-instruction))
         (successor (first (cleavir-ir:successors enter-instruction)))
         (lambda-list-variable (gensym))
         (static-environment-variable (gensym))
         (dynamic-environment-variable (gensym))
         (remaining-variable (gensym)))
    (multiple-value-bind (required-parameters
                          optional-parameters
                          rest-parameter
                          key-parameters)
        (split-lambda-list lambda-list)
      `(lambda (,lambda-list-variable
                ,static-environment-variable
                ,dynamic-environment-variable)
         (block ,(block-name context)
           (let (,@(make-let-bindings lambda-list)
                 (,remaining-variable ,lambda-list-variable))
             ;; Check that enough arguments were passed.
             ,@(if (null required-parameters)
                   '()
                   `((when (< (length ,lambda-list-variable)
                              ,(length required-parameters))
                       (error "Not enough arguments"))))
             ;; Check that not too many arguments were passed
             ,@(if (and (null rest-parameter) (null key-parameters))
                   '()
                   `((when (> (length ,lambda-list-variable)
                              ,(+ (length required-parameters)
                                  (length optional-parameters)))
                       (error "Too many arguments"))))
             ,@(loop for required-parameter in required-parameters
                     collect `(setq ,(cleavir-ir:name required-parameter)
                                    (pop ,remaining-variable)))
             ,@(loop for optional-parameter in optional-parameters
                     collect `(setq ,(cleavir-ir:name (first optional-parameter))
                                    (pop ,remaining-variable))
                     collect `(setq ,(cleavir-ir:name (first optional-parameter))
                                    t))
             ,@(if (null rest-parameter)
                   '()
                   `((setq ,(cleavir-ir:name rest-parameter) ,remaining-variable)))
             ,@(loop for key-parameter in key-parameters
                     collect `(multiple-value-bind (indicator value tail)
                                  (get-properties ,remaining-variable
                                                  '(,(first key-parameter)))
                                (unless (null tail)
                                  (setf ,(cleavir-ir:name (second key-parameter))
                                        value)
                                  (setf ,(cleavir-ir:name (third key-parameter))
                                        t))))
             (tagbody ,@(translate successor context))))))))
