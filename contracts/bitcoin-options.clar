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