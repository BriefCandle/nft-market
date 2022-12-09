// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// import "solmate/tokens/ERC721.sol";
import "./BidAndAsk.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract NFT is BidAndAsk {
    uint256 public currentTokenId;

    constructor(string memory _name, string memory _symbol
    ) ERC721(_name, _symbol) {}

    function mintTo(address recipient) public payable returns (uint256) {
        uint256 newItemId = ++currentTokenId;
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return Strings.toString(id);
    }
}
