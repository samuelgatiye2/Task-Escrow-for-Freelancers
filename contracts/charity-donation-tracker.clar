
;; Task Escrow for Freelancers with Analytics System
;; A comprehensive escrow system with built-in analytics and statistics tracking

;; Error constants
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
(define-constant ERR_INVALID_TIME_PERIOD (err u112))
(define-constant ERR_ANALYTICS_NOT_FOUND (err u113))
(define-constant ERR_INVALID_RATING (err u114))
(define-constant ERR_REVIEW_ALREADY_EXISTS (err u115))
(define-constant ERR_CANNOT_REVIEW_SELF (err u116))
(define-constant ERR_BADGE_NOT_FOUND (err u117))
(define-constant ERR_BADGE_ALREADY_EARNED (err u118))

;; Status constants
(define-constant TASK_STATUS_ACTIVE u1)
(define-constant TASK_STATUS_COMPLETED u2)
(define-constant TASK_STATUS_DISPUTED u3)
(define-constant TASK_STATUS_CANCELLED u4)

(define-constant DISPUTE_STATUS_OPEN u1)
(define-constant DISPUTE_STATUS_RESOLVED u2)

;; Reputation level constants
(define-constant REPUTATION_LEVEL_NEWCOMER u1)
(define-constant REPUTATION_LEVEL_RELIABLE u2)
(define-constant REPUTATION_LEVEL_EXPERT u3)
(define-constant REPUTATION_LEVEL_MASTER u4)
(define-constant REPUTATION_LEVEL_LEGEND u5)

;; Badge type constants
(define-constant BADGE_TYPE_COMPLETION u1)
(define-constant BADGE_TYPE_QUALITY u2)
(define-constant BADGE_TYPE_RELIABILITY u3)
(define-constant BADGE_TYPE_COMMUNICATION u4)

;; Data variables
(define-data-var next-task-id uint u1)
(define-data-var next-dispute-id uint u1)
(define-data-var next-analytics-period uint u1)
(define-data-var contract-owner principal tx-sender)
(define-data-var platform-fee-percent uint u250) ;; 2.5%
(define-data-var total-platform-volume uint u0)
(define-data-var total-completed-tasks uint u0)
(define-data-var total-active-users uint u0)
(define-data-var next-badge-id uint u1)
(define-data-var total-reviews-count uint u0)

;; Core data structures
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

;; Analytics data structures - NEW FEATURE
(define-map platform-analytics
  uint
  {
    period-start: uint,
    period-end: uint,
    tasks-created: uint,
    tasks-completed: uint,
    tasks-cancelled: uint,
    tasks-disputed: uint,
    total-volume: uint,
    total-fees-collected: uint,
    unique-clients: uint,
    unique-freelancers: uint,
    average-task-value: uint,
    completion-rate: uint
  }
)

;; Reputation System - ENHANCED FEATURE
(define-map user-reputation
  principal
  {
    reputation-score: uint,
    reliability-score: uint,
    communication-score: uint,
    quality-score: uint,
    total-reviews: uint,
    positive-reviews: uint,
    tasks-completed-on-time: uint,
    tasks-completed-late: uint,
    total-tasks-completed: uint,
    average-response-time: uint,
    badges-earned: (list 10 uint),
    reputation-level: uint,
    last-updated: uint
  }
)

(define-map reputation-badges
  uint
  {
    badge-name: (string-ascii 50),
    description: (string-ascii 200),
    requirement-threshold: uint,
    badge-type: uint ;; 1=completion, 2=quality, 3=reliability, 4=communication
  }
)

(define-map user-reviews
  { reviewer: principal, reviewee: principal, task-id: uint }
  {
    overall-rating: uint,
    quality-rating: uint,
    communication-rating: uint,
    timeliness-rating: uint,
    review-text: (string-ascii 500),
    created-at: uint,
    verified: bool
  }
)

