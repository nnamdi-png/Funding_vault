;; funding-vault.clar
;; A smart contract that locks funds until a funding target is reached

;; Error codes
(define-constant ERR-EXPIRATION-PASSED (err u100))
(define-constant ERR-TARGET-NOT-MET (err u101))
(define-constant ERR-ALREADY-WITHDRAWN (err u102))
(define-constant ERR-NOT-RECIPIENT (err u103))
(define-constant ERR-EXPIRATION-NOT-REACHED (err u104))
(define-constant ERR-TARGET-ALREADY-MET (err u105))
(define-constant ERR-ZERO-AMOUNT (err u106))

;; Data variables
(define-data-var recipient principal tx-sender)
(define-data-var target-amount uint u0)
(define-data-var expiration uint u0)
(define-data-var collected-funds uint u0)
(define-data-var is-completed bool false)
(define-data-var is-terminated bool false)

;; Maps to track deposits and withdrawals
(define-map deposits principal uint)
(define-map withdrawal-processed principal bool)

;; Initialize the funding vault contract
(define-public (initialize (funding-target uint) (expiration-height uint) (fund-recipient principal))
  (begin
    (asserts! (is-eq tx-sender (var-get recipient)) (err u1))
    (asserts! (> funding-target u0) (err u2))
    (asserts! (> expiration-height stacks-block-height) (err u3))
    
    (var-set target-amount funding-target)
    (var-set expiration expiration-height)
    (var-set recipient fund-recipient)
    
    (ok true)))

;; Add funds to the vault
(define-public (add-funds)
  (let ((amount (stx-get-balance tx-sender)))
    (begin
      ;; Check that the expiration hasn't passed
      (asserts! (< stacks-block-height (var-get expiration)) ERR-EXPIRATION-PASSED)
      ;; Check that the target hasn't been met yet
      (asserts! (not (var-get is-completed)) ERR-TARGET-ALREADY-MET)
      ;; Check that the contract isn't terminated
      (asserts! (not (var-get is-terminated)) ERR-TARGET-NOT-MET)
      ;; Check that the amount is greater than zero
      (asserts! (> amount u0) ERR-ZERO-AMOUNT)
      
      ;; Transfer STX from sender to contract
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      
      ;; Update the deposits map and total collected
      (map-set deposits tx-sender 
        (+ (default-to u0 (map-get? deposits tx-sender)) amount))
      (var-set collected-funds (+ (var-get collected-funds) amount))
      
      ;; Check if target is met after this deposit
      (if (>= (var-get collected-funds) (var-get target-amount))
        (release-funds)
        (ok true)))))

;; Release the funds if target is met
(define-private (release-funds)
  (begin
    (asserts! (>= (var-get collected-funds) (var-get target-amount)) ERR-TARGET-NOT-MET)
    (asserts! (not (var-get is-completed)) ERR-TARGET-ALREADY-MET)
    
    ;; Transfer the funds to the recipient
    (try! (as-contract (stx-transfer? (var-get collected-funds) tx-sender (var-get recipient))))
    
    ;; Mark as completed
    (var-set is-completed true)
    (ok true)))

;; Manually trigger fund release (can be called by anyone if target is met)
(define-public (trigger-release)
  (begin
    (asserts! (>= (var-get collected-funds) (var-get target-amount)) ERR-TARGET-NOT-MET)
    (asserts! (not (var-get is-completed)) ERR-TARGET-ALREADY-MET)
    (release-funds)))

;; Withdraw deposit if expiration passed and target not met
(define-public (withdraw-deposit)
  (let 
    ((deposit-amount (default-to u0 (map-get? deposits tx-sender))))
    (begin
      ;; Check that the expiration has passed
      (asserts! (>= stacks-block-height (var-get expiration)) ERR-EXPIRATION-NOT-REACHED)
      ;; Check that the target was not met
      (asserts! (< (var-get collected-funds) (var-get target-amount)) ERR-TARGET-NOT-MET)
      ;; Check that the user has not already processed their withdrawal
      (asserts! (not (default-to false (map-get? withdrawal-processed tx-sender))) ERR-ALREADY-WITHDRAWN)
      ;; Check that the user has deposited
      (asserts! (> deposit-amount u0) ERR-ZERO-AMOUNT)
      
      ;; Transfer the deposit back
      (try! (as-contract (stx-transfer? deposit-amount tx-sender tx-sender)))
      
      ;; Mark as processed
      (map-set withdrawal-processed tx-sender true)
      (ok true))))

;; Terminate the funding and enable withdrawals (only recipient can do this)
(define-public (terminate-funding)
  (begin
    (asserts! (is-eq tx-sender (var-get recipient)) ERR-NOT-RECIPIENT)
    (asserts! (not (var-get is-completed)) ERR-TARGET-ALREADY-MET)
    (asserts! (not (var-get is-terminated)) (err u107))
    
    (var-set is-terminated true)
    (ok true)))

;; Read-only functions to check status
(define-read-only (get-deposit (depositor principal))
  (default-to u0 (map-get? deposits depositor)))

(define-read-only (get-collected-funds)
  (var-get collected-funds))

(define-read-only (get-target-amount)
  (var-get target-amount))

(define-read-only (get-expiration)
  (var-get expiration))

(define-read-only (is-target-met)
  (>= (var-get collected-funds) (var-get target-amount)))

(define-read-only (is-expiration-passed)
  (>= stacks-block-height (var-get expiration)))

(define-read-only (get-recipient)
  (var-get recipient))

(define-read-only (get-contract-status)
  {
    collected-funds: (var-get collected-funds),
    target-amount: (var-get target-amount),
    expiration: (var-get expiration),
    is-completed: (var-get is-completed),
    is-terminated: (var-get is-terminated),
    recipient: (var-get recipient),
    current-block: stacks-block-height
  })