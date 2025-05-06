;; Assignment Blockchain Tracker
;; A blockchain-based solution for managing action items and assignments
;; This contract enables users to track, prioritize, and manage their workflow elements

;; ==========================================
;; DATA REPOSITORIES
;; ==========================================
;; Primary storage for workflow item details
;; Links blockchain identities to their specific workflow elements
(define-map workflow-registry
    principal
    {
        item-description: (string-ascii 100),
        completion-status: bool
    }
)

;; Storage for workflow item priority classifications
;; Enables organizing items by their relative importance
(define-map workflow-priority
    principal
    {
        priority-level: uint
    }
)

;; Storage for workflow item scheduling information
;; Tracks temporal constraints and notification preferences
(define-map workflow-timeframe
    principal
    {
        deadline-block: uint,
        alert-triggered: bool
    }
)