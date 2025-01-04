# Oracle Documentation

## Overview

The price oracle is a critical component of the Bitcoin Options Platform, providing reliable and timely BTC price data for option execution.

## Oracle Architecture

### 1. Components

#### Price Feed

- Current BTC price
- Last update timestamp
- Validity window

#### Oracle Authority

- Authorized oracle address
- Update permissions
- Administrative controls

### 2. Key Functions

```clarity
(define-public (update-btc-price (new-price uint)))
(define-read-only (get-current-btc-price))
(define-public (set-oracle-address (new-oracle principal)))
(define-public (set-price-validity-window (new-window uint)))
```

## Security Considerations

### 1. Access Control

- Only authorized oracle can update prices
- Contract owner manages oracle settings

### 2. Price Validation

- Non-zero price check
- Staleness prevention
- Validity window enforcement

### 3. Error Handling

- Invalid price protection
- Stale price protection
- Authorization checks

## Integration Guide

### 1. Oracle Updates

```clarity
;; Update price
(contract-call? .bitcoin-options update-btc-price u50000)

;; Get current price
(contract-call? .bitcoin-options get-current-btc-price)
```

### 2. Configuration

```clarity
;; Set new oracle
(contract-call? .bitcoin-options set-oracle-address 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)

;; Set validity window
(contract-call? .bitcoin-options set-price-validity-window u150)
```

## Best Practices

1. **Regular Updates**

   - Maintain fresh price data
   - Monitor update frequency
   - Handle network delays

2. **Error Recovery**

   - Backup price sources
   - Retry mechanisms
   - Alert systems

3. **Monitoring**
   - Price deviation alerts
   - Update frequency tracking
   - Error rate monitoring
