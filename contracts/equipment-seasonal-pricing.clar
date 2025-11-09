(define-constant err-unauthorized (err u401))
(define-constant err-not-found (err u402))
(define-constant err-invalid-season (err u403))
(define-constant err-invalid-multiplier (err u404))
(define-constant err-pricing-exists (err u405))

(define-constant season-spring u1)
(define-constant season-summer u2)
(define-constant season-fall u3)
(define-constant season-winter u4)

(define-map seasonal-pricing
  { equipment-id: uint, season: uint }
  { price-multiplier: uint }
)

(define-map equipment-base-pricing
  { equipment-id: uint }
  {
    owner: principal,
    base-daily-rate: uint,
    pricing-enabled: bool
  }
)

(define-public (enable-seasonal-pricing (equipment-id uint) (base-rate uint))
  (let ((existing (map-get? equipment-base-pricing { equipment-id: equipment-id })))
    (asserts! (is-none existing) err-pricing-exists)
    (asserts! (> base-rate u0) err-invalid-multiplier)
    
    (map-set equipment-base-pricing
      { equipment-id: equipment-id }
      { owner: tx-sender, base-daily-rate: base-rate, pricing-enabled: true }
    )
    (ok true)
  )
)

(define-public (set-season-multiplier (equipment-id uint) (season uint) (multiplier uint))
  (let ((pricing-data (unwrap! (map-get? equipment-base-pricing { equipment-id: equipment-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get owner pricing-data)) err-unauthorized)
    (asserts! (and (>= season season-spring) (<= season season-winter)) err-invalid-season)
    (asserts! (and (>= multiplier u50) (<= multiplier u300)) err-invalid-multiplier)
    
    (map-set seasonal-pricing
      { equipment-id: equipment-id, season: season }
      { price-multiplier: multiplier }
    )
    (ok true)
  )
)

(define-public (toggle-pricing (equipment-id uint))
  (let ((pricing-data (unwrap! (map-get? equipment-base-pricing { equipment-id: equipment-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get owner pricing-data)) err-unauthorized)
    
    (map-set equipment-base-pricing
      { equipment-id: equipment-id }
      (merge pricing-data { pricing-enabled: (not (get pricing-enabled pricing-data)) })
    )
    (ok true)
  )
)

(define-read-only (calculate-seasonal-rate (equipment-id uint) (season uint))
  (let (
    (base-data (map-get? equipment-base-pricing { equipment-id: equipment-id }))
    (season-data (map-get? seasonal-pricing { equipment-id: equipment-id, season: season }))
  )
    (match base-data
      pricing
        (if (get pricing-enabled pricing)
          (match season-data
            multiplier-data (some (/ (* (get base-daily-rate pricing) (get price-multiplier multiplier-data)) u100))
            (some (get base-daily-rate pricing))
          )
          none
        )
      none
    )
  )
)

(define-read-only (get-pricing-config (equipment-id uint))
  (map-get? equipment-base-pricing { equipment-id: equipment-id })
)

(define-read-only (get-season-multiplier (equipment-id uint) (season uint))
  (map-get? seasonal-pricing { equipment-id: equipment-id, season: season })
)
