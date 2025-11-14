// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFund {

    struct Campaign {
        address owner;
        string title;
        uint goal;
        uint deadline;
        uint totalRaised;
        bool goalReached;
        bool fundsWithdrawn;
        mapping(address => uint) donations;
    }

    uint public campaignCount=1;
    mapping(uint => Campaign) public campaigns;

    event CampaignCreated(uint campaignId, address owner, string title, uint goal, uint deadline);
    event DonationOccured(uint campaignId, address donor, uint amount);
    event WithdrawalOccured(uint campaignId, address receiver, uint amount);
    event RefundOccured(uint campaignId, address receiver, uint amount);

    modifier campaignExists(uint _campaignId) {
        require(_campaignId < campaignCount, "Campaign does not exist!");
        _;
    }

    modifier campaignRunning(uint _campaignId) {
        require(block.timestamp <= campaigns[_campaignId].deadline, "Campaign has finished.");
        _;
    }

    modifier campaignFinished(uint _campaignId) {
        require(block.timestamp > campaigns[_campaignId].deadline, "Campaign has not finished yet!");
        _;
    }

    modifier onlyCampaignOwner(uint _campaignId) {
        require(msg.sender == campaigns[_campaignId].owner, "You are not the campaign owner!");
        _;
    }

    function createCampaign(
        string memory _title, 
        uint _goal, 
        uint _durationMinutes
    ) public returns (uint) {
        require(_goal > 0, "Goal must be greater than zero!");
        require(_durationMinutes > 0, "Duration must be greater than zero!");
        require(bytes(_title).length > 0, "Title cannot be empty!");

        uint campaignId = campaignCount++;
        Campaign storage newCampaign = campaigns[campaignId];
        
        newCampaign.owner = msg.sender;
        newCampaign.title = _title;
        newCampaign.goal = _goal * 1 ether;
        newCampaign.deadline = block.timestamp + (_durationMinutes * 60);
        newCampaign.totalRaised = 0;
        newCampaign.goalReached = false;
        newCampaign.fundsWithdrawn = false;

        emit CampaignCreated(campaignId, msg.sender, _title, newCampaign.goal, newCampaign.deadline);
        return campaignId;
    }

    function donateTo(uint _campaignId) 
        public 
        payable 
        campaignExists(_campaignId) 
        campaignRunning(_campaignId) 
    {
        require(msg.value > 0, "Donation must be greater than zero!");
        
        Campaign storage campaign = campaigns[_campaignId];
        campaign.totalRaised += msg.value;
        campaign.donations[msg.sender] += msg.value;
        
        if (campaign.totalRaised >= campaign.goal) {
            campaign.goalReached = true;
        }
        
        emit DonationOccured(_campaignId, msg.sender, msg.value);
    }

    function withdrawFunds(uint _campaignId) 
        public 
        campaignExists(_campaignId)
        onlyCampaignOwner(_campaignId)
        campaignFinished(_campaignId)  
    {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(campaign.goalReached, "Campaign did not reach its goal!");
        require(!campaign.fundsWithdrawn, "Funds have already been withdrawn!");
        
        uint amount = campaign.totalRaised;
        campaign.fundsWithdrawn = true;
        payable(campaign.owner).transfer(amount);
        
        emit WithdrawalOccured(_campaignId, campaign.owner, amount);
    }

    function getRefund(uint _campaignId) 
        public 
        campaignExists(_campaignId)
        campaignFinished(_campaignId) 
    {
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.goalReached, "Campaign reached its goal! No refunds.");
        
        uint amount = campaign.donations[msg.sender];
        require(amount > 0, "No donations to refund!");
        campaign.donations[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        
        emit RefundOccured(_campaignId, msg.sender, amount);
    }


    function getCampaignInfo(uint _campaignId) 
        external 
        view 
        campaignExists(_campaignId)
        returns (
            address owner,
            string memory title,
            uint goal,
            uint deadline,
            uint totalRaised,
            bool goalReached,
            bool fundsWithdrawn
        ) 
    {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.owner,
            campaign.title,
            campaign.goal,
            campaign.deadline,
            campaign.totalRaised,
            campaign.goalReached,
            campaign.fundsWithdrawn
        );
    }

    function getTimeLeft(uint _campaignId) 
        external 
        view 
        campaignExists(_campaignId)
        returns (uint) 
    {
        Campaign storage campaign = campaigns[_campaignId];
        if (block.timestamp >= campaign.deadline) {
            return 0;
        }
        return campaign.deadline - block.timestamp;
    }
}