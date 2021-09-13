// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {ComicToken} from "./ComicToken.sol";

contract ComicICO {
    enum Phase {
        SEED, 
        GENERAL, 
        OPEN
    }

    ComicToken public cmcToken;

    uint public totalRaised;
    mapping(address => uint256) public contributions;
    mapping(address => bool) public privateInvestors;
    Phase phase;

    constructor() {
        cmcToken = new ComicToken();
    }

    receive() external payable {
        revert("Please call contribute()");
    }

    // events
    event PhaseChanged(Phase newPhase);
    event Contribute(address contributer, uint amount);
    event RedeemedCoins(address redeemer, uint amount);
    event AddRemovePrivateInvestor(address privateInvestor, bool action);
    event Withdraw(address withdrawer, uint amount);


    function _addRemovePrivateInvestor(address privateInvestor, bool action) internal {
        require(privateInvestor != address(0), "address should be non zero");
        privateInvestors[privateInvestor] = action;
        emit AddRemovePrivateInvestor(privateInvestor, action);
    }

    function toGeneral() internal {
        require(phase == Phase.SEED, "Phase needs to be seed to advance to General");
        phase = Phase.GENERAL;
        emit PhaseChanged(phase);
    }

    function toOpen() internal {
        require(phase == Phase.GENERAL, "Phase needs to be general to advance to General");
        phase = Phase.OPEN;
        emit PhaseChanged(phase);
    }
    
    function contribute() payable external {
        if (phase == Phase.SEED) {
            require(privateInvestors[msg.sender] == true, "This phase is open only for private investors");
            require(contributions[msg.sender] + msg.value <= 1500 ether, "Contribution above individual threshold");
            require(totalRaised + msg.value <= 15000 ether, "Total contribution above threshold");
            contributions[msg.sender] += msg.value;
            totalRaised += msg.value;
            emit Contribute(msg.sender, msg.value);
        } else if(phase == Phase.GENERAL) {
            require(contributions[msg.sender] + msg.value <= 1000 ether, "Contribution above individual threshold");
            require(totalRaised + msg.value <= 30000 ether, "Total contribution above threshold");
            contributions[msg.sender] += msg.value;
            totalRaised += msg.value;
            emit Contribute(msg.sender, msg.value);
        } else if (phase == Phase.OPEN) {
            contributions[msg.sender] += msg.value;
            totalRaised += msg.value;
            emit Contribute(msg.sender, msg.value);
        }
    }

    function redeemComicToken() external {
        require(phase == Phase.OPEN, "ICO is not Open yet");
        require(contributions[msg.sender]>0, "Not part of the ICO");
        uint comicToken = contributions[msg.sender] * 5;
        contributions[msg.sender] = 0;
        cmcToken.mint(msg.sender, comicToken);
        emit RedeemedCoins(msg.sender, comicToken);
    } 

    function _withdraw(address _to, uint amount) internal returns(bool) {
        require(phase == Phase.OPEN, "The ICO is should be open");
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