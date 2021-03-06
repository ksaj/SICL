(cl:in-package #:cleavir-cst-to-ast)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting a compound form when the head of a compound form is a
;;; CONS.  Then the head must be a lambda expression.  We replace a
;;; call such as ((lambda (params) . body) . args) by (flet ((temp
;;; (params) . body)) (temp . args))
;;;
;;; FIXME: do some more error checking.

(defmethod convert-lambda-call (client cst lexical-environment dynamic-environment-ast)
  (cst:db origin ((lambda-cst lambda-list-cst . body-cst) . args-cst) cst
    (assert (eql (cst:raw lambda-cst) 'cl:lambda) nil
            'lambda-call-first-symbol-not-lambda :expr (cst:raw lambda-cst))
    (make-instance 'cleavir-ast:call-ast
     :callee-ast (convert-code client lambda-list-cst body-cst lexical-environment dynamic-environment-ast)
     :argument-asts (convert-sequence client args-cst lexical-environment dynamic-environment-ast)
     :dynamic-environment-input-ast dynamic-environment-ast)))
