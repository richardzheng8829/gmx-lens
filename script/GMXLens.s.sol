// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "../src/GMXLens.sol";

address constant owner = 0x349CF949BF40cd86586440d4b84E189e4f119210;

contract DeployScript is Script {
    function setUp() public {
    }

    function run() public {
        vm.startBroadcast(owner);
        address impl = address(new GMXLens());
        GMXLens lens = GMXLens(
            payable(new ERC1967Proxy(impl, abi.encodeWithSignature("initialize()"))));
        vm.stopBroadcast();
        
        console.log("Deployed Lens", address(lens));
    }
}

contract UpgradeScript is Script {
    function setUp() public {
    }

    function run() public {
        vm.startBroadcast(owner);
        address impl = address(new GMXLens());
        GMXLens(0x93dd001d8099fCf2e87559732857AD9017f3ACC8).upgradeTo(impl);
        vm.stopBroadcast();

        console.log("Upgraded Lens to new impl", address(impl));
    }
}