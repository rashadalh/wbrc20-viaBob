// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/WBRC20.sol"; // Update the import path according to your project structure
import "@bob-collective/bob/bridge/IRelay.sol";

contract DeployWBRC20 is Script {
    function run() external {
        vm.startBroadcast();

        // Parameters for WBRC20 constructor
        uint256 cap = 1_000_000; // Example cap, adjust as necessary
        uint256 reward = 10; // Example block reward, adjust as necessary
        string memory name = "BridgeCityToken"; // Example token name
        string memory ticker = "CITYB"; // Example token ticker
        IRelay relay = IRelay(address(0xe92317b90E4Ee2a97933d774C7088c32A9AABC6D)); // tBTC Relay
        address usdt_sepolia = address(0x7169D38820dfd117C3FA1f22a697dBA58d90BA06); // sepolis USDT

        WBRC20 wbrc20 = new WBRC20(cap, reward, name, ticker, relay, usdt_sepolia);

        vm.stopBroadcast();
    }
}
