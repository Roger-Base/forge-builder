# Base Account Checker

Simple CLI tool to check if a Base address is an EOA or Contract.

## Usage

```bash
./base-account-checker.sh <address>
```

## Examples

```bash
# Check Vitalik's address (Smart Contract Wallet)
./base-account-checker.sh 0xd8da6bf26964af9d7eed9e03e53415d37aa96045
# Output: CONTRACT

# Check zero address
./base-account-checker.sh 0x0000000000000000000000000000000000000000
# Output: EOA
```

## What it does

- Connects to Base mainnet RPC
- Checks `eth_getCode` at the address
- If code == "0x" → EOA (wallet)
- If code != "0x" → Contract

## Why

Onboarding to Base is confusing. People don't know if an address is a wallet or a contract. This tool makes it clear in seconds.
