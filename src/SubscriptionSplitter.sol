// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract SubscriptionSplitter {
  //// errors
  error SubscriptionSplitter__CallerNotAuthorizedOwner();
  error SubscriptionSplitter__InvalidNumberOfOwners();
  error SubscriptionSplitter__OwnerCannotBeBurnAddress();
  error SubscriptionSplitter__SubscriberCannotBeBurnAddress();
  error SubscriptionSplitter__SubscriptionAmountMustBeMoreThanZero();
  error SubscriptionSplitter__SubscriberDoesNotExists();
  error SubscriptionSplitter__SubscriberAlreadyExists();
  error SubscriptionSplitter__DuplicateOwnersNotAllowed();
  error SubscriptionSplitter__SubscriptionPeriodNotPassed();
  error SubscriptionSplitter__BalanceMustBeMoreThanZero();
  error SubscriptionSplitter__InsufficientBalance();
  error SubscriptionSplitter__PaymentTransferFailed();

  //// data stuctures
  struct SubscriptionDetail {
    bytes32 serviceProvider;
    address serviceAddress;
    uint256 subscriptionAmount;
    uint256 subscriptionPeriod;
    bool exists;
    uint256 lastPaymentTimestamp;
  }

  //// state variables
  uint256 public constant NUM_OWNERS = 3;
  address[] public sharedOwners = new address[](NUM_OWNERS);
  mapping(address => bool) public isOwner;
  mapping(address => SubscriptionDetail) public subscriptions;

  //// events
  event Deposited(address indexed from, uint256 amount);
  event PaymentCollected(address indexed from, uint256 amount);
  event SubscriberAdded(address indexed subscriber, uint256 amount);
  event SubscriberRemoved(address indexed subscriber);

  //// functions
  //// modifiers
  modifier onlyOwner() {
    if (!isOwner[msg.sender]) {
      revert SubscriptionSplitter__CallerNotAuthorizedOwner();
    }
    _;
  }

  //// constructors
  constructor(address[] memory _owners) {
    if (_owners.length != NUM_OWNERS) {
      revert SubscriptionSplitter__InvalidNumberOfOwners();
    }
    for (uint256 i = 0; i < NUM_OWNERS; i++) {
      address owns = _owners[i];

      if (owns == address(0)) {
        revert SubscriptionSplitter__OwnerCannotBeBurnAddress();
      }
      if (isOwner[owns]) {
        revert SubscriptionSplitter__DuplicateOwnersNotAllowed();
      }
      isOwner[owns] = true;
      sharedOwners[i] = owns;
    }
  }

  //// receive and fallback functions
  receive() external payable {
    if (!isOwner[msg.sender]) {
      revert SubscriptionSplitter__CallerNotAuthorizedOwner();
    }
    emit Deposited(msg.sender, msg.value);
  }

  //// external functions
  function addSubcription(
    address serviceAddress,
    string memory serviceProvider,
    uint256 subscriptionAmount,
    uint256 subscriptionPeriod
  ) external onlyOwner {
    if (serviceAddress == address(0)) {
      revert SubscriptionSplitter__SubscriberCannotBeBurnAddress();
    }
    if (subscriptionAmount <= 0) {
      revert SubscriptionSplitter__SubscriptionAmountMustBeMoreThanZero();
    }
    if (subscriptions[serviceAddress].exists) {
      revert SubscriptionSplitter__SubscriberAlreadyExists();
    }

    subscriptions[serviceAddress] = SubscriptionDetail(
      keccak256(abi.encodePacked(serviceProvider)),
      serviceAddress,
      subscriptionAmount,
      subscriptionPeriod,
      true,
      block.timestamp
    );
    emit SubscriberAdded(serviceAddress, subscriptionAmount);
  }

  function removeSubcription(address serviceAddress) external onlyOwner {
    if (!subscriptions[serviceAddress].exists) {
      revert SubscriptionSplitter__SubscriberDoesNotExists();
    }

    delete subscriptions[serviceAddress];
    emit SubscriberRemoved(serviceAddress);
  }

  function collectPayment() external {
    if (msg.sender == address(0)) {
      revert SubscriptionSplitter__SubscriberCannotBeBurnAddress();
    }
    if (!subscriptions[msg.sender].exists) {
      revert SubscriptionSplitter__SubscriberDoesNotExists();
    }
    if (
      block.timestamp
        > subscriptions[msg.sender].lastPaymentTimestamp
          + subscriptions[msg.sender].subscriptionPeriod
    ) {
      revert SubscriptionSplitter__SubscriptionPeriodNotPassed();
    }
    if (address(this).balance <= 0) {
      revert SubscriptionSplitter__BalanceMustBeMoreThanZero();
    }
    if (address(this).balance < subscriptions[msg.sender].subscriptionAmount) {
      revert SubscriptionSplitter__InsufficientBalance();
    }

    SubscriptionDetail storage subscription = subscriptions[msg.sender];
    uint256 subscriptionAmount = subscription.subscriptionAmount;
    address serviceAddress = subscription.serviceAddress;
    uint256 lastPaymentTimestamp = subscription.lastPaymentTimestamp;

    lastPaymentTimestamp = block.timestamp;
    subscriptions[msg.sender] = subscription;

    (bool success,) = serviceAddress.call{value: subscriptionAmount}("");
    if (!success) revert SubscriptionSplitter__PaymentTransferFailed();
    emit PaymentCollected(msg.sender, subscriptionAmount);
  }

  //// getter functions
  function getTotalBalance() external view onlyOwner returns (uint256) {
    return address(this).balance;
  }

  function getOwners() external view onlyOwner returns (address[] memory) {
    return sharedOwners;
  }

  function getSubscription(address _serviceAddress)
    external
    view
    returns (SubscriptionDetail memory)
  {
    return subscriptions[_serviceAddress];
  }
}
