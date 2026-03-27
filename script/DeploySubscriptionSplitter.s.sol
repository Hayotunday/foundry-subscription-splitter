// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {SubscriptionSplitter} from "src/SubscriptionSplitter.sol";

contract DeploySubscriptionSplitter is Script {
  SubscriptionSplitter public subscriptionSplitter;

  function run(address[] memory _owners)
    external
    returns (SubscriptionSplitter)
  {
    vm.startBroadcast();
    subscriptionSplitter = new SubscriptionSplitter(_owners);
    vm.stopBroadcast();
    return subscriptionSplitter;
  }
}
