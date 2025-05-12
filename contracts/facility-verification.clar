;; facility-verification.clar
;; This contract validates industrial sites and maintains a registry of verified facilities

(define-data-var admin principal tx-sender)

;; Data structure for facilities
(define-map facilities
  { facility-id: uint }
  {
    owner: principal,
    name: (string-utf8 100),
    location: (string-utf8 100),
    verified: bool,
    verification-date: uint
  }
)

;; Counter for facility IDs
(define-data-var next-facility-id uint u1)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Register a new facility
(define-public (register-facility (name (string-utf8 100)) (location (string-utf8 100)))
  (let
    (
      (facility-id (var-get next-facility-id))
    )
    (asserts! (is-none (map-get? facilities { facility-id: facility-id })) (err u1))
    (map-set facilities
      { facility-id: facility-id }
      {
        owner: tx-sender,
        name: name,
        location: location,
        verified: false,
        verification-date: u0
      }
    )
    (var-set next-facility-id (+ facility-id u1))
    (ok facility-id)
  )
)

;; Verify a facility (admin only)
(define-public (verify-facility (facility-id uint))
  (begin
    (asserts! (is-admin) (err u403))
    (match (map-get? facilities { facility-id: facility-id })
      facility (begin
        (map-set facilities
          { facility-id: facility-id }
          (merge facility {
            verified: true,
            verification-date: block-height
          })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Get facility details
(define-read-only (get-facility (facility-id uint))
  (map-get? facilities { facility-id: facility-id })
)

;; Check if a facility is verified
(define-read-only (is-facility-verified (facility-id uint))
  (match (map-get? facilities { facility-id: facility-id })
    facility (get verified facility)
    false
  )
)

;; Transfer admin rights
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
