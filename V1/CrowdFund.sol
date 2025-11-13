// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFund {

    address public owner;
    uint public goal;
    uint public deadline;
    uint public totalRaised;
    bool public goalReached;
    bool public fundsWithdrawn;
    mapping(address => uint) public donations;

    event DonationOccured(address donor, uint amount);
    event WithdrawalOccured(address receiver, uint amount);
    event RefundOccured(address receiver, uint amount);

    constructor(uint _goal, uint _durationMinutes) {
        owner = msg.sender;
        goal = _goal * 1 ether;
        deadline = block.timestamp + (_durationMinutes * 60);
    }

    modifier campaignRunning() {
        require(block.timestamp <= deadline, "The donation campaign has finished.");
        _;
    }

    modifier campaignFinished() {
        require(block.timestamp > deadline, "The donation campaign has not finished yet!");
        _;
    }

    modifier ownerOnlyAction() {
        require(msg.sender == owner, "You are not authorized to perform this action!");
        _;
    }

    function donate() public payable campaignRunning {
        require(msg.value > 0, "Donation must be greater than zero!");
        totalRaised += msg.value;
        donations[msg.sender] += msg.value;
        if (totalRaised >= goal) {
            goalReached = true;
        }
    	emit DonationOccured(msg.sender, msg.value);
    }

    function withdrawFunds() public ownerOnlyAction campaignFinished {
        require(goalReached, "Can't withdraw! Campaign did not reach its goal.");
        require(!fundsWithdrawn, "Funds have already been withdrawn!");
        uint amount = address(this).balance;
        payable(owner).transfer(amount);
        fundsWithdrawn = true;
        emit WithdrawalOccured(owner, amount);
    }

    function getRefund() public campaignFinished {
        require(totalRaised < goal, "Can't get a refund! Campaign reached its goal.");
        uint amount = donations[msg.sender];
        require(amount > 0, "No donations to refund!");
        donations[msg.sender] = 0; 
        payable(msg.sender).transfer(amount);
        emit RefundOccured(msg.sender, amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function getTimeLeft() external view returns (uint) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
}