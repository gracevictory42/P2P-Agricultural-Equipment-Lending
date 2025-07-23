(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-insufficient-stake (err u104))
(define-constant err-not-available (err u105))
(define-constant err-rental-active (err u106))
(define-constant err-rental-expired (err u107))

(define-data-var next-equipment-id uint u1)
(define-data-var next-rental-id uint u1)

(define-map equipment
  { equipment-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    description: (string-ascii 200),
    daily-rate: uint,
    stake-required: uint,
    is-available: bool
  }
)

(define-map rentals
  { rental-id: uint }
  {
    equipment-id: uint,
    renter: principal,
    owner: principal,
    start-block: uint,
    end-block: uint,
    daily-rate: uint,
    stake-amount: uint,
    is-active: bool,
    is-returned: bool
  }
)

(define-map user-stakes
  { user: principal, equipment-id: uint }
  { amount: uint }
)

(define-public (register-equipment (name (string-ascii 50)) (description (string-ascii 200)) (daily-rate uint) (stake-required uint))
  (let ((equipment-id (var-get next-equipment-id)))
    (map-set equipment
      { equipment-id: equipment-id }
      {
        owner: tx-sender,
        name: name,
        description: description,
        daily-rate: daily-rate,
        stake-required: stake-required,
        is-available: true
      }
    )
    (var-set next-equipment-id (+ equipment-id u1))
    (ok equipment-id)
  )
)

(define-public (rent-equipment (equipment-id uint) (rental-days uint))
  (let (
    (equipment-data (unwrap! (map-get? equipment { equipment-id: equipment-id }) err-not-found))
    (rental-id (var-get next-rental-id))
    (start-block stacks-block-height)
    (end-block (+ stacks-block-height (* rental-days u144)))
    (total-cost (* (get daily-rate equipment-data) rental-days))
    (stake-amount (get stake-required equipment-data))
  )
    (asserts! (get is-available equipment-data) err-not-available)
    (asserts! (not (is-eq tx-sender (get owner equipment-data))) err-unauthorized)
    
    (try! (stx-transfer? total-cost tx-sender (get owner equipment-data)))
    (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))
    
    (map-set equipment
      { equipment-id: equipment-id }
      (merge equipment-data { is-available: false })
    )
    
    (map-set rentals
      { rental-id: rental-id }
      {
        equipment-id: equipment-id,
        renter: tx-sender,
        owner: (get owner equipment-data),
        start-block: start-block,
        end-block: end-block,
        daily-rate: (get daily-rate equipment-data),
        stake-amount: stake-amount,
        is-active: true,
        is-returned: false
      }
    )
    
    (map-set user-stakes
      { user: tx-sender, equipment-id: equipment-id }
      { amount: stake-amount }
    )
    
    (var-set next-rental-id (+ rental-id u1))
    (ok rental-id)
  )
)

(define-public (return-equipment (rental-id uint))
  (let (
    (rental-data (unwrap! (map-get? rentals { rental-id: rental-id }) err-not-found))
    (equipment-id (get equipment-id rental-data))
    (equipment-data (unwrap! (map-get? equipment { equipment-id: equipment-id }) err-not-found))
  )
    (asserts! (is-eq tx-sender (get renter rental-data)) err-unauthorized)
    (asserts! (get is-active rental-data) err-rental-active)
    (asserts! (not (get is-returned rental-data)) err-rental-active)
    
    (map-set rentals
      { rental-id: rental-id }
      (merge rental-data { is-active: false, is-returned: true })
    )
    
    (map-set equipment
      { equipment-id: equipment-id }
      (merge equipment-data { is-available: true })
    )
    
    (as-contract (stx-transfer? (get stake-amount rental-data) tx-sender (get renter rental-data)))
  )
)

(define-public (claim-overdue-stake (rental-id uint))
  (let (
    (rental-data (unwrap! (map-get? rentals { rental-id: rental-id }) err-not-found))
    (equipment-id (get equipment-id rental-data))
  )
    (asserts! (is-eq tx-sender (get owner rental-data)) err-unauthorized)
    (asserts! (get is-active rental-data) err-rental-active)
    (asserts! (> stacks-block-height (get end-block rental-data)) err-rental-expired)
    
    (map-set rentals
      { rental-id: rental-id }
      (merge rental-data { is-active: false })
    )
    
    (let ((equipment-data (unwrap! (map-get? equipment { equipment-id: equipment-id }) err-not-found)))
      (map-set equipment
        { equipment-id: equipment-id }
        (merge equipment-data { is-available: true })
      )
    )
    
    (as-contract (stx-transfer? (get stake-amount rental-data) tx-sender (get owner rental-data)))
  )
)

(define-read-only (get-equipment (equipment-id uint))
  (map-get? equipment { equipment-id: equipment-id })
)

(define-read-only (get-rental (rental-id uint))
  (map-get? rentals { rental-id: rental-id })
)

(define-read-only (get-user-stake (user principal) (equipment-id uint))
  (map-get? user-stakes { user: user, equipment-id: equipment-id })
)

(define-read-only (get-next-equipment-id)
  (var-get next-equipment-id)
)

(define-read-only (get-next-rental-id)
  (var-get next-rental-id)
)

(define-read-only (is-rental-overdue (rental-id uint))
  (match (map-get? rentals { rental-id: rental-id })
    rental-data (and 
      (get is-active rental-data)
      (> stacks-block-height (get end-block rental-data))
    )
    false
  )
)
