// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// For major decisions, quorum of 20% with quadratic and voting period of a week
contract ComicMajorGovernor is Governor, GovernorCountingSimple {
    address private owner;
    address token;
    
    constructor(address _token) Governor("ComicMajorGovernor")
    {
        owner = msg.sender;
        token = _token;
    }
    
    function sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    function votingPeriod() public pure override returns (uint256) {
        return 44772; // per week
    }

    function quorum(uint256 blockNumber) public view override returns (uint256) {
        return IERC20(token).totalSupply()/5; // minimum 20% of votes
    }

    function getVotes(address account, uint256 blockNumber) public view override returns (uint256)
    {
        return sqrt(IERC20(token).balanceOf(account));
    }
}