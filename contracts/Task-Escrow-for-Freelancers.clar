(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_TASK_NOT_FOUND (err u101))
(define-constant ERR_TASK_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_TASK_NOT_ACTIVE (err u104))
(define-constant ERR_TASK_ALREADY_COMPLETED (err u105))
(define-constant ERR_INSUFFICIENT_FUNDS (err u106))
(define-constant ERR_INVALID_MILESTONE (err u107))
(define-constant ERR_MILESTONE_ALREADY_RELEASED (err u108))
(define-constant ERR_DISPUTE_ALREADY_EXISTS (err u109))
(define-constant ERR_NO_DISPUTE (err u110))
(define-constant ERR_DISPUTE_RESOLVED (err u111))
(define-constant ERR_INVALID_DISPUTE_DECISION (err u112))

(define-constant TASK_STATUS_ACTIVE u1)
(define-constant TASK_STATUS_COMPLETED u2)
(define-constant TASK_STATUS_DISPUTED u3)
(define-constant TASK_STATUS_CANCELLED u4)

(define-constant DISPUTE_STATUS_OPEN u1)
(define-constant DISPUTE_STATUS_RESOLVED u2)

(define-data-var next-task-id uint u1)
(define-data-var next-dispute-id uint u1)
(define-data-var contract-owner principal tx-sender)
(define-data-var platform-fee-percent uint u250)

(define-map tasks
  uint
  {
    client: principal,
    freelancer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    total-amount: uint,
    milestones: uint,
    completed-milestones: uint,
    status: uint,
    created-at: uint,
    deadline: uint
  }
)

(define-map task-funds
  uint
  {
    escrow-amount: uint,
    released-amount: uint,
    platform-fee: uint
  }
)

(define-map milestone-funds
  { task-id: uint, milestone-id: uint }
  {
    amount: uint,
    released: bool,
    approved-by-client: bool
  }
)

(define-map disputes
  uint
  {
    task-id: uint,
    complainant: principal,
    reason: (string-ascii 500),
    status: uint,
    created-at: uint,
    resolved-at: (optional uint),
    decision: (optional bool)
  }
)

(define-map user-ratings
  principal
  {
    total-score: uint,
    review-count: uint
  }
)

(define-private (get-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-percent)) u10000)
)

(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

(define-private (is-task-participant (task-id uint))
  (match (map-get? tasks task-id)
    task (or (is-eq tx-sender (get client task)) (is-eq tx-sender (get freelancer task)))
    false
  )
)

(define-private (calculate-milestone-amount (total-amount uint) (milestones uint) (milestone-id uint))
  (if (is-eq milestones u1)
    total-amount
    (/ total-amount milestones)
  )
)

(define-public (create-task 
  (freelancer principal) 
  (title (string-ascii 100)) 
  (description (string-ascii 500)) 
  (amount uint) 
  (milestones uint) 
  (deadline uint))
  (let 
    (
      (task-id (var-get next-task-id))
      (platform-fee (get-platform-fee amount))
      (total-required (+ amount platform-fee))
    )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> milestones u0) ERR_INVALID_AMOUNT)
    (asserts! (> deadline stacks-block-height) ERR_INVALID_AMOUNT)
    (asserts! (>= (stx-get-balance tx-sender) total-required) ERR_INSUFFICIENT_FUNDS)
    
    (try! (stx-transfer? total-required tx-sender (as-contract tx-sender)))
    
    (map-set tasks task-id
      {
        client: tx-sender,
        freelancer: freelancer,
        title: title,
        description: description,
        total-amount: amount,
        milestones: milestones,
        completed-milestones: u0,
        status: TASK_STATUS_ACTIVE,
        created-at: stacks-block-height,
        deadline: deadline
      }
    )
    
    (map-set task-funds task-id
      {
        escrow-amount: amount,
        released-amount: u0,
        platform-fee: platform-fee
      }
    )
    
    (let ((milestone-loop-result 
      (fold create-milestone-entry 
        (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) 
        { task-id: task-id, milestones: milestones, amount: amount, counter: u0 })))
      
      (var-set next-task-id (+ task-id u1))
      (ok task-id)
    )
  )
)

