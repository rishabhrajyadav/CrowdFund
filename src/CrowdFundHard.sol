// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMyToken{
    function getTokenPriceInUSD() external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

contract CrowdFund {
        uint256 private campaignIds;
        address[] private tokens;
        struct Campaign {
            address creator;
            uint256 duration;
            uint256 goal;
            uint256 totalFundsCollected;
        }

        mapping(uint256 => Campaign) private campaigns;
        mapping(uint256 => mapping(address => uint256)) campaignAmounts;
        mapping(uint256 => mapping(address => mapping(address => uint256))) contributions;
		/**
		 * @param _tokens list of allowed token addresses
		 */
		constructor(address[] memory _tokens) {
            tokens = _tokens;
        }

    /**
     * @notice createCampaign allows anyone to create a campaign
     * @param _goal amount of funds to be raised in USD
     * @param _duration the duration of the campaign in seconds
     */
    function createCampaign(uint256 _goal, uint256 _duration) external {
        if(_goal == 0) revert();
        if(_duration == 0) revert();
        campaigns[++campaignIds] = Campaign(msg.sender , block.timestamp + _duration , _goal , 0);
    }

    /**
     * @dev contribute allows anyone to contribute to a campaign
     * @param _id the id of the campaign
     * @param _token the address of the token to contribute
     * @param _amount the amount of tokens to contribute
     */
    function contribute(uint256 _id, address _token, uint256 _amount) external {
        if(_id > campaignIds) revert();
        if(!isTokenValid(tokens ,_token)) revert();
        Campaign memory campaign = campaigns[_id];
        if(block.timestamp >= campaign.duration) revert();
        if(_amount == 0) revert();
        if(msg.sender == campaign.creator) revert();
        
        campaignAmounts[_id][_token] += _amount;
        contributions[_id][msg.sender][_token] += _amount;
        campaigns[_id].totalFundsCollected += _amount * IMyToken(_token).getTokenPriceInUSD();

        IMyToken(_token).transferFrom(msg.sender, address(this), _amount); 
    }

    /**
     * @dev cancelContribution allows anyone to cancel their contribution
     * @param _id the id of the campaign
     */
    function cancelContribution(uint256 _id) external {
        uint256 count = tokens.length;
        uint256 k;
        Campaign storage campaign = campaigns[_id];
        if(campaign.duration <= block.timestamp) revert();
        for(uint256 i; i < count; i++){
            address token = tokens[i];
            uint256 amount = contributions[_id][msg.sender][token];
            if(amount > 0){
              contributions[_id][msg.sender][token] = 0;
              campaign.totalFundsCollected -= amount;
              campaignAmounts[_id][token] -= amount;
              k += amount ;
              IMyToken(token).transfer(msg.sender, amount);
            }
        }
        if(k == 0) revert();
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
        if(campaign.goal > campaign.totalFundsCollected) revert();
        campaigns[_id].goal = 0;
        
        for(uint256 i; i < tokens.length; i++){
          address token = tokens[i];
          uint256 amount = campaign.totalFundsCollected;
          if(amount > 0){
            campaigns[_id].totalFundsCollected = 0;
            campaignAmounts[_id][token] = 0;
            IMyToken(token).transfer( campaign.creator , campaign.totalFundsCollected);
          }
          
        }
    }

    /**
     * @notice refund allows the contributors to get a refund if the campaign failed
     * @param _id the id of the campaign
     */
    function refund(uint256 _id) external {
        uint256 count = tokens.length;
        uint256 k;
        Campaign storage campaign = campaigns[_id];
        if(campaign.duration > block.timestamp) revert();
        if(campaign.goal <= campaign.totalFundsCollected) revert();
        for(uint256 i; i < count; i++){
            address token = tokens[i];
            uint256 amount = contributions[_id][msg.sender][token];
            if(amount > 0){
              contributions[_id][msg.sender][token] = 0;
              campaign.totalFundsCollected -= amount;
              campaignAmounts[_id][token] -= amount;
              k += amount ;
              IMyToken(token).transfer(msg.sender, amount);
            }
        }
        if(k == 0) revert();
    }

    /**
     * @notice getContribution returns the contribution of a contributor in USD
     * @param _id the id of the campaign
     * @param _contributor the address of the contributor
     */
    function getContribution(uint256 _id, address _contributor) public view returns (uint256) {
        if(_id > campaignIds) revert();
        uint256 a;
        for(uint256 i; i < tokens.length;i++){
            address token = tokens[i];
            uint256 amount = contributions[_id][_contributor][token];
            if(amount > 0){
              a += amount * IMyToken(token).getTokenPriceInUSD();
            }
        }
        return a;
    }
		
		/**
		 * @notice getCampaign returns details about a campaign
		 * @param _id the id of the campaign
		 * @return remainingTime the time (in seconds) remaining for the campaign
		 * @return goal the goal of the campaign (in USD)
		 * @return totalFunds total funds (in USD) raised by the campaign
		 */
    function getCampaign(uint256 _id)
        external
        view
        returns (uint256 remainingTime, uint256 goal, uint256 totalFunds) {
            address token = tokens[0];
            if(_id > campaignIds) revert();
            Campaign memory campaign = campaigns[_id];
            if(campaign.duration > block.timestamp){
              remainingTime = campaign.duration - block.timestamp ;
            }else{
                remainingTime = 0;
            } 
            goal = campaign.goal;
            totalFunds = campaign.totalFundsCollected * IMyToken(token).getTokenPriceInUSD(); 
        }

    function isTokenValid( address[] memory _tokens, address _token) private pure returns(bool){
        for(uint256 i; i < _tokens.length; ){
            if(_token == _tokens[i]){
               return true;
            }
            unchecked {i++;}
        }
        return false;
    }    
}