# Bitcoin Options Trading Platform Smart Contract

A secure and decentralized platform for trading Bitcoin options with automated execution, collateral management, and price oracle integration built on Stacks blockchain.

## Features

- **Decentralized Options Trading**: Create and trade Bitcoin CALL and PUT options
- **Automated Execution**: Smart contract handles option exercise and settlement
- **Price Oracle Integration**: Secure price feeds for option execution
- **Collateral Management**: Automated collateral locking and release
- **Configurable Parameters**: Adjustable platform fees and collateral ratios

## Technical Overview

The platform consists of several key components:

- **Option Creation**: Users can create CALL or PUT options by specifying:
  - Strike price
  - Expiry (in blocks)
  - Option amount
  - Required collateral
- **Price Oracle**: Provides secure BTC price feeds for option execution
- **Exercise Mechanism**: Automated profit calculation and settlement
- **Collateral System**: Manages deposits and locked funds

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for local development
- [Stacks Wallet](https://www.hiro.so/wallet) for deployment and interaction
- Basic understanding of options trading and Clarity smart contracts

### Installation

1. Clone the repository:

```bash
git clone https://github.com/abolore-install/bitcoin-options-trading-platform.git
```

2. Install dependencies:

```bash
clarinet requirements
```

3. Run tests:

```bash
clarinet test
```

### Usage

#### Creating an Option

```clarity
(contract-call? .bitcoin-options create-option "CALL" u45000 u1000 u10000)
```

Parameters:

- Option type: "CALL" or "PUT"
- Strike price (in sats)
- Expiry (in blocks)
- Amount (in sats)

#### Exercising an Option

```clarity
(contract-call? .bitcoin-options exercise-option u0)
```

Parameter:

- Option ID

#### Expiring an Option

```clarity
(contract-call? .bitcoin-options expire-option u0)
```

Parameter:

- Option ID

## Architecture

### Smart Contract Components

1. **Data Storage**

   - Options mapping
   - User balances
   - Oracle data

2. **Core Functions**

   - Option creation
   - Option exercise
   - Option expiration
   - Collateral management

3. **Administrative Functions**
   - Fee management
   - Oracle updates
   - Parameter configuration

### Security Features

- Row-level security
- Collateral validation
- Price staleness checks
- Access control

## Testing

The contract includes comprehensive test coverage:

```bash
clarinet test
```

Test suites cover:

- Option creation and validation
- Price oracle functionality
- Option exercise mechanics
- Administrative functions
- Error handling

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Security

For security concerns, please review our [SECURITY.md](SECURITY.md) file.

## License

This project is licensed under the MIT License - see [LICENSE.md](LICENSE.md) for details.

## Documentation

Detailed documentation is available in the [docs](docs/) directory.
