// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {SupplyChainTracker} from "../src/contracts/SupplyChainTracker.sol";

contract Deploy is Script {
    function run() external {
        // Usará la clave proporcionada por --private-key o --keystore en la CLI
        vm.startBroadcast();

        SupplyChainTracker supplyChainTracker = new SupplyChainTracker();
        console.log(unicode"✅ SupplyChainTracker desplegado en:", address(supplyChainTracker));

        vm.stopBroadcast();
    }
}