(define-private (create-milestone-entry (milestone-num uint) (data { task-id: uint, milestones: uint, amount: uint, counter: uint }))
  (let ((current-counter (+ (get counter data) u1)))
    (if (<= current-counter (get milestones data))
      (begin
        (map-set milestone-funds 
          { task-id: (get task-id data), milestone-id: current-counter }
          {
            amount: (calculate-milestone-amount (get amount data) (get milestones data) current-counter),
            released: false,
            approved-by-client: false
          }
        )
        (merge data { counter: current-counter })
      )
      data
    )
  )
)

(define-public (submit-milestone (task-id uint) (milestone-id uint))
  (let ((task (unwrap! (map-get? tasks task-id) ERR_TASK_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get freelancer task)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status task) TASK_STATUS_ACTIVE) ERR_TASK_NOT_ACTIVE)
    (asserts! (<= milestone-id (get milestones task)) ERR_INVALID_MILESTONE)
    
    (ok true)
  )
)

(define-public (approve-milestone (task-id uint) (milestone-id uint))
  (let 
    (
      (task (unwrap! (map-get? tasks task-id) ERR_TASK_NOT_FOUND))
      (milestone (unwrap! (map-get? milestone-funds { task-id: task-id, milestone-id: milestone-id }) ERR_INVALID_MILESTONE))
    )
    (asserts! (is-eq tx-sender (get client task)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status task) TASK_STATUS_ACTIVE) ERR_TASK_NOT_ACTIVE)
    (asserts! (not (get released milestone)) ERR_MILESTONE_ALREADY_RELEASED)
    
    (map-set milestone-funds 
      { task-id: task-id, milestone-id: milestone-id }
      (merge milestone { approved-by-client: true })
    )
    
    (ok true)
  )
)

(define-public (release-milestone-funds (task-id uint) (milestone-id uint))
  (let 
    (
      (task (unwrap! (map-get? tasks task-id) ERR_TASK_NOT_FOUND))
      (milestone (unwrap! (map-get? milestone-funds { task-id: task-id, milestone-id: milestone-id }) ERR_INVALID_MILESTONE))
      (task-fund (unwrap! (map-get? task-funds task-id) ERR_TASK_NOT_FOUND))
    )
    (asserts! (get approved-by-client milestone) ERR_NOT_AUTHORIZED)
    (asserts! (not (get released milestone)) ERR_MILESTONE_ALREADY_RELEASED)
    (asserts! (is-eq (get status task) TASK_STATUS_ACTIVE) ERR_TASK_NOT_ACTIVE)
    
    (try! (as-contract (stx-transfer? (get amount milestone) tx-sender (get freelancer task))))
    
    (map-set milestone-funds 
      { task-id: task-id, milestone-id: milestone-id }
      (merge milestone { released: true })
    )
    
    (map-set task-funds task-id
      (merge task-fund { released-amount: (+ (get released-amount task-fund) (get amount milestone)) })
    )
    
    (let ((new-completed-milestones (+ (get completed-milestones task) u1)))
      (map-set tasks task-id
        (merge task { completed-milestones: new-completed-milestones })
      )
      
      (if (is-eq new-completed-milestones (get milestones task))
        (begin
          (map-set tasks task-id (merge task { status: TASK_STATUS_COMPLETED }))
          (try! (as-contract (stx-transfer? (get platform-fee task-fund) tx-sender (var-get contract-owner))))
          (ok "task-completed")
        )
        (ok "milestone-released")
      )
    )
  )
)

(define-public (create-dispute (task-id uint) (reason (string-ascii 500)))
  (let 
    (
      (task (unwrap! (map-get? tasks task-id) ERR_TASK_NOT_FOUND))
      (dispute-id (var-get next-dispute-id))
    )
    (asserts! (is-task-participant task-id) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status task) TASK_STATUS_ACTIVE) ERR_TASK_NOT_ACTIVE)
    
    (map-set disputes dispute-id
      {
        task-id: task-id,
        complainant: tx-sender,
        reason: reason,
        status: DISPUTE_STATUS_OPEN,
        created-at: stacks-block-height,
        resolved-at: none,
        decision: none
      }
    )
    
    (map-set tasks task-id
      (merge task { status: TASK_STATUS_DISPUTED })
    )
    
    (var-set next-dispute-id (+ dispute-id u1))
    (ok dispute-id)
  )
)

