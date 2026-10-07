# Foundry Subscription Splitter

A Foundry-based subscription payment splitter that enables shared management of recurring service payments. This project demonstrates how multiple owners can jointly maintain subscriptions and collect recurring payments on behalf of shared services.

## What the product does
This contract lets a group of shared owners manage recurring service subscriptions. Owners can add new service subscriptions with specific payment amounts and intervals, and service providers can collect payments when their subscription period has elapsed. The contract maintains a balance that owners can refill, and payment collection is enforced only when the lock period has passed.

## The problem it solves
Many applications require recurring payments, but managing subscriptions across multiple participants is complex. Without a smart contract, these payments require manual coordination or a centralized processor. This project demonstrates how to enforce recurring payment logic on-chain while maintaining shared ownership.

## My specific contribution
I implemented the subscription registry, payment collection logic, owner governance, and deployment configuration. The focus is on making recurring payments safe, predictable, and verifiable on-chain.

## Architecture
The repository includes:

- `src/SubscriptionSplitter.sol` — subscription management and payment collection
- `script/DeploySubscriptionSplitter.s.sol` — deployment script
- `test/SubscriptionSplitterTest.t.sol` — payment and subscription tests
- `lib/` — Foundry dependencies
- `foundry.toml` — Foundry configuration

## Technologies
- Solidity
- Foundry
- Forge testing
- Recurring payment logic
- Time-based access control

## Important technical decisions
- Subscriptions are stored in a mapping with a struct that includes the service address, payment amount, period, and last-payment timestamp.
- Owner-only operations ensure only authorized participants can manage subscriptions.
- Payment collection uses block timestamps to enforce lock periods and prevent duplicate charges within a single interval.
- Custom errors make invalid subscription and payment states explicit.
- The contract requires a minimum balance to prevent payment failures due to insufficient funds.

## Key features
- Multi-owner governance for subscription management
- Recurring payment enforcement with time-based locks
- Service provider claim logic
- Subscription addition and removal
- Balance tracking and deposit handling
- Event-driven auditing of all subscriptions and payments

## Screenshots
No screenshots are included.

## Live demo
No live deployment is included in the repository.

## Challenges and solutions
The main challenge is preventing duplicate payment and ensuring subscriptions can only be claimed once per interval. This is solved by tracking the last payment timestamp and comparing it against the subscription period.

Another challenge is maintaining a safe owner set without duplicates. The solution is to validate owner uniqueness at construction time and prevent zero-address entries.

## Setup instructions
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone
git clone https://github.com/Hayotunday/foundry-subscription-splitter.git
cd foundry-subscription-splitter

# Install dependencies
forge install

# Build
forge build

# Run tests
forge test

# Optional
forge fmt
forge snapshot
```
