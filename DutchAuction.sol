// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC721A.sol";
import "./Ownable.sol";

contract DutchAuction is ERC721A, Ownable {

    //constant
    uint256 public constant MAX_TOTAL = 10000;
    uint256 public constant AUCTION_START_PRICE = 1 ether;
    uint256 public constant AUCTION_END_PRICE = 0.1 ether;
    uint256 public constant AUCTION_TIME = 10 minutes;
    uint256 public constant AUCTION_DROP_INTERVAL = 1 minutes;
    uint256 public constant AUCTION_DROP_PER_STEP = (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_TIME / AUCTION_DROP_INTERVAL);

    uint256 public auctionStartTime;
    string baseTokenURI;

    constructor(string memory _initBaseURI) ERC721A("RedCat", "RCN") {
        auctionStartTime = block.timestamp;
        setBaseURI(_initBaseURI);
    }

    function auctionMint(uint256 quantity) external payable {
        require(auctionStartTime != 0 && block.timestamp >= auctionStartTime, "not yet started");
        require(totalSupply() + quantity <= MAX_TOTAL,"exceed the maximum amount");

        uint256 totalCost = getAuctionPrice() * quantity;
        require(msg.value >= totalCost, "not enough BNB");

        _mint(msg.sender, quantity);
        
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    //onlyOwner
    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "transfer failed");
    }

    function setAuctionStartTime(uint32 timestamp) external onlyOwner {
        auctionStartTime = timestamp;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function getAuctionPrice() public view returns (uint256) {
        if(block.timestamp < auctionStartTime) {
            return AUCTION_START_PRICE;
        } else if(block.timestamp - auctionStartTime >= AUCTION_TIME) {
            return AUCTION_END_PRICE;
        } else {
            uint256 steps = (block.timestamp - auctionStartTime) / AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

}