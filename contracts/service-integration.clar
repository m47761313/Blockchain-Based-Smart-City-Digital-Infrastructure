;; Service Integration Contract
;; Connects and manages smart city services

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-already-connected (err u202))
(define-constant err-invalid-service (err u203))

;; Service types
(define-constant service-transport u1)
(define-constant service-energy u2)
(define-constant service-water u3)
(define-constant service-waste u4)
(define-constant service-security u5)

;; Data structures
(define-map city-services
  { service-id: uint }
  {
    name: (string-ascii 64),
    service-type: uint,
    endpoint: (string-ascii 128),
    status: bool,
    integration-date: uint,
    last-sync: uint
  }
)

(define-map service-connections
  { from-service: uint, to-service: uint }
  {
    connection-type: (string-ascii 32),
    data-flow: (string-ascii 64),
    established-date: uint,
    active: bool
  }
)

(define-data-var next-service-id uint u1)

;; Register new service
(define-public (register-service (name (string-ascii 64)) (service-type uint) (endpoint (string-ascii 128)))
  (let ((service-id (var-get next-service-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= service-type service-security) err-invalid-service)
    (map-set city-services
      { service-id: service-id }
      {
        name: name,
        service-type: service-type,
        endpoint: endpoint,
        status: true,
        integration-date: block-height,
        last-sync: block-height
      }
    )
    (var-set next-service-id (+ service-id u1))
    (ok service-id)
  )
)

;; Connect two services
(define-public (connect-services (from-service uint) (to-service uint) (connection-type (string-ascii 32)) (data-flow (string-ascii 64)))
  (let (
    (from-exists (is-some (map-get? city-services { service-id: from-service })))
    (to-exists (is-some (map-get? city-services { service-id: to-service })))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! from-exists err-not-found)
    (asserts! to-exists err-not-found)
    (asserts! (is-none (map-get? service-connections { from-service: from-service, to-service: to-service })) err-already-connected)
    (map-set service-connections
      { from-service: from-service, to-service: to-service }
      {
        connection-type: connection-type,
        data-flow: data-flow,
        established-date: block-height,
        active: true
      }
    )
    (ok true)
  )
)

;; Get service info
(define-read-only (get-service-info (service-id uint))
  (map-get? city-services { service-id: service-id })
)

;; Get connection info
(define-read-only (get-connection-info (from-service uint) (to-service uint))
  (map-get? service-connections { from-service: from-service, to-service: to-service })
)

;; Update service status
(define-public (update-service-status (service-id uint) (status bool))
  (let ((service (unwrap! (map-get? city-services { service-id: service-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set city-services
      { service-id: service-id }
      (merge service {
        status: status,
        last-sync: block-height
      })
    )
    (ok true)
  )
)
