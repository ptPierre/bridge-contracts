// script/DeployToken.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/TestTokenB.sol";

contract DeployToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        TestTokenB token = new TestTokenB();
        
        vm.stopBroadcast();
        
        console.log("TestToken deployed to:", address(token));
    }
}