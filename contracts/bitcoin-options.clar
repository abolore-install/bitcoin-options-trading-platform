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