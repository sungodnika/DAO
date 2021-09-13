// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {ComicToken} from "./ComicToken.sol";

contract ComicICO {

    ComicToken public cmcToken;

    uint public totalRaised;
    mapping(address => uint256) public contributions;

    constructor() {
        cmcToken = new ComicToken();
    }

    receive() external payable {
        revert("Please call contribute()");
    }

    // events
    event Contribute(address contributer, uint amount);
    event RedeemedCoins(address redeemer, uint amount);
    event Withdraw(address withdrawer, uint amount);
    
    function contribute() payable external {
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
        emit Contribute(msg.sender, msg.value);
    }

    function redeemComicToken() external {
        require(contributions[msg.sender]>0, "Not part of the ICO");
        uint comicToken = contributions[msg.sender] * 5;
        contributions[msg.sender] = 0;
        cmcToken.mint(msg.sender, comicToken);
        emit RedeemedCoins(msg.sender, comicToken);
    } 

    function _withdraw(address _to, uint amount) internal returns(bool) {
        require(totalRaised > amount, 'Out of funds');
        totalRaised-=amount;
        (bool success, ) = _to.call{value: amount}("");
        if(success) {
        emit Withdraw(_to, amount);
        }
        require(success, 'fund transfer failed');
        return success;
    }

    function getComicToken() external view returns(ComicToken) {
        return cmcToken;
    }
}