(defpackage :common-lisp-user)
(#j:console:log "Loading jscl-react.lisp...")

(defun get-element-by-id (id) (#j:document:getElementById id))
(defun react-render (&rest stuff) (apply #j:ReactDOM:render stuff))
(defun react-create-element (&rest args) (apply #j:React:createElement args))
(defun alert (&rest args) (apply #j:window:alert args))
(defun object (&rest l) (apply #j:window:lispToJs l)) ; TODO reader macro
(defun getobj (key obj) (#j:window:getObj key obj))
(defun setobj (key val obj) (#j:window:setObj key val obj))
(defun to-list (vec) (loop for item across vec collect item))
(defun vec-push (vec new-item) (apply #'vector (cons (to-list vec) new-item)))
(defun make-component (&rest args) (apply #j:window:makeComponent args))
(defun assoc-val (key obj) (cdr (assoc key obj)))

(defmacro render (&body arguments)
  (let ((render-help
          (lambda (l rh)
            (if (symbolp l) l
            `(react-create-element
              ,(car l)
              ,(cadr l)
              ,@(loop for child in (cddr l)
                      collect (cond
                                ((stringp child) child)
                                ((symbolp child) child)
                                ((listp child) 
                                 (let ((c (car child)))
                                   (cond
                                     ((stringp c) (funcall rh child rh))
                                     ((listp c)
                                      (if (eq (car c) 'jscl::oget)
                                        child
                                        (funcall rh child rh)))
                                     (t child))))
                                (t (funcall rh child rh)))))))))
    (funcall render-help arguments render-help)))

(defmacro defcomponent ((name initial-state) args &body body)
  (let ((s (gensym)))
    `(let ((,s (make-component ,initial-state (lambda ,args ,@body))))
       (defun ,name () ,s))))

(defun mount (root-id el)
  (let ((domContainer (get-element-by-id root-id)))
    (react-render el domContainer)))

(defmacro obj-destructure (obj syms &body body)
  (let ((sym (gensym))
        (remove-bars (lambda (s)
                       (if (char= (char s 0) #\|)
                         (subseq s 1 (1- (length s)))
                         s))))
    `(let ((,sym ,obj))
       (destructuring-bind
          ,(loop for s in syms
                 collect (intern (string-upcase (funcall remove-bars (princ-to-string s)))))
          (list ,@(loop for s in syms
                        collect `(getobj ,(if (stringp s)
                                            s
                                            (funcall remove-bars (princ-to-string s)))
                                         ,sym)))
          ,@body))))
