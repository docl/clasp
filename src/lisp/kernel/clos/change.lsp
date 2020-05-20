;;;;  -*- Mode: Lisp; Syntax: Common-Lisp; Package: CLOS -*-
;;;;
;;;;  Copyright (c) 1992, Giuseppe Attardi.
;;;;  Copyright (c) 2001, Juan Jose Garcia Ripoll.
;;;;
;;;;    This program is free software; you can redistribute it and/or
;;;;    modify it under the terms of the GNU Library General Public
;;;;    License as published by the Free Software Foundation; either
;;;;    version 2 of the License, or (at your option) any later version.
;;;;
;;;;    See file '../Copyright' for full details.

(in-package "CLOS")

;;; ----------------------------------------------------------------------
;;; INSTANCE UPDATE PROTOCOL
;;;
;;;
;;; PART 1: CHANGING THE CLASS OF AN INSTANCE
;;;
;;; The method CHANGE-CLASS performs most of the work.
;;;
;;;	a) The structure of the instance is changed to match the new
;;;	   number of local slots.
;;;	b) The new local slots are filled with the value of the old
;;;	   slots. Only the name is used, so that a new local slot may
;;;	   get the value of old slots that were eithe local or shared.
;;;	c) Finally, UPDATE-INSTANCE-FOR-DIFFERENT-CLASS is invoked
;;;	   with a copy of the instance as it looked before the change,
;;;	   the changed instance and enough information to perform any
;;;	   extra processing.
;;;

