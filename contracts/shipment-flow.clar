;; ShipmentFlow - Decentralized Shipment Tracking
;; Track shipments, routes, and delivery status across supply chain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-invalid-status (err u202))
(define-constant err-unauthorized (err u203))

;; Data Variables
(define-data-var shipment-counter uint u0)
(define-data-var carrier-counter uint u0)

;; Data Maps
(define-map carriers
    { carrier-id: uint }
    {
        name: (string-ascii 50),
        contact: (string-ascii 100),
        active: bool,
        rating: uint
    }
)

(define-map shipments
    { shipment-id: uint }
    {
        origin: (string-ascii 100),
        destination: (string-ascii 100),
        carrier-id: uint,
        status: (string-ascii 20),
        created-at: uint,
        estimated-delivery: uint,
        actual-delivery: (optional uint),
        sender: principal,
        recipient: principal
    }
)

(define-map shipment-checkpoints
    { checkpoint-id: uint }
    {
        shipment-id: uint,
        location: (string-ascii 100),
        timestamp: uint,
        status: (string-ascii 20),
        notes: (string-ascii 200)
    }
)

(define-data-var checkpoint-counter uint u0)

;; Public Functions

(define-public (register-carrier (name (string-ascii 50)) (contact (string-ascii 100)))
    (let
        (
            (carrier-id (+ (var-get carrier-counter) u1))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set carriers
            { carrier-id: carrier-id }
            {
                name: name,
                contact: contact,
                active: true,
                rating: u5
            }
        )
        (var-set carrier-counter carrier-id)
        (ok carrier-id)
    )
)

(define-public (create-shipment 
    (origin (string-ascii 100)) 
    (destination (string-ascii 100)) 
    (carrier-id uint)
    (estimated-delivery uint)
    (recipient principal))
    (let
        (
            (shipment-id (+ (var-get shipment-counter) u1))
            (carrier-data (unwrap! (map-get? carriers { carrier-id: carrier-id }) err-not-found))
        )
        (asserts! (get active carrier-data) err-not-found)
        (map-set shipments
            { shipment-id: shipment-id }
            {
                origin: origin,
                destination: destination,
                carrier-id: carrier-id,
                status: "CREATED",
                created-at: stacks-block-height,
                estimated-delivery: estimated-delivery,
                actual-delivery: none,
                sender: tx-sender,
                recipient: recipient
            }
        )
        (var-set shipment-counter shipment-id)
        (add-checkpoint shipment-id origin "CREATED" "Shipment created and ready for pickup")
        (ok shipment-id)
    )
)

(define-public (update-shipment-status (shipment-id uint) (new-status (string-ascii 20)) (location (string-ascii 100)) (notes (string-ascii 200)))
    (let
        (
            (shipment-data (unwrap! (map-get? shipments { shipment-id: shipment-id }) err-not-found))
            (carrier-data (unwrap! (map-get? carriers { carrier-id: (get carrier-id shipment-data) }) err-not-found))
        )
        (asserts! (or (is-eq tx-sender contract-owner) 
                     (is-eq tx-sender (get sender shipment-data))) err-unauthorized)
        (map-set shipments
            { shipment-id: shipment-id }
            (merge shipment-data { 
                status: new-status,
                actual-delivery: (if (is-eq new-status "DELIVERED") (some stacks-block-height) (get actual-delivery shipment-data))
            })
        )
        (add-checkpoint shipment-id location new-status notes)
        (ok true)
    )
)

(define-public (rate-carrier (carrier-id uint) (rating uint))
    (let
        (
            (carrier-data (unwrap! (map-get? carriers { carrier-id: carrier-id }) err-not-found))
        )
        (asserts! (<= rating u10) err-invalid-status)
        (asserts! (>= rating u1) err-invalid-status)
        (map-set carriers
            { carrier-id: carrier-id }
            (merge carrier-data { rating: rating })
        )
        (ok true)
    )
)

;; Private Functions

(define-private (add-checkpoint (shipment-id uint) (location (string-ascii 100)) (status (string-ascii 20)) (notes (string-ascii 200)))
    (let
        (
            (checkpoint-id (+ (var-get checkpoint-counter) u1))
        )
        (map-set shipment-checkpoints
            { checkpoint-id: checkpoint-id }
            {
                shipment-id: shipment-id,
                location: location,
                timestamp: stacks-block-height,
                status: status,
                notes: notes
            }
        )
        (var-set checkpoint-counter checkpoint-id)
        checkpoint-id
    )
)

;; Read Only Functions

(define-read-only (get-shipment (shipment-id uint))
    (map-get? shipments { shipment-id: shipment-id })
)

(define-read-only (get-carrier (carrier-id uint))
    (map-get? carriers { carrier-id: carrier-id })
)

(define-read-only (get-checkpoint (checkpoint-id uint))
    (map-get? shipment-checkpoints { checkpoint-id: checkpoint-id })
)

(define-read-only (get-shipment-count)
    (var-get shipment-counter)
)

(define-read-only (is-shipment-delayed (shipment-id uint))
    (match (map-get? shipments { shipment-id: shipment-id })
        shipment-data 
        (and 
            (> stacks-block-height (get estimated-delivery shipment-data))
            (not (is-eq (get status shipment-data) "DELIVERED"))
        )
        false
    )
)