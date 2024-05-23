// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC4626} from "lib/solmate/src/tokens/ERC4626.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract TokenVault is ERC4626 {
    address owner;
    address strategyContract;

    constructor(address _owner, address _strategyContract, ERC20 asset, string memory _name, string memory _symbol)
        ERC4626(asset, _name, _symbol)
    {
        strategyContract = _strategyContract;
        owner = _owner;
    }

    function depositShares(uint256 _assets) public {
        require(_assets > 0, "ZERO_ASSETS");
        deposit(_assets, msg.sender);
    }

    function withdrawShares(uint256 _shares) public {
        require(_shares > 0, "ZERO_SHARES");
        withdraw(_shares, msg.sender, msg.sender);
    }

    function totalAssets() public view override returns (uint256) {
        uint256 totalAssetsInStrategy = asset.balanceOf(strategyContract);
        uint256 totalAssetsInVault = asset.balanceOf(address(this));
        return totalAssetsInStrategy + totalAssetsInVault;
    }

    function totalSharesOfUser(address _user) public view returns (uint256) {
        return this.balanceOf(_user);
    }

    // hooks

    function beforeWithdraw(uint256 assets, uint256 shares) internal override {
        asset.transferFrom(strategyContract, address(this), assets);
    }

    function afterDeposit(uint256 assets, uint256 shares) internal override {
        asset.transfer(strategyContract, assets);
    }
}