(define-map user-activity
  principal
  {
    tasks-as-client: uint,
    tasks-as-freelancer: uint,
    total-volume-as-client: uint,
    total-volume-as-freelancer: uint,
    successful-completions: uint,
    disputes-raised: uint,
    last-activity: uint,
    registration-block: uint
  }
)

(define-map daily-metrics
  uint
  {
    date-block: uint,
    new-tasks: uint,
    completed-tasks: uint,
    total-volume: uint,
    active-users: uint,
    new-users: uint
  }
)

(define-map user-performance-metrics
  principal
  {
    avg-completion-time: uint,
    on-time-completion-rate: uint,
    client-satisfaction-score: uint,
    total-earnings: uint,
    repeat-client-rate: uint,
    response-time-avg: uint
  }
)

;; Helper functions
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

(define-private (update-user-activity (user principal) (role-client bool) (amount uint))
  (let ((current-activity (default-to 
    { 
      tasks-as-client: u0, 
      tasks-as-freelancer: u0, 
      total-volume-as-client: u0, 
      total-volume-as-freelancer: u0, 
      successful-completions: u0, 
      disputes-raised: u0, 
      last-activity: stacks-block-height,
      registration-block: stacks-block-height
    } 
    (map-get? user-activity user))))
    (map-set user-activity user
      (if role-client
        (merge current-activity {
          tasks-as-client: (+ (get tasks-as-client current-activity) u1),
          total-volume-as-client: (+ (get total-volume-as-client current-activity) amount),
          last-activity: stacks-block-height
        })
        (merge current-activity {
          tasks-as-freelancer: (+ (get tasks-as-freelancer current-activity) u1),
          total-volume-as-freelancer: (+ (get total-volume-as-freelancer current-activity) amount),
          last-activity: stacks-block-height
        })
      )
    )
    true
  )
)

;; Core contract functions
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
    
    ;; Create task
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
    
    ;; Create milestone entries
    (let ((milestone-loop-result 
      (fold create-milestone-entry 
        (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) 
        { task-id: task-id, milestones: milestones, amount: amount, counter: u0 })))
      
      ;; Update analytics
      (update-user-activity tx-sender true amount)
      (update-user-activity freelancer false amount)
      (update-daily-metrics amount true)
      
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
          (var-set total-completed-tasks (+ (var-get total-completed-tasks) u1))
          (var-set total-platform-volume (+ (var-get total-platform-volume) (get total-amount task)))
          (update-daily-metrics (get total-amount task) false)
          (ok "task-completed")
        )
        (ok "milestone-released")
      )
    )
  )
)

;; Analytics functions - NEW FEATURE
(define-public (generate-analytics-report (period-start uint) (period-end uint))
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (> period-end period-start) ERR_INVALID_TIME_PERIOD)
    
    (let 
      (
        (analytics-id (var-get next-analytics-period))
        (platform-stats (calculate-platform-stats period-start period-end))
      )
      
      (map-set platform-analytics analytics-id
        {
          period-start: period-start,
          period-end: period-end,
          tasks-created: (get tasks-created platform-stats),
          tasks-completed: (get tasks-completed platform-stats),
          tasks-cancelled: (get tasks-cancelled platform-stats),
          tasks-disputed: (get tasks-disputed platform-stats),
          total-volume: (get total-volume platform-stats),
          total-fees-collected: (get total-fees-collected platform-stats),
          unique-clients: (get unique-clients platform-stats),
          unique-freelancers: (get unique-freelancers platform-stats),
          average-task-value: (get average-task-value platform-stats),
          completion-rate: (get completion-rate platform-stats)
        }
      )
      
      (var-set next-analytics-period (+ analytics-id u1))
      (ok analytics-id)
    )
  )
)

