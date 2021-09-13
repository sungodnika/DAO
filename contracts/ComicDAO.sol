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

    // events
    event ProposedSketch(string sketchlink, address writer, uint pageNumber);
    event ProposedDrawing(string drawlink, string sketchlink, address artist, uint pageNumber);
    event ApprovedSketch(string sketchlink, address writer, uint pageNumber);
    event ApprovedDrawing(string drawlink, string sketchlink, address artist, uint pageNumber);

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

    function withdraw(address _to, uint amount) external onlyMajorGovernor returns(bool) {
        return _withdraw(_to, amount);
    }

    function proposePageSketches(string calldata sketchLink) external {
        require(sketchesToWriter[sketchLink] == address(0), "sketch already submitted");
        require(writers[msg.sender] || cmcToken.balanceOf(msg.sender)>0, "Only approved writers or community members can submit page sketches");
        sketchesToWriter[sketchLink] = msg.sender;
        emit ProposedSketch(sketchLink, msg.sender, getPageNumber());
    }

    function proposeDrawings(string calldata sketchLink, string calldata drawingLink) external {
        require(drawingsToArtist[drawingLink] == address(0), "drawing already submitted");
        require(artists[msg.sender], "Only approved artists can submit page sketches");
        require(approvedSketches[sketchLink], "Only approved sketches can have drawings");
        drawingsToSketches[drawingLink] = sketchLink;
        drawingsToArtist[drawingLink] = msg.sender;
        emit ProposedDrawing(drawingLink, sketchLink, msg.sender, getPageNumber());
    }

    // page sketches can only be approved by a major governor, payment decided by the governor
    function approvePageSketches(string calldata sketchLink, uint payment) external onlyMajorGovernor {
        require(!approvedSketches[sketchLink], "Sketch is already approved");
        approvedSketches[sketchLink] = true;
        pendingPayments[sketchesToWriter[sketchLink]] += payment;
        emit ApprovedSketch(sketchLink, msg.sender, getPageNumber());
    }

    // drawings can only be approved by a major governor, payment decided by the governor
    function approveDrawings(string calldata sketchLink, string calldata drawingLink, uint payment) external onlyMajorGovernor {
        require(approvedSketches[sketchLink], "Sketch should already be approved");
        require(compareStrings(drawingsToSketches[drawingLink], sketchLink), "drawingLink is not for the sketch");
        pendingPayments[drawingsToArtist[drawingLink]] += payment;
        approvedComics.push(drawingLink);
        emit ApprovedDrawing(drawingLink, sketchLink, msg.sender, getPageNumber());
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

    function getPageNumber() public view returns (uint) {
        return approvedComics.length + 1;
    }

    function getMajorGovernor() public view returns (IGovernor) {
        return majorGovernor;
    }
    function getMinorGovernor() public view returns (IGovernor) {
        return minorGovernor;
    }

}