pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ERC20Token is ERC20 {
    uint256 public currentTokenId;

    constructor(string memory _name, string memory _symbol
    ) ERC20(_name, _symbol) {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}