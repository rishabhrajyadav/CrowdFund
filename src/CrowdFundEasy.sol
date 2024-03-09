// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMyToken {
    function getTokenPriceInUSD() external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

contract CrowdFundEasy {
		uint256 campaignIds;
        IMyToken immutable private token;
        struct Campaign {
            address creator;
            uint256 duration;
            uint256 goal;
            uint256 totalFundsCollected;
        }

        mapping(uint256 => Campaign) private campaigns;
        mapping(uint256 => mapping(address => uint256)) contributions;
		constructor(address _token) {
            token = IMyToken(_token);
        }

    /**
     * @notice createCampaign allows anyone to create a campaign
     * @param _goal amount of funds to be raised in USD
     * @param _duration the duration of the campaign in seconds
     */
    function createCampaign(uint256 _goal, uint256 _duration) external {
        if(_goal == 0) revert();
        if(_duration == 0) revert();
        uint256 goal = _goal;
        campaigns[++campaignIds] = Campaign(msg.sender , block.timestamp + _duration , goal , 0);
    }

    /**
     * @dev contribute allows anyone to contribute to a campaign
     * @param _id the id of the campaign
     * @param _amount the amount of tokens to contribute
     */
    function contribute(uint256 _id, uint256 _amount) external {
        if(_id > campaignIds) revert();
        Campaign memory campaign = campaigns[_id];
        if(block.timestamp >= campaign.duration) revert();
        if(_amount == 0) revert();
        if(msg.sender == campaign.creator) revert();

        contributions[_id][msg.sender] += _amount;
        campaigns[_id].totalFundsCollected += _amount;

        token.transferFrom(msg.sender, address(this), _amount); 
    }

    /**
     * @dev cancelContribution allows anyone to cancel their contribution
     * @param _id the id of the campaign
     */
    function cancelContribution(uint256 _id) external {
        uint256 contribution = contributions[_id][msg.sender];
        if(contributions[_id][msg.sender] == 0) revert();
        
        campaigns[_id].totalFundsCollected -= contribution;
        contributions[_id][msg.sender] = 0;
        token.transfer(msg.sender, contribution);
    }

    /**
     * @notice withdrawFunds allows the creator of the campaign to withdraw the funds
     * @param _id the id of the campaign
     */

    function withdrawFunds(uint256 _id) external {
        if(_id > campaignIds) revert();
        Campaign memory campaign = campaigns[_id];
        if(msg.sender != campaign.creator) revert();
        if(block.timestamp < campaign.duration) revert();
        if(campaign.goal > campaign.totalFundsCollected * token.getTokenPriceInUSD()) revert();
        
        campaigns[_id].totalFundsCollected = 0;
        token.transfer( campaign.creator , campaign.totalFundsCollected);

        delete campaigns[_id];
    }

    /**
     * @notice refund allows the contributors to get a refund if the campaign failed
     * @param _id the id of the campaign
     */
    function refund(uint256 _id) external {
        if(_id > campaignIds) revert();

        Campaign memory campaign = campaigns[_id];
        uint256 contribution = contributions[_id][msg.sender];

        if(msg.sender == campaign.creator) revert();
        if(block.timestamp < campaign.duration) revert();
        if(campaign.goal <= campaign.totalFundsCollected * token.getTokenPriceInUSD()) revert();      
        if(contributions[_id][msg.sender] == 0) revert();
        
        campaigns[_id].totalFundsCollected -= contribution;
        contributions[_id][msg.sender] = 0;
        token.transfer(msg.sender, contribution);
    }

    /**
     * @notice getContribution returns the contribution of a contributor in USD
     * @param _id the id of the campaign
     * @param _contributor the address of the contributor
     */
    function getContribution(uint256 _id, address _contributor) public view returns (uint256) {
        if(_id > campaignIds) revert();
       return contributions[_id][_contributor] * token.getTokenPriceInUSD();
    }
		
		/**
		 * @notice getCampaign returns details about a campaign
		 * @param _id the id of the campaign
		 * @return remainingTime the time (in seconds) when the campaign ends
		 * @return goal the goal of the campaign (in USD)
		 * @return totalFunds total funds (in USD) raised by the campaign
		 */
    function getCampaign(uint256 _id)
        external
        view
        returns (uint256 remainingTime, uint256 goal, uint256 totalFunds) {
            if(_id > campaignIds) revert();
            Campaign memory campaign = campaigns[_id];
            if(campaign.duration > block.timestamp){
              remainingTime = campaign.duration - block.timestamp ;
            }else{
                remainingTime = 0;
            } 
            goal = campaign.goal;
            totalFunds = campaign.totalFundsCollected * token.getTokenPriceInUSD(); 
        }
     
     //Just For testing you can remove this
     function fetchCampaignDetails(uint256 _id) external view returns (Campaign memory campaign) {
        return campaigns[_id];
    }   
}