// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CrowdFundEasy} from "../src/CrowdFundEasy.sol";
import {MyToken} from "../src/MyToken.sol";

contract CrowdFundEasyTest is Test {
    CrowdFundEasy public crowdFundEasy;
    MyToken public token;
    address contributor;   
    

    function setUp() public {
        token = new MyToken("MyToken","MTK" , 2);
        crowdFundEasy = new CrowdFundEasy(address(token));
        contributor = address(9);
        token.mint(contributor , 5);
    }

    function testCreateCampaign() public {
        address user = address(1);
        vm.prank(user);
        crowdFundEasy.createCampaign(4, 4 days);

       CrowdFundEasy.Campaign memory campaign = crowdFundEasy.fetchCampaignDetails(1);
       skip(1 days);
       assertEq(campaign.duration - 3 days , block.timestamp);
       assertEq(campaign.creator , user);
       assertEq(campaign.goal , 4 );
       assertEq(campaign.totalFundsCollected , 0 );
    }

    function testCreateMultipleCampaigns() public {
        address user1 = address(1);
        address user2 = address(2);

        vm.prank(user1);
        crowdFundEasy.createCampaign(4, 4 days);

        vm.prank(user2);
        crowdFundEasy.createCampaign(3, 2 days);

        assertEq(crowdFundEasy.fetchTotalCampaignIds() , 2);
    }


    function testContribute() public {
        address user = address(1);

        vm.prank(user);
        crowdFundEasy.createCampaign(4, 4 days);
        
        skip(100);
        vm.startPrank(contributor);
        token.approve(address(crowdFundEasy), 1);
        assertEq(token.allowance(contributor, address(crowdFundEasy)), 1);

        crowdFundEasy.contribute(1, 1);
        vm.stopPrank();
    }

    function testFailContributeTimeUp() public {
        address user = address(1);

        vm.prank(user);
        crowdFundEasy.createCampaign(4, 4 days);
        
        skip(4 days);
        vm.startPrank(contributor);
        token.approve(address(crowdFundEasy), 1);
        assertEq(token.allowance(contributor, address(crowdFundEasy)), 1);

        crowdFundEasy.contribute(1, 3);
        vm.stopPrank();
    }

    function testCancelContribution() public {
        address user = address(1);

        vm.prank(user);
        crowdFundEasy.createCampaign(4, 4 days);
        
        skip(100);
        vm.startPrank(contributor);
        token.approve(address(crowdFundEasy), 1);
        assertEq(token.allowance(contributor, address(crowdFundEasy)), 1);

        crowdFundEasy.contribute(1, 1);
        
        skip(1 days);
        crowdFundEasy.cancelContribution(1);
        vm.stopPrank();
    }

    function testWithdrawFunds() public {
        address user = address(1);

        vm.prank(user);
        crowdFundEasy.createCampaign(4, 4 days);
        
        skip(1 days);
        vm.startPrank(contributor);
        token.approve(address(crowdFundEasy), 2);
        assertEq(token.allowance(contributor, address(crowdFundEasy)), 2);

        crowdFundEasy.contribute(1, 2);
        vm.stopPrank();
        
        skip(3 days);
        vm.prank(user);
        crowdFundEasy.withdrawFunds(1);
    } 

    function testRefunds() public {
        address user = address(1);

        vm.prank(user);
        crowdFundEasy.createCampaign(4, 4 days);
        
        skip(1 days);
        vm.startPrank(contributor);
        token.approve(address(crowdFundEasy), 1);
        assertEq(token.allowance(contributor, address(crowdFundEasy)), 1);

        crowdFundEasy.contribute(1, 1);

        skip(3 days);
        crowdFundEasy.refund(1);
        vm.stopPrank();
    } 

}