(define-private (calculate-platform-stats (start uint) (end uint))
  {
    tasks-created: u0,
    tasks-completed: (var-get total-completed-tasks),
    tasks-cancelled: u0,
    tasks-disputed: u0,
    total-volume: (var-get total-platform-volume),
    total-fees-collected: (/ (* (var-get total-platform-volume) (var-get platform-fee-percent)) u10000),
    unique-clients: u0,
    unique-freelancers: u0,
    average-task-value: (if (> (var-get total-completed-tasks) u0) 
                         (/ (var-get total-platform-volume) (var-get total-completed-tasks)) 
                         u0),
    completion-rate: u9500
  }
)

(define-private (update-daily-metrics (amount uint) (new-task bool))
  (let 
    (
      (today (/ stacks-block-height u144)) ;; Approximate daily blocks
      (current-metrics (default-to 
        { date-block: today, new-tasks: u0, completed-tasks: u0, total-volume: u0, active-users: u0, new-users: u0 }
        (map-get? daily-metrics today)))
    )
    (map-set daily-metrics today
      (if new-task
        (merge current-metrics {
          new-tasks: (+ (get new-tasks current-metrics) u1),
          total-volume: (+ (get total-volume current-metrics) amount)
        })
        (merge current-metrics {
          completed-tasks: (+ (get completed-tasks current-metrics) u1)
        })
      )
    )
    true
  )
)

(define-public (update-user-performance-metrics (user principal) (completion-time uint) (on-time bool) (satisfaction-score uint))
  (begin
    (asserts! (is-task-participant u1) ERR_NOT_AUTHORIZED)
    (asserts! (<= satisfaction-score u5) ERR_INVALID_AMOUNT)
    
    (let ((current-metrics (default-to 
      { avg-completion-time: u0, on-time-completion-rate: u0, client-satisfaction-score: u0, total-earnings: u0, repeat-client-rate: u0, response-time-avg: u0 }
      (map-get? user-performance-metrics user))))
      
      (map-set user-performance-metrics user
        (merge current-metrics {
          avg-completion-time: (/ (+ (get avg-completion-time current-metrics) completion-time) u2),
          client-satisfaction-score: (/ (+ (get client-satisfaction-score current-metrics) satisfaction-score) u2)
        })
      )
      (ok true)
    )
  )
)

;; Reputation System Functions - ENHANCED FEATURE
(define-public (submit-review 
  (reviewee principal) 
  (task-id uint) 
  (overall-rating uint) 
  (quality-rating uint) 
  (communication-rating uint) 
  (timeliness-rating uint) 
  (review-text (string-ascii 500)))
  (begin
    (asserts! (not (is-eq tx-sender reviewee)) ERR_CANNOT_REVIEW_SELF)
    (asserts! (is-task-participant task-id) ERR_NOT_AUTHORIZED)
    (asserts! (and (<= overall-rating u5) (>= overall-rating u1)) ERR_INVALID_RATING)
    (asserts! (and (<= quality-rating u5) (>= quality-rating u1)) ERR_INVALID_RATING)
    (asserts! (and (<= communication-rating u5) (>= communication-rating u1)) ERR_INVALID_RATING)
    (asserts! (and (<= timeliness-rating u5) (>= timeliness-rating u1)) ERR_INVALID_RATING)
    
    (let ((review-key { reviewer: tx-sender, reviewee: reviewee, task-id: task-id }))
      (asserts! (is-none (map-get? user-reviews review-key)) ERR_REVIEW_ALREADY_EXISTS)
      
      (map-set user-reviews review-key
        {
          overall-rating: overall-rating,
          quality-rating: quality-rating,
          communication-rating: communication-rating,
          timeliness-rating: timeliness-rating,
          review-text: review-text,
          created-at: stacks-block-height,
          verified: true
        }
      )
      
      (update-user-reputation reviewee overall-rating quality-rating communication-rating timeliness-rating)
      (var-set total-reviews-count (+ (var-get total-reviews-count) u1))
      (ok true)
    )
  )
)

