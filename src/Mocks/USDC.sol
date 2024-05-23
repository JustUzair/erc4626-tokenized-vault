// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract USDC is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, 6) {}

    function mint(address receiver, uint256 amount) public {
        _mint(receiver, amount * 1e6);
    }
}
