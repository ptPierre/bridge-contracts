# Bridge Contracts

This repo implements a simplified version of bridge contracts between two blockchains.

## Getting started

### Prerequisites
forge installed

### Configuration
Create a `.env` file following the .env.example file.

### Running
Build the contracts:
   ```
   forge build
   ```
Deploy the contracts to Holesky
    ```
    source .env
    forge script script/DeployTokenBridge.s.sol:DeployTokenBridge --rpc-url $HOLESKY_RPC_URL --broadcast --verify
    ```
Deploy the contracts to Sepolia
    ```
    source .env
    forge script script/DeployTokenBridge.s.sol:DeployTokenBridge --rpc-url $TARGET_CHAIN_RPC_URL --broadcast
    ```



## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
