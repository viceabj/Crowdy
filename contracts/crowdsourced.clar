;; Crowdsourced Digital Monument
;; A collaborative NFT that evolves through community contributions and voting

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MINIMUM-VOTES u10)
(define-constant VOTING-PERIOD u144) ;; ~24 hours in blocks
(define-constant ACCEPTANCE-THRESHOLD u70) ;; 70% approval needed

;; Data Variables
(define-data-var total-contributions uint u0)
(define-data-var current-proposal-id uint u0)

;; Data Maps
(define-map contributions uint
  {
    contributor: principal,
    content-hash: (buff 32),
    timestamp: uint,
    accepted: bool
  }
)

(define-map proposals uint
  {
    contributor: principal,
    content-hash: (buff 32),
    voting-start: uint,
    yes-votes: uint,
    no-votes: uint,
    processed: bool
  }
)

(define-map user-votes {proposal-id: uint, voter: principal} bool)

;; Error constants
(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-ALREADY-VOTED (err u101))
(define-constant ERR-PROPOSAL-EXPIRED (err u102))
(define-constant ERR-PROPOSAL-ACTIVE (err u103))
(define-constant ERR-INVALID-PROPOSAL (err u104))

;; Read-only functions

(define-read-only (get-contribution (id uint))
  (map-get? contributions id)
)

(define-read-only (get-proposal (id uint))
  (map-get? proposals id)
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? user-votes {proposal-id: proposal-id, voter: voter})
)

(define-read-only (is-proposal-active (proposal-id uint))
  (let (
    (proposal (unwrap! (get-proposal proposal-id) false))
    (current-block block-height)
  )
    (and
      (not (get processed proposal))
      (<= current-block (+ (get voting-start proposal) VOTING-PERIOD))
    )
  )
)

;; Public functions

;; Submit a new contribution proposal
(define-public (submit-proposal (content-hash (buff 32)))
  (let
    (
      (proposal-id (+ (var-get current-proposal-id) u1))
    )
    (map-set proposals proposal-id
      {
        contributor: tx-sender,
        content-hash: content-hash,
        voting-start: block-height,
        yes-votes: u0,
        no-votes: u0,
        processed: false
      }
    )
    (var-set current-proposal-id proposal-id)
    (ok proposal-id)
  )
)

;; Cast a vote on a proposal
(define-public (vote (proposal-id uint) (support bool))
  (let
    (
      (proposal (unwrap! (get-proposal proposal-id) ERR-INVALID-PROPOSAL))
    )
    (asserts! (is-proposal-active proposal-id) ERR-PROPOSAL-EXPIRED)
    (asserts! (is-none (get-vote proposal-id tx-sender)) ERR-ALREADY-VOTED)

    (map-set user-votes {proposal-id: proposal-id, voter: tx-sender} support)
    (if support
      (map-set proposals proposal-id
        (merge proposal {yes-votes: (+ (get yes-votes proposal) u1)}))
      (map-set proposals proposal-id
        (merge proposal {no-votes: (+ (get no-votes proposal) u1)}))
    )
    (ok true)
  )
)
