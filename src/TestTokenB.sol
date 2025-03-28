// src/TestToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestTokenB is ERC20 {
    constructor() ERC20("Test Token", "TSTB") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}