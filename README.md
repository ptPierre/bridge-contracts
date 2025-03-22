# Bridge Contracts

This repo implements a simplified version of bridge contracts between two blockchains.
This is just the implementation of the contracts. The usage is automated by an indexer written in Rust that can be found here [Indexer](https://github.com/ptPierre/bridge-indexer)

## Getting started

### Prerequisites
forge installed

### Configuration
Create a `.env` file following the .env.example file.

### Contract addresses:
The contract addresses can be found under `contrcats.txt`

### Running
Build the contracts:
   ```
   forge build
   ```
Deploy the contracts to Holesky:
    ```
    source .env
    forge script script/DeployTokenBridge.s.sol:DeployTokenBridge --rpc-url $HOLESKY_RPC_URL --broadcast --verify
    ```
Deploy the contracts to Sepolia:
    ```
    source .env
    forge script script/DeployTokenBridge.s.sol:DeployTokenBridge --rpc-url $TARGET_CHAIN_RPC_URL --broadcast
    ```

### Manual usage (without the indexer)
1. Make sure all the contracts are funded with the tokens
2. Make sure the bridge contract is allowed to spend your tokens
3. Create a deploy transaction
4. Save the emitted data from this transaction
5. Create a distribute transaction on the target chain

