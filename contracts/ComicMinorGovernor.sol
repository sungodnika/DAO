// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// For minor decisions, simple voting no quorum and voting period of a day
contract ComicMinorGovernor is GovernorCountingSimple {
    address private owner;
    address token;
    
    constructor(address _token) Governor("ComicMinorGovernor")
    {
        owner = msg.sender;
        token = _token;
    }

    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    function votingPeriod() public pure override returns (uint256) {
        return 6396; // per day
    }

    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 1;
    }

    function getVotes(address account, uint256 blockNumber) public view override returns (uint256)
    {
        if(IERC20(token).balanceOf(account)>0) {
            return 1;
        } else {
            return 0;
        }
    }
}