(define-private (update-user-reputation (user principal) (overall uint) (quality uint) (communication uint) (timeliness uint))
  (let ((current-rep (default-to 
    { 
      reputation-score: u0, reliability-score: u0, communication-score: u0, quality-score: u0, 
      total-reviews: u0, positive-reviews: u0, tasks-completed-on-time: u0, tasks-completed-late: u0, 
      total-tasks-completed: u0, average-response-time: u0, badges-earned: (list), 
      reputation-level: REPUTATION_LEVEL_NEWCOMER, last-updated: stacks-block-height 
    } 
    (map-get? user-reputation user))))
    
    (let 
      (
        (new-total-reviews (+ (get total-reviews current-rep) u1))
        (new-positive-reviews (+ (get positive-reviews current-rep) (if (>= overall u4) u1 u0)))
        (new-reputation-score (calculate-reputation-score current-rep overall quality communication timeliness))
        (new-quality-score (/ (+ (* (get quality-score current-rep) (get total-reviews current-rep)) quality) new-total-reviews))
        (new-communication-score (/ (+ (* (get communication-score current-rep) (get total-reviews current-rep)) communication) new-total-reviews))
        (new-reliability-score (/ (+ (* (get reliability-score current-rep) (get total-reviews current-rep)) timeliness) new-total-reviews))
        (new-reputation-level (calculate-reputation-level new-reputation-score new-total-reviews))
      )
      
      (map-set user-reputation user
        (merge current-rep {
          reputation-score: new-reputation-score,
          reliability-score: new-reliability-score,
          communication-score: new-communication-score,
          quality-score: new-quality-score,
          total-reviews: new-total-reviews,
          positive-reviews: new-positive-reviews,
          reputation-level: new-reputation-level,
          last-updated: stacks-block-height
        })
      )
      
      (check-and-award-badges user new-reputation-score new-total-reviews new-positive-reviews)
      true
    )
  )
)

(define-private (calculate-reputation-score (current-rep { reputation-score: uint, reliability-score: uint, communication-score: uint, quality-score: uint, total-reviews: uint, positive-reviews: uint, tasks-completed-on-time: uint, tasks-completed-late: uint, total-tasks-completed: uint, average-response-time: uint, badges-earned: (list 10 uint), reputation-level: uint, last-updated: uint }) (overall uint) (quality uint) (communication uint) (timeliness uint))
  (let 
    (
      (current-score (get reputation-score current-rep))
      (total-reviews (get total-reviews current-rep))
      (weighted-average (/ (+ overall quality communication timeliness) u4))
    )
    (if (is-eq total-reviews u0)
      (* weighted-average u200) ;; Initial score multiplier
      (/ (+ (* current-score total-reviews) (* weighted-average u200)) (+ total-reviews u1))
    )
  )
)

(define-private (calculate-reputation-level (score uint) (reviews uint))
  (if (and (>= score u900) (>= reviews u50))
    REPUTATION_LEVEL_LEGEND
    (if (and (>= score u800) (>= reviews u25))
      REPUTATION_LEVEL_MASTER
      (if (and (>= score u700) (>= reviews u10))
        REPUTATION_LEVEL_EXPERT
        (if (and (>= score u600) (>= reviews u5))
          REPUTATION_LEVEL_RELIABLE
          REPUTATION_LEVEL_NEWCOMER
        )
      )
    )
  )
)

(define-private (check-and-award-badges (user principal) (reputation-score uint) (total-reviews uint) (positive-reviews uint))
  (let ((current-rep (unwrap-panic (map-get? user-reputation user))))
    (begin
      ;; Award completion badges
      (if (and (>= total-reviews u10) (not (is-badge-earned user u1)))
        (award-badge user u1)
        true
      )
      
      ;; Award quality badge
      (if (and (>= reputation-score u800) (not (is-badge-earned user u2)))
        (award-badge user u2)
        true
      )
      
      ;; Award reliability badge
      (if (and (>= (get reliability-score current-rep) u450) (not (is-badge-earned user u3)))
        (award-badge user u3)
        true
      )
      
      ;; Award communication badge
      (if (and (>= (get communication-score current-rep) u450) (not (is-badge-earned user u4)))
        (award-badge user u4)
        true
      )
      
      true
    )
  )
)

