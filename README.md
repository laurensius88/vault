# Vault - Foundry Project

## Overview

The "Vault" Foundry project is a Solidity smart contract that provides secure handling of whitelisted ERC20 token deposits and withdrawals. It follows a structured approach with separate directories for source code (`src`) and tests (`test`).

## Features

- **Token Deposit and Withdrawal:** Enables any user to deposit and withdraw designated ERC20 tokens.
- **Whitelisting:** Allows admin to whitelist any of ERC20 tokens.
- **Security:** Implements pause/unpause by admin and reentrancy guards.
- **AccessControl:** Only admin can pause/unpause and whitelist ERC20 tokens.

## Requirements

- [Solidity](https://soliditylang.org/)
- [Foundry](https://getfoundry.sh/)

## Setup

1. **Clone the repository**:

   ```bash
   git clone [REPOSITORY_URL]
   cd [REPOSITORY_DIRECTORY]

   ```

2. **Compile Contracts:**
   Compile the smart contracts using Foundry's `forge`:

   ```shell
   forge build
   ```

3. **Run Tests:**
   Execute the test suite to ensure everything is working correctly:
   ```shell
   forge test
   ```
   This command will execute test/Vault.t.sol file, ensuring the contract functions as expected.

## License

This project is licensed under the [MIT License](LICENSE).