(define-public (resolve-dispute (dispute-id uint) (decision bool))
  (let 
    (
      (dispute (unwrap! (map-get? disputes dispute-id) ERR_NO_DISPUTE))
      (task-id (get task-id dispute))
      (task (unwrap! (map-get? tasks task-id) ERR_TASK_NOT_FOUND))
      (task-fund (unwrap! (map-get? task-funds task-id) ERR_TASK_NOT_FOUND))
    )
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status dispute) DISPUTE_STATUS_OPEN) ERR_DISPUTE_RESOLVED)
    
    (map-set disputes dispute-id
      (merge dispute 
        {
          status: DISPUTE_STATUS_RESOLVED,
          resolved-at: (some stacks-block-height),
          decision: (some decision)
        }
      )
    )
    
    (if decision
      (begin
        (try! (as-contract (stx-transfer? (get escrow-amount task-fund) tx-sender (get freelancer task))))
        (map-set tasks task-id (merge task { status: TASK_STATUS_COMPLETED }))
        (ok "dispute-resolved-freelancer-wins")
      )
      (begin
        (try! (as-contract (stx-transfer? (get escrow-amount task-fund) tx-sender (get client task))))
        (map-set tasks task-id (merge task { status: TASK_STATUS_CANCELLED }))
        (ok "dispute-resolved-client-wins")
      )
    )
  )
)

(define-public (cancel-task (task-id uint))
  (let 
    (
      (task (unwrap! (map-get? tasks task-id) ERR_TASK_NOT_FOUND))
      (task-fund (unwrap! (map-get? task-funds task-id) ERR_TASK_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get client task)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status task) TASK_STATUS_ACTIVE) ERR_TASK_NOT_ACTIVE)
    (asserts! (is-eq (get completed-milestones task) u0) ERR_NOT_AUTHORIZED)
    
    (try! (as-contract (stx-transfer? (+ (get escrow-amount task-fund) (get platform-fee task-fund)) tx-sender (get client task))))
    
    (map-set tasks task-id
      (merge task { status: TASK_STATUS_CANCELLED })
    )
    
    (ok true)
  )
)

(define-public (rate-user (user principal) (score uint))
  (let ((current-rating (default-to { total-score: u0, review-count: u0 } (map-get? user-ratings user))))
    (asserts! (<= score u5) ERR_INVALID_AMOUNT)
    (asserts! (>= score u1) ERR_INVALID_AMOUNT)
    
    (map-set user-ratings user
      {
        total-score: (+ (get total-score current-rating) score),
        review-count: (+ (get review-count current-rating) u1)
      }
    )
    (ok true)
  )
)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-fee u1000) ERR_INVALID_AMOUNT)
    (var-set platform-fee-percent new-fee)
    (ok true)
  )
)

(define-read-only (get-task (task-id uint))
  (map-get? tasks task-id)
)

(define-read-only (get-task-funds (task-id uint))
  (map-get? task-funds task-id)
)

(define-read-only (get-milestone (task-id uint) (milestone-id uint))
  (map-get? milestone-funds { task-id: task-id, milestone-id: milestone-id })
)

(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes dispute-id)
)

(define-read-only (get-user-rating (user principal))
  (match (map-get? user-ratings user)
    rating (some { 
      average-score: (if (> (get review-count rating) u0) 
                      (/ (get total-score rating) (get review-count rating)) 
                      u0),
      review-count: (get review-count rating)
    })
    none
  )
)

(define-read-only (get-platform-fee-percent)
  (var-get platform-fee-percent)
)

(define-read-only (get-next-task-id)
  (var-get next-task-id)
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)
