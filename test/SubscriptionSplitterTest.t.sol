// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {SubscriptionSplitter} from "src/SubscriptionSplitter.sol";
import {
  DeploySubscriptionSplitter
} from "script/DeploySubscriptionSplitter.s.sol";

contract SubscriptionSplitterTest is Test {
  SubscriptionSplitter public subscriptionSplitter;

  uint256 public constant SUBSCRIPTION_AMOUNT = 0.1 ether;
  uint256 public constant SUBSCRIPTION_PERIOD = 30 days;
  address public immutable IOWNER1 = makeAddr("OWNER1");
  address public immutable IOWNER2 = makeAddr("OWNER2");
  address public immutable IOWNER3 = makeAddr("OWNER3");
  address public immutable IUSER = makeAddr("USER");
  address public immutable ISERVICE_ADDRESS = makeAddr("SERVICE_ADDRESS");
  address public constant BURN_ADDRESS = address(0);
  string public constant SERVICE_PROVIDER = "SERVICE_PROVIDER";
  address[] public owners = [IOWNER1, IOWNER2, IOWNER3];

  function setUp() public {
    subscriptionSplitter = new DeploySubscriptionSplitter().run(owners);
  }

  modifier addNetflix() {
    vm.startPrank(IOWNER1);
    subscriptionSplitter.addSubcription(
      ISERVICE_ADDRESS,
      SERVICE_PROVIDER,
      SUBSCRIPTION_AMOUNT,
      SUBSCRIPTION_PERIOD
    );
    vm.stopPrank();
    _;
  }

  function testReceive() public {
    vm.deal(address(subscriptionSplitter), 2 ether);

    vm.startPrank(IOWNER1);
    vm.deal(IOWNER1, 1 ether);
    (bool success,) =
      address(subscriptionSplitter).call{value: SUBSCRIPTION_AMOUNT}("");
    vm.stopPrank();

    assert(success);
    assertEq(
      address(subscriptionSplitter).balance, SUBSCRIPTION_AMOUNT + 2 ether
    );
  }

  function testAddSubcription() public {
    vm.startPrank(IOWNER1);
    subscriptionSplitter.addSubcription(
      ISERVICE_ADDRESS,
      SERVICE_PROVIDER,
      SUBSCRIPTION_AMOUNT,
      SUBSCRIPTION_PERIOD
    );
    vm.stopPrank();
    SubscriptionSplitter.SubscriptionDetail memory sub =
      subscriptionSplitter.getSubscription(ISERVICE_ADDRESS);

    assertEq(sub.exists, true);
  }

  function testRemoveSubscription() public addNetflix {
    vm.startPrank(IOWNER2);
    subscriptionSplitter.removeSubcription(ISERVICE_ADDRESS);
    vm.stopPrank();

    SubscriptionSplitter.SubscriptionDetail memory sub =
      subscriptionSplitter.getSubscription(ISERVICE_ADDRESS);

    assertEq(sub.exists, false);
  }

  function testCollectPayment() public addNetflix {
    vm.deal(address(subscriptionSplitter), 2 ether);

    vm.startPrank(ISERVICE_ADDRESS);
    vm.warp(SUBSCRIPTION_PERIOD);
    subscriptionSplitter.collectPayment();
    vm.stopPrank();

    assertEq(address(ISERVICE_ADDRESS).balance, SUBSCRIPTION_AMOUNT);
  }

  function testReceiveCallerNotAuthorizedOwner() public addNetflix {
    vm.startPrank(IUSER);
    vm.deal(IUSER, 1 ether);
    vm.expectRevert(
      SubscriptionSplitter.SubscriptionSplitter__CallerNotAuthorizedOwner
        .selector
    );
    (bool success,) =
      address(subscriptionSplitter).call{value: SUBSCRIPTION_AMOUNT}("");
    vm.stopPrank();
  }

  function testInvalidNumberOfOwners() public {
    owners = [IOWNER1, IOWNER2];
    vm.expectRevert(
      SubscriptionSplitter.SubscriptionSplitter__InvalidNumberOfOwners.selector
    );
    new SubscriptionSplitter(owners);
  }

  function testOwnerCannotBeBurnAddress() public {
    owners = [IOWNER1, IOWNER2, BURN_ADDRESS];
    vm.expectRevert(
      SubscriptionSplitter.SubscriptionSplitter__OwnerCannotBeBurnAddress
        .selector
    );
    new SubscriptionSplitter(owners);
  }

  function testSubscriberCannotBeBurnAddress() public {
    vm.expectRevert(
      SubscriptionSplitter.SubscriptionSplitter__SubscriberCannotBeBurnAddress
        .selector
    );
    vm.startPrank(IOWNER1);
    subscriptionSplitter.addSubcription(
      BURN_ADDRESS, SERVICE_PROVIDER, SUBSCRIPTION_AMOUNT, SUBSCRIPTION_PERIOD
    );
    vm.stopPrank();
  }

  function testSubscriptionAmountMustBeMoreThanZero() public {
    vm.startPrank(IOWNER1);
    vm.expectRevert(
      SubscriptionSplitter.SubscriptionSplitter__SubscriptionAmountMustBeMoreThanZero
        .selector
    );
    subscriptionSplitter.addSubcription(
      ISERVICE_ADDRESS, SERVICE_PROVIDER, 0, SUBSCRIPTION_PERIOD
    );
    vm.stopPrank();
  }

  function testSubscriberAlreadyExists() public addNetflix {
    vm.startPrank(IOWNER3);
    vm.expectRevert(
      SubscriptionSplitter.SubscriptionSplitter__SubscriberAlreadyExists
      .selector
    );
    subscriptionSplitter.addSubcription(
      ISERVICE_ADDRESS,
      SERVICE_PROVIDER,
      SUBSCRIPTION_AMOUNT,
      SUBSCRIPTION_PERIOD
    );
    vm.stopPrank();
  }

  function testSubscriberDoesNotExists() public {
    vm.startPrank(IOWNER2);
    vm.expectRevert(
      SubscriptionSplitter.SubscriptionSplitter__SubscriberDoesNotExists
      .selector
    );
    subscriptionSplitter.removeSubcription(ISERVICE_ADDRESS);
    vm.stopPrank();
  }

  function testDuplicateOwnersNotAllowed() public {
    owners = [IOWNER1, IOWNER2, IOWNER2];
    vm.expectRevert(
      SubscriptionSplitter.SubscriptionSplitter__DuplicateOwnersNotAllowed
        .selector
    );
    new SubscriptionSplitter(owners);
  }

  function testSubscriberDoesNotExistsForCollectPayment() public {
    vm.deal(address(subscriptionSplitter), 2 ether);

    vm.startPrank(ISERVICE_ADDRESS);
    vm.warp(SUBSCRIPTION_PERIOD);

    vm.expectRevert(
      SubscriptionSplitter.SubscriptionSplitter__SubscriberDoesNotExists
      .selector
    );
    subscriptionSplitter.collectPayment();
    vm.stopPrank();
  }

  // require the use of vm.warp to properly test
  function testSubscriptionPeriodNotPassed() public addNetflix {
    vm.deal(address(subscriptionSplitter), 2 ether);
    vm.warp(10_000_000);

    SubscriptionSplitter.SubscriptionDetail memory sub =
      subscriptionSplitter.getSubscription(ISERVICE_ADDRESS);

    uint256 lastPaid = sub.lastPaymentTimestamp;
    uint256 period = sub.subscriptionPeriod;

    vm.startPrank(ISERVICE_ADDRESS);
    vm.expectRevert(
      SubscriptionSplitter.SubscriptionSplitter__SubscriptionPeriodNotPassed
        .selector
    );
    console2.log("timestamp: ", block.timestamp);
    console2.log("subscription time: ", lastPaid + period);
    subscriptionSplitter.collectPayment();
    vm.stopPrank();
  }

  function testBalanceMustBeMoreThanZero() public addNetflix {
    vm.startPrank(ISERVICE_ADDRESS);
    vm.warp(SUBSCRIPTION_PERIOD);
    vm.expectRevert(
      SubscriptionSplitter.SubscriptionSplitter__BalanceMustBeMoreThanZero
        .selector
    );
    subscriptionSplitter.collectPayment();
    vm.stopPrank();
  }

  function testInsufficientBalance() public addNetflix {
    vm.deal(address(subscriptionSplitter), 0.05 ether);

    vm.startPrank(ISERVICE_ADDRESS);
    vm.expectRevert(
      SubscriptionSplitter.SubscriptionSplitter__InsufficientBalance.selector
    );
    subscriptionSplitter.collectPayment();
    vm.stopPrank();
  }

  function testGetTotalBalance() public {
    vm.deal(address(subscriptionSplitter), 0.05 ether);

    vm.startPrank(IOWNER1);
    uint256 balance = subscriptionSplitter.getTotalBalance();
    vm.stopPrank();

    assertEq(balance, 0.05 ether);
  }

  function testGetOwners() public {
    vm.startPrank(IOWNER1);
    address[] memory owners = subscriptionSplitter.getOwners();
    vm.stopPrank();

    assertEq(owners[0], IOWNER1);
    assertEq(owners[1], IOWNER2);
    assertEq(owners[2], IOWNER3);
  }
}

// function testPaymentTransferFailed() public {
//   vm.expectRevert(
//     SubscriptionSplitter.SubscriptionSplitter__PaymentTransferFailed.selector
//   );
// }
