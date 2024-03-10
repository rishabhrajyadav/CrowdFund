// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CrowdFundHard} from "../src/CrowdFundHard.sol";
import {MyToken} from "../src/MyToken.sol";

contract CrowdFundHardTest is Test {
    CrowdFundHard public crowdFundHard;
    address contributor1;
    address contributor2;
    address contributor3;   
    address[] public tokens;

    function setUp() public {
        tokens.push() = address(new MyToken("MyToken1","MTK1" , 1));
        tokens.push() = address(new MyToken("MyToken2","MTK2" , 2));
        tokens.push() = address(new MyToken("MyToken3","MTK3" , 3));
        crowdFundHard = new CrowdFundHard(tokens);
        contributor1 = address(7);
        contributor2 = address(8);
        contributor3 = address(9);
        MyToken(tokens[0]).mint(contributor1 , 5);
        MyToken(tokens[1]).mint(contributor2 , 5);
        MyToken(tokens[2]).mint(contributor3 , 5);
    }

    function testCreateCampaign() public {
        address user = address(1);
        vm.prank(user);
        crowdFundHard.createCampaign(40, 4 days);

       CrowdFundHard.Campaign memory campaign = crowdFundHard.fetchCampaignDetails(1);
       skip(1 days);
       assertEq(campaign.duration - 3 days , block.timestamp);
       assertEq(campaign.creator , user);
       assertEq(campaign.goal , 40 );
       assertEq(campaign.totalFundsCollected , 0 );
    }

    function testCreateMultipleCampaigns() public {
        address user1 = address(1);
        address user2 = address(2);

        vm.prank(user1);
        crowdFundHard.createCampaign(4, 4 days);

        vm.prank(user2);
        crowdFundHard.createCampaign(3, 2 days);

        assertEq(crowdFundHard.fetchTotalCampaignIds() , 2);
    }

    function testContribute() public {
        address user = address(1);
        MyToken token = MyToken(tokens[0]);

        vm.prank(user);
        crowdFundHard.createCampaign(40, 4 days);
        
        skip(100);
        vm.startPrank(contributor1);
        (token).approve(address(crowdFundHard), 3);
        assertEq(token.allowance(contributor1, address(crowdFundHard)), 3);

        crowdFundHard.contribute(1, address(token) , 3);
        vm.stopPrank();
    }

    function testFailContributeTimeUp() public {
        address user = address(1);
        MyToken token = MyToken(tokens[0]);

        vm.prank(user);
        crowdFundHard.createCampaign(40, 4 days);
        
        skip(4 days);
        vm.startPrank(contributor1);
        token.approve(address(crowdFundHard), 3);
        assertEq(token.allowance(contributor1, address(crowdFundHard)), 3);

        crowdFundHard.contribute(1, address(token) , 3);
        vm.stopPrank();
    }

    function testCancelContribution() public {
        address user = address(1);
        MyToken token = MyToken(tokens[0]);

        vm.prank(user);
        crowdFundHard.createCampaign(4, 4 days);
        
        skip(100);
        vm.startPrank(contributor1);
        token.approve(address(crowdFundHard), 3);
        assertEq(token.allowance(contributor1, address(crowdFundHard)), 3);

        crowdFundHard.contribute(1, address(token) , 3);
        
        skip(1 days);
        crowdFundHard.cancelContribution(1);
        vm.stopPrank();
    }

    function testWithdrawFunds() public {
        address user = address(1);
        MyToken token = MyToken(tokens[0]);

        vm.prank(user);
        crowdFundHard.createCampaign(4, 4 days);
        
        skip(1 days);
        vm.startPrank(contributor1);
        token.approve(address(crowdFundHard), 4);
        assertEq(token.allowance(contributor1, address(crowdFundHard)), 4);

        crowdFundHard.contribute(1, address(token) , 4);
        vm.stopPrank();
        
        skip(3 days);
        vm.prank(user);
        crowdFundHard.withdrawFunds(1);
    } 

    function testRefunds() public {
        address user = address(1);
        MyToken token = MyToken(tokens[0]);

        vm.prank(user);
        crowdFundHard.createCampaign(4, 4 days);
        
        skip(1 days);
        vm.startPrank(contributor1);
        token.approve(address(crowdFundHard), 1);
        assertEq(token.allowance(contributor1, address(crowdFundHard)), 1);

        crowdFundHard.contribute(1, address(token) , 1);

        skip(3 days);
        crowdFundHard.refund(1);
        vm.stopPrank();
    } 


    function testContributeWithDifferentTokens() public {
        address user = address(1);
        MyToken token1 = MyToken(tokens[0]);
        MyToken token2 = MyToken(tokens[1]);
        token2.mint(contributor1 , 5);

        vm.prank(user);
        crowdFundHard.createCampaign(10, 4 days);

        skip(1 days);
        vm.startPrank(contributor1);
        token1.approve(address(crowdFundHard), 4);
        assertEq(token1.allowance(contributor1, address(crowdFundHard)), 4);

        crowdFundHard.contribute(1, address(token1) , 4);

        skip(2 days);
        token2.approve(address(crowdFundHard), 3);
        assertEq(token2.allowance(contributor1, address(crowdFundHard)), 3);
        crowdFundHard.contribute(1, address(token2) , 3);

        vm.stopPrank();

        CrowdFundHard.Campaign memory campaign = crowdFundHard.fetchCampaignDetails(1);
        assertEq(campaign.totalFundsCollected , 10);
        assertEq(campaign.totalFundsCollected , campaign.goal);
    }

     function testCancelContributeWithDifferentTokens() public {
        address user = address(1);
        MyToken token1 = MyToken(tokens[0]);
        MyToken token2 = MyToken(tokens[1]);
        token2.mint(contributor1 , 5);

        vm.prank(user);
        crowdFundHard.createCampaign(10, 4 days);

        skip(1 days);
        vm.startPrank(contributor1);
        token1.approve(address(crowdFundHard), 4);
        assertEq(token1.allowance(contributor1, address(crowdFundHard)), 4);
        crowdFundHard.contribute(1, address(token1) , 4);

        skip(1 days);
        token2.approve(address(crowdFundHard), 3);
        assertEq(token2.allowance(contributor1, address(crowdFundHard)), 3);
        crowdFundHard.contribute(1, address(token2) , 3);

        CrowdFundHard.Campaign memory campaign = crowdFundHard.fetchCampaignDetails(1);
        assertEq(campaign.totalFundsCollected , 10);
        assertEq(token1.balanceOf(address(crowdFundHard)) , 4);
        assertEq(token2.balanceOf(address(crowdFundHard)) , 3);
        
        skip(1 days);
        crowdFundHard.cancelContribution(1);

        vm.stopPrank();

        assertEq(token1.balanceOf(contributor1) , 5);
        assertEq(token2.balanceOf(contributor1) , 5);
    }

}