(cl:in-package #:cleavir-cst-to-ast)

(defmethod convert-variable (client cst lexical-environment dynamic-environment-ast)
  (let* ((symbol (cst:raw cst))
         (info (cleavir-env:variable-info lexical-environment symbol)))
    (loop while (null info)
	  do (restart-case (error 'cleavir-env:no-variable-info
				  :name symbol
				  :origin (cst:source cst))
	       (recover ()
		 :report (lambda (stream)
			   (format stream "Consider the variable as special."))
                 (setf info 
                       (make-instance 'cleavir-env:special-variable-info
                                      :name symbol)))
               ;; This is identical to RECOVER, but more specifically named.
	       (consider-special ()
		 :report (lambda (stream)
			   (format stream "Consider the variable as special."))
                 (setf info
                       (make-instance 'cleavir-env:special-variable-info
                         :name symbol)))
	       (substitute (new-symbol)
		 :report (lambda (stream)
			   (format stream "Substitute a different name."))
		 :interactive (lambda ()
				(format *query-io* "Enter new name: ")
				(list (read *query-io*)))
		 (setq info (cleavir-env:variable-info lexical-environment new-symbol)))))
    (convert-cst client cst info lexical-environment dynamic-environment-ast)))
