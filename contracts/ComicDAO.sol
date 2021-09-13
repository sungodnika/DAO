// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {ComicToken} from "./ComicToken.sol";
import {ComicICO} from "./ComicICO.sol";
import {ComicMajorGovernor} from "./ComicMajorGovernor.sol";
import {ComicMinorGovernor} from "./ComicMinorGovernor.sol";
import "@openzeppelin/contracts/governance/IGovernor.sol";

contract ComicDAO is ComicICO {

    mapping(address => bool) public writers;
    mapping(address => bool) public artists;
    mapping(address => uint) public pendingPayments;

    mapping(string => address) public sketchesToWriter;
    mapping(string => address) public drawingsToArtist;

    mapping(string => bool) public approvedSketches;
    mapping(string => string) public drawingsToSketches;

    string[] approvedComics;

    IGovernor private majorGovernor;
    IGovernor private minorGovernor;

    constructor() ComicICO() {
        majorGovernor = new ComicMajorGovernor(address(cmcToken));
        minorGovernor = new ComicMinorGovernor(address(cmcToken));
    }

    modifier onlyMajorGovernor() {
        require(msg.sender == address(majorGovernor), "Needs to be the major governor");
        _;
    }

    modifier onlyMinorGovernor() {
        require(msg.sender == address(minorGovernor), "Needs to be the minor governor");
        _;
    }


    function addWriter(address _writer) external onlyMinorGovernor {
        writers[_writer] = true;
    }

    function addArtist(address _artist) external onlyMinorGovernor {
        artists[_artist] = true;
    }

    function toGeneralPhase() external onlyMajorGovernor {
        toGeneral();
    }

    function toOpenPhase() external onlyMajorGovernor {
        toOpen();
    }
    function addRemovePrivateInvestor(address privateInvestor, bool action) external onlyMajorGovernor {
        _addRemovePrivateInvestor(privateInvestor, action);
    }
    function withdraw(address _to, uint amount) external onlyMajorGovernor returns(bool) {
        return _withdraw(_to, amount);
    }

    function proposePageSketches(string calldata sketchLink) external {
        require(msg.sender != address(0));
        require(sketchesToWriter[sketchLink] == address(0), "sketch already submitted");
        require(writers[msg.sender], "Only approved writers can submit page sketches");
        require(!approvedSketches[sketchLink], "sketch is already approved");
        sketchesToWriter[sketchLink] = msg.sender;
        approvedSketches[sketchLink] = false;
    }

    function proposeDrawings(string calldata sketchLink, string calldata drawingLink) external {
        require(msg.sender != address(0));
        require(drawingsToArtist[drawingLink] == address(0), "drawing already submitted");
        require(artists[msg.sender], "Only approved artists can submit page sketches");
        require(approvedSketches[sketchLink], "Only approved sketches can have drawings");
        require(compareStrings(drawingsToSketches[drawingLink],""), "sketch already has a drawing linked");
        drawingsToSketches[drawingLink] = sketchLink;
        drawingsToArtist[drawingLink] = msg.sender;
    }

    // page sketches can only be approved by a major governor, payment decided by the governor
    function approveRejectPageSketches(string calldata sketchLink, uint payment, bool approve) external onlyMajorGovernor {
        require(!approvedSketches[sketchLink], "Sketch is already approved");
        approvedSketches[sketchLink] = approve;
        if(approve) {
            pendingPayments[sketchesToWriter[sketchLink]] += payment;
        }
    }

    // drawings can only be approved by a major governor, payment decided by the governor
    function approveDrawings(string calldata sketchLink, string calldata drawingLink, uint payment, bool approve) external onlyMajorGovernor {
        require(approvedSketches[sketchLink], "Sketch should already be approved");
        require(compareStrings(drawingsToSketches[drawingLink], sketchLink), "drawingLink is not for the sketch");
        if (approve){
            pendingPayments[drawingsToArtist[drawingLink]] += payment;
            approvedComics.push(drawingLink);
        } else {
            drawingsToSketches[drawingLink] = "";
        }
    }

    function claimPayment() external {
        require(artists[msg.sender] || writers[msg.sender], "Needs to be an artist or writer to claim payment");
        require(pendingPayments[msg.sender]>0, "No pending payments");
        uint amount = pendingPayments[msg.sender];
        pendingPayments[msg.sender] = 0;
        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "Payment Failed");
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

}