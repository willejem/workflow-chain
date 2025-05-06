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
;; ==========================================
;; WORKFLOW ITEM RETRIEVAL FUNCTIONS
;; ==========================================
;; Read-only function to access comprehensive workflow item details
(define-read-only (retrieve-workflow-details (user-address principal))
    (match (map-get? workflow-registry user-address)
        record (ok {
            item-description: (get item-description record),
            completion-status: (get completion-status record)
        })
        RECORD_NOT_FOUND
    )
)

;; Targeted function to quickly check completion status only
(define-read-only (verify-completion-status (user-address principal))
    (match (map-get? workflow-registry user-address)
        record (ok (get completion-status record))
        RECORD_NOT_FOUND
    )
)


;; ==========================================
;; STANDARD RESPONSE STATUS DEFINITIONS
;; ==========================================

(define-constant RECORD_NOT_FOUND (err u404))
(define-constant DUPLICATE_RECORD_ERROR (err u409))
(define-constant INVALID_INPUT_DATA (err u400))

;; ==========================================
;; WORKFLOW MANAGEMENT CORE FUNCTIONS
;; ==========================================
;; Public function for creation of new workflow items
(define-public (register-workflow-item 
    (item-description (string-ascii 100)))
    (let
        (
            (user-address tx-sender)
            (existing-record (map-get? workflow-registry user-address))
        )
        ;; Verify no existing registration exists for this address
        (if (is-none existing-record)
            ;; Validation to ensure input has meaningful content
            (if (is-eq item-description "")
                (err INVALID_INPUT_DATA)
                (begin
                    ;; Store the new workflow item with default completion status
                    (map-set workflow-registry user-address
                        {
                            item-description: item-description,
                            completion-status: false
                        }
                    )
                    (ok "Workflow item successfully registered.")
                )
            )
            (err DUPLICATE_RECORD_ERROR)
        )
    )
)


;; ==========================================
;; WORKFLOW ITEM MODIFICATION FUNCTIONS
;; ==========================================
;; Public function allowing users to update their existing workflow item
(define-public (modify-workflow-item
    (item-description (string-ascii 100))
    (completion-status bool))
    (let
        (
            (user-address tx-sender)
            (existing-record (map-get? workflow-registry user-address))
        )
        ;; First check if the record exists
        (if (is-some existing-record)
            ;; Validate input description isn't empty
            (if (is-eq item-description "")
                (err INVALID_INPUT_DATA)
                ;; Secondary validation for completion status
                (if (or (is-eq completion-status true) (is-eq completion-status false))
                    (begin
                        ;; Update the workflow item with new information
                        (map-set workflow-registry user-address
                            {
                                item-description: item-description,
                                completion-status: completion-status
                            }
                        )
                        (ok "Workflow item successfully updated.")
                    )
                    (err INVALID_INPUT_DATA)
                )
            )
            (err RECORD_NOT_FOUND)
        )
    )
)

;; Public function for record verification without modification
;; Allows applications to check workflow item status without changing state
(define-public (validate-workflow-item)
    (let
        (
            (user-address tx-sender)
            (existing-record (map-get? workflow-registry user-address))
        )
        (if (is-some existing-record)
            (let
                (
                    (current-record (unwrap! existing-record RECORD_NOT_FOUND))
                    (description-content (get item-description current-record))
                    (status-indicator (get completion-status current-record))
                )
                (ok {
                    record-found: true,
                    description-length: (len description-content),
                    is-completed: status-indicator
                })
            )
            (ok {
                record-found: false,
                description-length: u0,
                is-completed: false
            })
        )
    )
)

;; Public function enabling users to remove their workflow item
(define-public (remove-workflow-item)
    (let
        (
            (user-address tx-sender)
            (existing-record (map-get? workflow-registry user-address))
        )
        ;; Verify the record exists before attempting deletion
        (if (is-some existing-record)
            (begin
                (map-delete workflow-registry user-address)
                (ok "Workflow item successfully removed from registry.")
            )
            (err RECORD_NOT_FOUND)
        )
    )
)

;; ==========================================
;; COLLABORATION AND DELEGATION CAPABILITIES
;; ==========================================
;; Public function enabling workflow item assignment to other users
;; Allows authorized users to create workflow items for collaborators
(define-public (assign-workflow-item
    (recipient-address principal)
    (item-description (string-ascii 100)))
    (let
        (
            (existing-record (map-get? workflow-registry recipient-address))
        )
        ;; Verify target doesn't already have an assigned workflow item
        (if (is-none existing-record)
            ;; Validate input description isn't empty
            (if (is-eq item-description "")
                (err INVALID_INPUT_DATA)
                (begin
                    ;; Create the workflow item for the target user with default completion status
                    (map-set workflow-registry recipient-address
                        {
                            item-description: item-description,
                            completion-status: false
                        }
                    )
                    (ok "Workflow item successfully assigned to recipient.")
                )
            )
            (err DUPLICATE_RECORD_ERROR)
        )
    )
)

;; ==========================================
;; WORKFLOW ENHANCEMENT FUNCTIONS
;; ==========================================
;; Public function to establish workflow timeframe constraints
;; Sets a specific blockchain height target for completion
(define-public (configure-workflow-deadline (block-duration uint))
    (let
        (
            (user-address tx-sender)
            (existing-record (map-get? workflow-registry user-address))
            (target-completion-height (+ block-height block-duration))
        )
        ;; Verify the workflow item exists
        (if (is-some existing-record)
            ;; Validate the timeframe is in the future
            (if (> block-duration u0)
                (begin
                    ;; Store the deadline and initialize notification status
                    (map-set workflow-timeframe user-address
                        {
                            deadline-block: target-completion-height,
                            alert-triggered: false
                        }
                    )
                    (ok "Workflow deadline successfully configured.")
                )
                (err INVALID_INPUT_DATA)
            )
            (err RECORD_NOT_FOUND)
        )
    )
)

;; Public function to classify workflow item priority
;; Supports three-tier priority system (1=low, 2=medium, 3=high)
(define-public (assign-workflow-priority (priority-rating uint))
    (let
        (
            (user-address tx-sender)
            (existing-record (map-get? workflow-registry user-address))
        )
        ;; Verify the workflow item exists
        (if (is-some existing-record)
            ;; Validate priority is within accepted range (1-3)
            (if (and (>= priority-rating u1) (<= priority-rating u3))
                (begin
                    ;; Store the priority rating
                    (map-set workflow-priority user-address
                        {
                            priority-level: priority-rating
                        }
                    )
                    (ok "Workflow priority level successfully assigned.")
                )
                (err INVALID_INPUT_DATA)
            )
            (err RECORD_NOT_FOUND)
        )
    )
)

