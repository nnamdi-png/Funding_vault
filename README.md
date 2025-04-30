# Funding Vault

A secure Clarity smart contract for the Stacks blockchain that enables goal-based fundraising with automatic fund distribution.

## Overview

Funding Vault is a decentralized funding platform that allows creators to set funding targets and deadlines. Contributors can add funds to the vault, and if the target amount is reached before the expiration date, funds are automatically released to the recipient. If the target isn't met by the deadline, contributors can withdraw their deposits.

## Features

- **Target-based funding**: Funds are only released when the target amount is reached
- **Time-limited campaigns**: Set an expiration date for funding campaigns
- **Automatic fund distribution**: Funds are automatically released when the target is met
- **Secure refund mechanism**: Contributors can withdraw their funds if the target isn't met
- **Campaign termination**: Recipients can terminate campaigns early, enabling withdrawals
- **Transparent tracking**: Real-time tracking of collected funds and campaign status

## Contract Functions

### Public Functions

- `initialize`: Set up a new funding campaign with target amount, expiration, and recipient
- `add-funds`: Contribute STX to the funding campaign
- `trigger-release`: Manually trigger the release of funds if target is met
- `withdraw-deposit`: Withdraw your contribution if the campaign expires without meeting its target
- `terminate-funding`: Allow the recipient to end the campaign early

### Read-only Functions

- `get-deposit`: Check how much a specific address has contributed
- `get-collected-funds`: View the total amount collected so far
- `get-target-amount`: View the funding target
- `get-expiration`: Check when the campaign expires
- `is-target-met`: Check if the funding target has been met
- `is-expiration-passed`: Check if the campaign has expired
- `get-recipient`: View the recipient address
- `get-contract-status`: Get a complete status report of the campaign

## Usage Example

```clarity
;; Initialize a new funding campaign
(contract-call? .funding-vault initialize u1000000 u100000 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Add funds to the campaign
(contract-call? .funding-vault add-funds)

;; Check campaign status
(contract-call? .funding-vault get-contract-status)
