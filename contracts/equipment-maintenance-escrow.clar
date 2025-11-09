(define-constant err-not-found (err u301))
(define-constant err-unauthorized (err u302))
(define-constant err-insufficient-funds (err u303))
(define-constant err-escrow-exists (err u304))
(define-constant err-no-escrow (err u305))
(define-constant err-invalid-amount (err u306))
(define-constant err-claim-exists (err u307))
(define-constant err-claim-not-found (err u308))

(define-constant min-damage-deposit u50000)
(define-data-var next-claim-id uint u1)

(define-map equipment-escrows
  { equipment-id: uint }
  {
    owner: principal,
    escrow-balance: uint,
    total-deposited: uint,
    active: bool
  }
)

(define-map damage-claims
  { claim-id: uint }
  {
    equipment-id: uint,
    reporter: principal,
    owner: principal,
    repair-cost: uint,
    deposit-amount: uint,
    description: (string-ascii 150),
    created-block: uint,
    is-resolved: bool,
    approved: bool
  }
)

(define-public (create-escrow (equipment-id uint) (initial-amount uint))
  (let ((existing-escrow (map-get? equipment-escrows { equipment-id: equipment-id })))
    (asserts! (is-none existing-escrow) err-escrow-exists)
    (asserts! (> initial-amount u0) err-invalid-amount)
    
    (try! (stx-transfer? initial-amount tx-sender (as-contract tx-sender)))
    
    (map-set equipment-escrows
      { equipment-id: equipment-id }
      {
        owner: tx-sender,
        escrow-balance: initial-amount,
        total-deposited: initial-amount,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (deposit-to-escrow (equipment-id uint) (amount uint))
  (let ((escrow-data (unwrap! (map-get? equipment-escrows { equipment-id: equipment-id }) err-no-escrow)))
    (asserts! (is-eq tx-sender (get owner escrow-data)) err-unauthorized)
    (asserts! (get active escrow-data) err-unauthorized)
    (asserts! (> amount u0) err-invalid-amount)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set equipment-escrows
      { equipment-id: equipment-id }
      (merge escrow-data {
        escrow-balance: (+ (get escrow-balance escrow-data) amount),
        total-deposited: (+ (get total-deposited escrow-data) amount)
      })
    )
    (ok true)
  )
)

(define-public (report-damage (equipment-id uint) (repair-cost uint) (description (string-ascii 150)))
  (let (
    (escrow-data (unwrap! (map-get? equipment-escrows { equipment-id: equipment-id }) err-no-escrow))
    (claim-id (var-get next-claim-id))
  )
    (asserts! (get active escrow-data) err-unauthorized)
    (asserts! (>= (get escrow-balance escrow-data) repair-cost) err-insufficient-funds)
    (asserts! (> repair-cost u0) err-invalid-amount)
    
    (try! (stx-transfer? min-damage-deposit tx-sender (as-contract tx-sender)))
    
    (map-set damage-claims
      { claim-id: claim-id }
      {
        equipment-id: equipment-id,
        reporter: tx-sender,
        owner: (get owner escrow-data),
        repair-cost: repair-cost,
        deposit-amount: min-damage-deposit,
        description: description,
        created-block: stacks-block-height,
        is-resolved: false,
        approved: false
      }
    )
    
    (var-set next-claim-id (+ claim-id u1))
    (ok claim-id)
  )
)

(define-public (approve-claim (claim-id uint))
  (let ((claim-data (unwrap! (map-get? damage-claims { claim-id: claim-id }) err-claim-not-found)))
    (asserts! (is-eq tx-sender (get owner claim-data)) err-unauthorized)
    (asserts! (not (get is-resolved claim-data)) err-unauthorized)
    
    (let ((escrow-data (unwrap! (map-get? equipment-escrows { equipment-id: (get equipment-id claim-data) }) err-no-escrow)))
      (try! (as-contract (stx-transfer? (get repair-cost claim-data) tx-sender (get reporter claim-data))))
      (try! (as-contract (stx-transfer? (get deposit-amount claim-data) tx-sender (get reporter claim-data))))
      
      (map-set equipment-escrows
        { equipment-id: (get equipment-id claim-data) }
        (merge escrow-data { escrow-balance: (- (get escrow-balance escrow-data) (get repair-cost claim-data)) })
      )
      
      (map-set damage-claims
        { claim-id: claim-id }
        (merge claim-data { is-resolved: true, approved: true })
      )
      (ok true)
    )
  )
)

(define-public (reject-claim (claim-id uint))
  (let ((claim-data (unwrap! (map-get? damage-claims { claim-id: claim-id }) err-claim-not-found)))
    (asserts! (is-eq tx-sender (get owner claim-data)) err-unauthorized)
    (asserts! (not (get is-resolved claim-data)) err-unauthorized)
    
    (try! (as-contract (stx-transfer? (get deposit-amount claim-data) tx-sender (get owner claim-data))))
    
    (map-set damage-claims
      { claim-id: claim-id }
      (merge claim-data { is-resolved: true, approved: false })
    )
    (ok true)
  )
)

(define-public (withdraw-escrow (equipment-id uint) (amount uint))
  (let ((escrow-data (unwrap! (map-get? equipment-escrows { equipment-id: equipment-id }) err-no-escrow)))
    (asserts! (is-eq tx-sender (get owner escrow-data)) err-unauthorized)
    (asserts! (<= amount (get escrow-balance escrow-data)) err-insufficient-funds)
    
    (try! (as-contract (stx-transfer? amount tx-sender (get owner escrow-data))))
    
    (map-set equipment-escrows
      { equipment-id: equipment-id }
      (merge escrow-data { escrow-balance: (- (get escrow-balance escrow-data) amount) })
    )
    (ok true)
  )
)

(define-read-only (get-escrow (equipment-id uint))
  (map-get? equipment-escrows { equipment-id: equipment-id })
)

(define-read-only (get-damage-claim (claim-id uint))
  (map-get? damage-claims { claim-id: claim-id })
)

(define-read-only (get-next-claim-id)
  (var-get next-claim-id)
)
