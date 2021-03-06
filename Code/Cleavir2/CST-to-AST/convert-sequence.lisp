(cl:in-package #:cleavir-cst-to-ast)

;;; Utility function for converting a sequence of CSTs, represented
;;; as a chain of CONS-CSTs terminated by a NULL-CST.
(defun convert-sequence (client
                         sequence-cst
                         lexical-environment
                         dynamic-environment-ast)
  (loop for cst = sequence-cst then (cst:rest cst)
        until (cst:null cst)
	collect (convert client
                         (cst:first cst)
                         lexical-environment
                         dynamic-environment-ast)))