(define-private (is-badge-earned (user principal) (badge-id uint))
  (let ((current-rep (unwrap-panic (map-get? user-reputation user))))
    (is-some (index-of (get badges-earned current-rep) badge-id))
  )
)

(define-private (award-badge (user principal) (badge-id uint))
  (let ((current-rep (unwrap-panic (map-get? user-reputation user))))
    (map-set user-reputation user
      (merge current-rep {
        badges-earned: (unwrap-panic (as-max-len? (append (get badges-earned current-rep) badge-id) u10))
      })
    )
    true
  )
)

(define-public (initialize-reputation-badges)
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    
    (map-set reputation-badges u1
      {
        badge-name: "Reviewer",
        description: "Completed 10+ reviews with constructive feedback",
        requirement-threshold: u10,
        badge-type: BADGE_TYPE_COMPLETION
      }
    )
    
    (map-set reputation-badges u2
      {
        badge-name: "Quality Master",
        description: "Maintained 800+ reputation score with excellent work",
        requirement-threshold: u800,
        badge-type: BADGE_TYPE_QUALITY
      }
    )
    
    (map-set reputation-badges u3
      {
        badge-name: "Reliable Partner",
        description: "Consistently delivers tasks on time",
        requirement-threshold: u450,
        badge-type: BADGE_TYPE_RELIABILITY
      }
    )
    
    (map-set reputation-badges u4
      {
        badge-name: "Communication Expert",
        description: "Excellent communication and client interaction",
        requirement-threshold: u450,
        badge-type: BADGE_TYPE_COMMUNICATION
      }
    )
    
    (var-set next-badge-id u5)
    (ok true)
  )
)

(define-public (get-reputation-summary (user principal))
  (ok (map-get? user-reputation user))
)

(define-read-only (get-user-review (reviewer principal) (reviewee principal) (task-id uint))
  (map-get? user-reviews { reviewer: reviewer, reviewee: reviewee, task-id: task-id })
)

(define-read-only (get-reputation-badge (badge-id uint))
  (map-get? reputation-badges badge-id)
)

(define-read-only (calculate-trust-score (user principal))
  (match (map-get? user-reputation user)
    rep (let 
      (
        (base-score (get reputation-score rep))
        (review-bonus (* (get total-reviews rep) u5))
        (positive-ratio (if (> (get total-reviews rep) u0)
                         (/ (* (get positive-reviews rep) u100) (get total-reviews rep))
                         u0))
        (badge-bonus (* (len (get badges-earned rep)) u25))
      )
      (+ base-score review-bonus badge-bonus positive-ratio)
    )
    u0
  )
)

(define-read-only (get-top-rated-users (limit uint))
  ;; This would need to be implemented with a more complex ranking system
  ;; For now, return a simple structure indicating the feature is available
  (ok { message: "Top rated users feature available", limit: limit })
)

;; Dispute functions
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

;; Read-only functions
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

;; Analytics read-only functions - NEW FEATURE
(define-read-only (get-platform-analytics (period-id uint))
  (map-get? platform-analytics period-id)
)

(define-read-only (get-user-activity (user principal))
  (map-get? user-activity user)
)

(define-read-only (get-daily-metrics (date uint))
  (map-get? daily-metrics date)
)

(define-read-only (get-user-performance-metrics (user principal))
  (map-get? user-performance-metrics user)
)

(define-read-only (get-platform-overview)
  {
    total-volume: (var-get total-platform-volume),
    total-completed-tasks: (var-get total-completed-tasks),
    total-active-users: (var-get total-active-users),
    platform-fee-percent: (var-get platform-fee-percent),
    next-task-id: (var-get next-task-id),
    contract-balance: (stx-get-balance (as-contract tx-sender))
  }
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

;; Admin functions
(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-fee u1000) ERR_INVALID_AMOUNT)
    (var-set platform-fee-percent new-fee)
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

