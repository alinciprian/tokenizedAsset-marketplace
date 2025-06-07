//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract AssetToken is ERC20, Ownable {
    /// The maximum amount of tokens that will ever be is 100, each representing 1% stake in the asset.
    uint256 public constant MAX_SUPPLY = 100 ether;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) Ownable(msg.sender) {
        _mint(msg.sender, MAX_SUPPLY);
    }

    function burnTokens() external onlyOwner {
        _burn(msg.sender, MAX_SUPPLY);
    }
}
