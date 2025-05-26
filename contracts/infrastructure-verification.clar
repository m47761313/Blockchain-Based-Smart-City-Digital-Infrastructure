;; Infrastructure Verification Contract
;; Validates and manages digital city infrastructure systems

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-status (err u103))

;; Infrastructure status types
(define-constant status-pending u0)
(define-constant status-verified u1)
(define-constant status-failed u2)
(define-constant status-maintenance u3)

;; Data structures
(define-map infrastructure-systems
  { system-id: uint }
  {
    name: (string-ascii 64),
    system-type: (string-ascii 32),
    status: uint,
    verified-by: principal,
    verification-date: uint,
    last-check: uint
  }
)

(define-map system-metrics
  { system-id: uint }
  {
    uptime: uint,
    performance-score: uint,
    security-level: uint,
    compliance-status: bool
  }
)

(define-data-var next-system-id uint u1)

;; Register new infrastructure system
(define-public (register-system (name (string-ascii 64)) (system-type (string-ascii 32)))
  (let ((system-id (var-get next-system-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set infrastructure-systems
      { system-id: system-id }
      {
        name: name,
        system-type: system-type,
        status: status-pending,
        verified-by: tx-sender,
        verification-date: block-height,
        last-check: block-height
      }
    )
    (var-set next-system-id (+ system-id u1))
    (ok system-id)
  )
)

;; Verify infrastructure system
(define-public (verify-system (system-id uint) (performance-score uint) (security-level uint))
  (let ((system (unwrap! (map-get? infrastructure-systems { system-id: system-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set infrastructure-systems
      { system-id: system-id }
      (merge system {
        status: status-verified,
        verified-by: tx-sender,
        verification-date: block-height,
        last-check: block-height
      })
    )
    (map-set system-metrics
      { system-id: system-id }
      {
        uptime: u100,
        performance-score: performance-score,
        security-level: security-level,
        compliance-status: true
      }
    )
    (ok true)
  )
)

;; Get system info
(define-read-only (get-system-info (system-id uint))
  (map-get? infrastructure-systems { system-id: system-id })
)

;; Get system metrics
(define-read-only (get-system-metrics (system-id uint))
  (map-get? system-metrics { system-id: system-id })
)

;; Update system status
(define-public (update-system-status (system-id uint) (new-status uint))
  (let ((system (unwrap! (map-get? infrastructure-systems { system-id: system-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-status status-maintenance) err-invalid-status)
    (map-set infrastructure-systems
      { system-id: system-id }
      (merge system {
        status: new-status,
        last-check: block-height
      })
    )
    (ok true)
  )
)