(defmethod update-instance-for-different-class
    ((old-data standard-object) (new-data standard-object) &rest initargs)
  (declare (dynamic-extent initargs))
  (let ((added-slots
          (loop with old-slotds = (si:instance-sig old-data)
                for new-slotd in (si:instance-sig new-data)
                for new-slotd-name = (slot-definition-name new-slotd)
                when (and (eq (slot-definition-allocation new-slotd)
                              :instance)
                          (not (member new-slotd-name old-slotds
                                       :key #'slot-definition-name
                                       :test #'eq)))
                  collect new-slotd-name)))
    (when initargs
      (check-initargs-uncached
       (class-of new-data) initargs
       (list (list #'update-instance-for-different-class
                   (list old-data new-data))
             (list #'shared-initialize (list new-data added-slots)))))
    (apply #'shared-initialize new-data added-slots initargs)))

(defmethod change-class ((instance standard-object) (new-class std-class)
			 core:&va-rest initargs)
  (let ((old-instance (si:copy-instance instance))
        (instance (core:reallocate-instance instance new-class (class-size new-class))))
    ;; "The values of local slots specified by both the class Cto and
    ;; Cfrom are retained.  If such a local slot was unbound, it remains
    ;; unbound."
    ;; "The values of slots specified as shared in the class Cfrom and
    ;; as local in the class Cto are retained."
    (let* ((new-local-slotds (class-slots (class-of instance))))
      (dolist (new-slot new-local-slotds)
	;; CHANGE-CLASS can only operate on the value of local slots.
	(when (eq (slot-definition-allocation new-slot) :INSTANCE)
	  (let ((name (slot-definition-name new-slot)))
	    (if (and (slot-exists-p old-instance name)
		     (slot-boundp old-instance name))
		(setf (slot-value instance name) (slot-value old-instance name))
		(slot-makunbound instance name))))))
    (apply #'update-instance-for-different-class old-instance instance
	   initargs)
    instance))

;;;
;;; PART 2: UPDATING AN INSTANCE THAT BECAME OBSOLETE
;;;
;;; Each instance has a hidden field (readable with SI:INSTANCE-SIG), which
;;; contains the list of slots of its class. This field must be updated every
;;; time the class is initialized or reinitialized. Generally
;;;	(EQ (SI:INSTANCE-SIG x) (CLASS-SLOTS (CLASS-OF x)))
;;; returns NIL whenever the instance x is obsolete.
;;;
;;; There are two circumstances under which a instance may become obsolete:
;;; either the class has been modified using REDEFINE-INSTANCE (and thus the
;;; list of slots changed), or MAKE-INSTANCES-OBSOLETE has been used.
;;;
;;; The function UPDATE-INSTANCE (hidden to the user) does the job of
;;; updating an instance that has become obsolete.
;;;
;;;	a) A copy of the instance is saved to check the old values.
;;;	b) The structure of the instance is changed to match the new
;;;	   number of local slots.
;;;	c) The new local slots are filled with the value of the old
;;;	   local slots.
;;;	d) Finally, UPDATE-INSTANCE-FOR-REDEFINED-CLASS is invoked
;;;	   with enough information to perform any extra initialization,
;;;	   for instance of new slots.
;;;
;;; UPDATE-INSTANCE is invoked whenever a generic function dispatch misses.
;;;

(defmethod update-instance-for-redefined-class
    ((instance standard-object) added-slots discarded-slots property-list
     &rest initargs)
  (declare (dynamic-extent initargs))
  (check-initargs-uncached
   (class-of instance) initargs
   (list (list #'update-instance-for-redefined-class
               (list instance added-slots discarded-slots property-list))
         (list #'shared-initialize (list instance added-slots))))
  (apply #'shared-initialize instance added-slots initargs))

(defun update-instance (instance)
  (let* ((class (class-of instance))
	 (old-slotds (si:instance-sig instance))
	 (new-slotds (class-slots class))
	 (old-instance (si::copy-instance instance))
	 (discarded-slots '())
	 (added-slots '())
	 (property-list '()))
    (setf instance (core:reallocate-instance instance class (class-size class)))
    (let* ((new-i 0)
           (old-local-slotds (remove :instance old-slotds :test-not #'eq
                                     :key #'slot-definition-allocation))
           (new-local-slotds (remove :instance new-slotds :test-not #'eq
                                     :key #'slot-definition-allocation)))
      (declare (fixnum new-i))
      (setq discarded-slots
            (set-difference (mapcar #'slot-definition-name old-local-slotds)
                            (mapcar #'slot-definition-name new-local-slotds)))
      (dolist (slot-name discarded-slots)
        (let* ((ndx (position slot-name old-local-slotds :key #'slot-definition-name)))
          (push (cons slot-name (si::instance-ref old-instance ndx))
                property-list)))
      (dolist (new-slot new-local-slotds)
        (let* ((name (slot-definition-name new-slot))
               (old-i (position name old-local-slotds :key #'slot-definition-name)))
          (if old-i
              (si::instance-set instance new-i
                                (si::instance-ref old-instance old-i))
              (push name added-slots))
          (incf new-i))))
    (update-instance-for-redefined-class instance added-slots
                                         discarded-slots property-list)))

;;; ----------------------------------------------------------------------
;;; CLASS REDEFINITION PROTOCOL

(defmethod reinitialize-instance :before ((class class) &rest initargs &key)
  (declare (ignore initargs))
  (let ((name (class-name class)))
    (when (member name '(CLASS BUILT-IN-CLASS) :test #'eq)
      (error "The kernel CLOS class ~S cannot be changed." name)))

  ;; remove previous defined accessor methods
  (when (class-finalized-p class)
    (remove-optional-slot-accessors class)))

(defun slots-unchanged-p (old-slots new-slots)
  ;; M-I-O is called "[when] the set of local slots accessible in an instance has changed
  ;; or the order of slots in storage has changed", where "local" means accessible only
  ;; in the instance it's allocated in, which we take as meaning :allocation :instance.
  ;; However, because we're pretty aggressive with slot accessors, I think we need to be
  ;; conscientious of class slots as well. Here we just deny identity if there are any
  ;; class slots; better safe than sorry, but maybe could be improved. With custom
  ;; allocations, who knows. We could define a slot-equivalent-p generic-function.
  ;; NOTE/TODO?: We kind of don't actually care about the order of slots IN THE CLASS,
  ;; just in the instance. So we could go through and do a real set comparison. But this
  ;; is enough to cover an identical defclass being executed.
  (and (= (length old-slots) (length new-slots))
       (every (lambda (slot1 slot2)
                (and
                 (eq (slot-definition-name slot1) (slot-definition-name slot2))
                 (eq (slot-definition-allocation slot1) :instance)
                 (eq (slot-definition-allocation slot1) (slot-definition-allocation slot2))
                 (= (slot-definition-location slot1) (slot-definition-location slot2))))
              old-slots new-slots)))

(defmethod reinitialize-instance :after ((class class) &rest initargs
                                         &key (direct-superclasses () direct-superclasses-p)
                                           (direct-slots nil direct-slots-p))
  (declare (dynamic-extent initargs))
  ;; the list of direct slots is converted to direct-slot-definitions
  (when direct-slots-p
    (setf (%class-direct-slots class)
	  (loop for s in direct-slots
		collect (canonical-slot-to-direct-slot class s))))

  ;; set up inheritance checking that it makes sense
  (when direct-superclasses-p
    (setf direct-superclasses 
          (check-direct-superclasses class direct-superclasses))
    (dolist (l (class-direct-superclasses class))
      (unless (member l direct-superclasses)
        (remove-direct-subclass l class)))
    (dolist (l (setf (%class-direct-superclasses class)
		     direct-superclasses))
      (add-direct-subclass l class)))

  ;; if there are no forward references, we can just finalize the class here.
  ;; We keep a list of the old slots to compare with the new. If there's been
  ;; no substantial change (meaning we have slots with the same names and
  ;; allocations in the same order), we skip MAKE-INSTANCES-OBSOLETE.
  ;; This is explicitly allowed (see CLHS M-I-O). It reduces needless
  ;; compilation in fastgf dispatch, and is actually required to support
  ;; evaluating defstruct forms with no :type multiple times.
  (let* (;; Grab the slots before finalization (may) change them.
         ;; Of course there have to BE old slots - with e.g. forward references
         ;; this may not be so.
         (old-slots-p (slot-boundp class 'slots))
         (old-slots (when old-slots-p (class-slots class))))
    (setf (%class-finalized-p class) nil)
    (finalize-unless-forward class)

    (unless (and old-slots-p
                 (slot-boundp class 'slots) ; new-slots-p
                 (slots-unchanged-p old-slots (class-slots class)))
      (make-instances-obsolete class)))

  (update-dependents class initargs))

(defun remove-optional-slot-accessors (class)
  (declare (class class)
	   (optimize (safety 0)))
  (let ((class-name (class-name class)))
    (dolist (slotd (class-slots class))
      ;; remove previously defined reader methods
      (dolist (reader (slot-definition-readers slotd))
	(let* ((gf-object (fdefinition reader))
	       found)
          (when gf-object ; fmakunbound or otherwise could have removed
            ;; primary method
            (when (setq found (find-method gf-object nil (list class-name) nil))
              (remove-method gf-object found))
            ;; before method
            ;; not sure whether removing these is a good idea. Couldn't a user have defined them?
            ;; And e.g. have a subclass that retains the accessor.
            (when (setq found (find-method gf-object ':before (list class-name) nil))
              (remove-method gf-object found))
            ;; after method
            (when (setq found (find-method gf-object ':after (list class-name) nil))
              (remove-method gf-object found))
            ;; This is unnecessary but kind of nice?
            ;; Other implementations have different behavior.
            ;; The user could have defined the generic function specially, so whether this is
            ;; the right thing to do is ambiguous.
            (when (null (generic-function-methods gf-object))
              (fmakunbound reader)))))
      ;; remove previously defined writer methods
      (dolist (writer (slot-definition-writers slotd))
	(let* ((gf-object (fdefinition writer))
	       found)
          (when gf-object
            ;; primary method
            (when (setq found (find-method gf-object nil (list 'T class-name) nil))
              (remove-method gf-object found))
            ;; before method
            (when (setq found (find-method gf-object ':before (list 'T class-name) nil))
              (remove-method gf-object found))
            ;; after method
            (when (setq found (find-method gf-object ':after (list 'T class-name) nil))
              (remove-method gf-object found))
            (when (null (generic-function-methods gf-object))
              (fmakunbound writer))))))))

;;; ----------------------------------------------------------------------
;;; BANS
;;; Some change operations AMOP expressly prohibits.
;;; Specifically, reinitialize-instance HAS to signal an error, but for the
;;; others the behavior doesn't seem to be defined: it just says portable
;;; programs can't do this.
;;; Relatedly, we don't signal an error if a metaobject class is redefined,
;;; although AMOP says portable programs can't do so. We may be able to
;;; support that kind of redefinition.
;;; We also don't actually signal an error if an object is change-class'd
;;; into a metaobject, but that's more because we can't check with just
;;; discrimination as below, and we'd have to be more manual, and for
;;; almost every call to change-class.

(defmethod reinitialize-instance ((instance method) &rest initargs)
  (declare (ignore initargs))
  (error "Cannot reinitialize method metaobject ~a per AMOP Ch. 6"
         instance))

(defmethod reinitialize-instance ((instance slot-definition) &rest initargs)
  (declare (ignore initargs))
  (error "Cannot reinitialize slot definition metaobject ~a per AMOP Ch. 6"
         instance))

(defmethod change-class ((instance class) new-class &rest initargs)
  (declare (ignore new-class initargs))
  (if (forward-referenced-class-p instance)
      (call-next-method)
      (error "The metaclass of a class metaobject ~a cannot be changed per AMOP Ch. 6"
             instance)))

(defmethod change-class ((instance generic-function) new-class &rest initargs)
  (declare (ignore new-class initargs))
  (error "The metaclass of a generic function metaobject ~a cannot be changed per AMOP Ch. 6"
         instance))

(defmethod change-class ((instance method) new-class &rest initargs)
  (declare (ignore new-class initargs))
  (error "The metaclass of a method metaobject ~a cannot be changed per AMOP Ch. 6"
         instance))

(defmethod change-class ((instance slot-definition) new-class &rest initargs)
  (declare (ignore new-class initargs))
  (error "The metaclass of a slot definition metaobject ~a cannot be changed per AMOP Ch. 6"
         instance))
