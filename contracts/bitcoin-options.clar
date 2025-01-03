;; Title: Bitcoin Options Trading Platform Smart Contract
;; Description: A decentralized platform for trading Bitcoin options with automated
;; execution, collateral management, and price oracle integration.

;; ==============================================
;; Constants and Error Codes
;; ==============================================

;; Contract Owner
(define-constant CONTRACT_OWNER tx-sender)

;; Error Codes
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_OPTION_NOT_FOUND (err u103))
(define-constant ERR_OPTION_EXPIRED (err u104))
(define-constant ERR_INVALID_STRIKE_PRICE (err u105))
(define-constant ERR_INVALID_EXPIRY (err u106))
(define-constant ERR_INSUFFICIENT_COLLATERAL (err u107))
(define-constant ERR_OPTION_NOT_EXERCISABLE (err u108))

;; ==============================================
;; Data Variables
;; ==============================================

(define-data-var min-collateral-ratio uint u150) ;; 150% collateral ratio
(define-data-var platform-fee uint u10) ;; 0.1% fee (basis points)
(define-data-var next-option-id uint u0)

;; ==============================================
;; Data Maps
;; ==============================================

;; Options Storage
(define-map options
    uint ;; option-id
    {
        creator: principal,
        holder: principal,
        option-type: (string-ascii 4), ;; "CALL" or "PUT"
        strike-price: uint,
        expiry: uint,
        amount: uint,
        collateral: uint,
        status: (string-ascii 10) ;; "ACTIVE", "EXERCISED", "EXPIRED"
    }
)

;; User Balances
(define-map user-balances
    principal
    {
        sbtc-balance: uint,
        locked-collateral: uint
    }
)

;; ==============================================
;; Private Functions
;; ==============================================

;; Authorization Check
(define-private (is-contract-owner)
    (is-eq tx-sender CONTRACT_OWNER)
)

;; Option Expiry Check
(define-private (check-expiry (option-id uint))
    (let (
        (option (unwrap! (map-get? options option-id) ERR_OPTION_NOT_FOUND))
        (current-height block-height)
    )
    (if (> current-height (get expiry option))
        ERR_OPTION_EXPIRED
        (ok true)
    ))
)

;; Balance Management
(define-private (update-user-balance (user principal) (amount int))
    (let (
        (current-balance (default-to {sbtc-balance: u0, locked-collateral: u0} 
                        (map-get? user-balances user)))
        (new-balance (+ (get sbtc-balance current-balance) amount))
    )
    (if (>= new-balance u0)
        (map-set user-balances 
            user 
            (merge current-balance {sbtc-balance: new-balance}))
        ERR_INSUFFICIENT_BALANCE
    ))
)

;; ==============================================
;; Public Functions
;; ==============================================

;; Deposit sBTC
(define-public (deposit-sbtc (amount uint))
    (begin
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set user-balances
            tx-sender
            (merge (default-to {sbtc-balance: u0, locked-collateral: u0} 
                   (map-get? user-balances tx-sender))
                  {sbtc-balance: (+ (default-to u0 (get sbtc-balance 
                    (map-get? user-balances tx-sender))) amount)}))
        (ok true)
    )
)

;; Create Option
(define-public (create-option (option-type (string-ascii 4)) 
                            (strike-price uint)
                            (expiry uint)
                            (amount uint))
    (let (
        (option-id (var-get next-option-id))
        (required-collateral (/ (* amount strike-price) u100))
        (user-balance (default-to {sbtc-balance: u0, locked-collateral: u0} 
                     (map-get? user-balances tx-sender)))
    )
    (asserts! (or (is-eq option-type "CALL") (is-eq option-type "PUT")) 
              ERR_NOT_AUTHORIZED)
    (asserts! (>= strike-price u0) ERR_INVALID_STRIKE_PRICE)
    (asserts! (> expiry block-height) ERR_INVALID_EXPIRY)
    (asserts! (>= (get sbtc-balance user-balance) required-collateral) 
              ERR_INSUFFICIENT_COLLATERAL)
    
    ;; Create the option
    (map-set options option-id {
        creator: tx-sender,
        holder: tx-sender,
        option-type: option-type,
        strike-price: strike-price,
        expiry: expiry,
        amount: amount,
        collateral: required-collateral,
        status: "ACTIVE"
    })
    
    ;; Lock collateral
    (map-set user-balances tx-sender
        (merge user-balance {
            sbtc-balance: (- (get sbtc-balance user-balance) required-collateral),
            locked-collateral: (+ (get locked-collateral user-balance) required-collateral)
        }))
    
    ;; Increment option ID
    (var-set next-option-id (+ option-id u1))
    (ok option-id))
)

;; Exercise Option
(define-public (exercise-option (option-id uint))
    (let (
        (option (unwrap! (map-get? options option-id) ERR_OPTION_NOT_FOUND))
        (current-price (get-current-btc-price)) ;; Implemented via oracle
    )
    (asserts! (is-eq (get holder option) tx-sender) ERR_NOT_AUTHORIZED)
    (try! (check-expiry option-id))
    (asserts! (is-eq (get status option) "ACTIVE") ERR_OPTION_NOT_EXERCISABLE)
    
    (if (is-eq (get option-type option) "CALL")
        (if (> current-price (get strike-price option))
            (let (
                (profit (- current-price (get strike-price option)))
            )
            ;; Transfer profit to option holder
            (try! (update-user-balance tx-sender profit))
            ;; Update option status
            (map-set options option-id 
                (merge option {status: "EXERCISED"}))
            (ok true))
            ERR_OPTION_NOT_EXERCISABLE)
        ;; PUT option logic
        (if (< current-price (get strike-price option))
            (let (
                (profit (- (get strike-price option) current-price))
            )
            ;; Transfer profit to option holder
            (try! (update-user-balance tx-sender profit))
            ;; Update option status
            (map-set options option-id 
                (merge option {status: "EXERCISED"}))
            (ok true))
            ERR_OPTION_NOT_EXERCISABLE))
    )
)

;; Expire Option
(define-public (expire-option (option-id uint))
    (let (
        (option (unwrap! (map-get? options option-id) ERR_OPTION_NOT_FOUND))
    )
    (asserts! (> block-height (get expiry option)) ERR_OPTION_NOT_EXPIRED)
    (asserts! (is-eq (get status option) "ACTIVE") ERR_OPTION_NOT_EXERCISABLE)
    
    ;; Return collateral to creator
    (try! (update-user-balance (get creator option) (get collateral option)))
    
    ;; Update option status
    (map-set options option-id 
        (merge option {status: "EXPIRED"}))
    (ok true))
)