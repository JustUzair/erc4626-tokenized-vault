// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {TokenVault} from "../src/TokenVault.sol";
import {USDC} from "../src/Mocks/USDC.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract TokenVaultTest is Test {
    TokenVault vault;
    USDC usdc;
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    address aaveStrategy = makeAddr("aave");

    uint256 constant STARTING_BALANCE = 10000;

    function setUp() public {
        usdc = new USDC("USDC", "USDC");
        vault = new TokenVault(owner, aaveStrategy, usdc, "TokenVault", "TV");

        usdc.mint(user1, 50);
        usdc.mint(user2, 50);
        usdc.mint(user3, 50);

        vm.deal(user1, STARTING_BALANCE);
        vm.deal(user2, STARTING_BALANCE);
        vm.deal(user2, STARTING_BALANCE);

        vm.prank(address(vault));
        usdc.approve(aaveStrategy, 1000e6);
    }

    function test_depositAssets() public depositUSDCAsUser1 {
        assertEq(vault.totalAssets(), 10e6);
        assertEq(vault.totalSharesOfUser(user1), 10e6);
    }

    function test_withdrawShares() public depositUSDCAsUser1 withdrawSharesAsUser1 {
        assertEq(vault.totalAssets(), 0);
        assertEq(vault.totalSharesOfUser(user1), 0);
    }

    function test_afterDeposit() public depositUSDCAsUser1 depositUSDCAsUser2 {
        uint256 usdcBalanceOfVault = usdc.balanceOf(address(vault));
        uint256 usdcBalanceOfStrategy = usdc.balanceOf(address(aaveStrategy));

        assertEq(usdcBalanceOfVault, 0);
        assertEq(usdcBalanceOfStrategy, 16e6);
    }

    // ------------------ No strategy ------------------
    function test_noStrategyPreviewRedeem() public depositUSDCAsUser1 {
        uint256 sharesToAssets = vault.previewRedeem(10e6);
        assertEq(sharesToAssets, 10e6);
    }

    // ------------------ Test strategy ------------------
    function test_strategyPreviewRedeem() public depositUSDCAsUser1 {
        //    user 1 deposited 10e6
        vm.startPrank(user2);
        usdc.approve(address(vault), 10e6);
        usdc.transfer(address(vault), 10e6); // user2 puts in 10e6 without minting shares
        // this changes ratio to : 20e6 USDC / 10e6 shares, 2:1
        vm.stopPrank();
        uint256 sharesToAssets = vault.previewRedeem(10e5);
        assertEq(sharesToAssets, 20e5);
    }

    // ------------------ Test zero address & aave strategy ------------------

    function test_zeroAddressStrategyPreviewRedeem() public depositUSDCAsUser1 depositUSDCAsUser2 depositUSDCAsUser3 {
        vm.startPrank(address(vault));
        usdc.transfer(address(0), 5e4);
        vm.stopPrank();

        uint256 maxWithdrawalForUser1 = vault.maxWithdraw(user1);
        console.log("maxWithdrawalForUser1", maxWithdrawalForUser1);

        uint256 maxWithdrawalForUser2 = vault.maxWithdraw(user2);
        console.log("maxWithdrawalForUser2", maxWithdrawalForUser2);

        uint256 maxWithdrawalForUser3 = vault.maxWithdraw(user3);
        console.log("maxWithdrawalForUser3", maxWithdrawalForUser3);

        uint256 totalMaxWithdrawal = maxWithdrawalForUser1 + maxWithdrawalForUser2 + maxWithdrawalForUser3;
        console.log("totalMaxWithdrawal", totalMaxWithdrawal);
    }

    function test_aaveStrategyPreviewRedeem() public depositUSDCAsUser1 depositUSDCAsUser2 depositUSDCAsUser3 {
        uint256 maxWithdrawalForUser1 = vault.maxWithdraw(user1);
        console.log("maxWithdrawalForUser1", maxWithdrawalForUser1);

        uint256 maxWithdrawalForUser2 = vault.maxWithdraw(user2);
        console.log("maxWithdrawalForUser2", maxWithdrawalForUser2);

        uint256 maxWithdrawalForUser3 = vault.maxWithdraw(user3);
        console.log("maxWithdrawalForUser3", maxWithdrawalForUser3);

        uint256 totalMaxWithdrawal = maxWithdrawalForUser1 + maxWithdrawalForUser2 + maxWithdrawalForUser3;
        console.log("totalMaxWithdrawal", totalMaxWithdrawal);
    }

    // ------------------ Helper modifiers ------------------

    modifier depositUSDCAsUser1() {
        vm.startBroadcast(user1);
        usdc.approve(address(vault), 10e6);
        vault.depositShares(10e6);
        vm.stopBroadcast();
        _;
    }

    modifier withdrawSharesAsUser1() {
        vm.startBroadcast(user1);
        vault.withdrawShares(10e6);
        vm.stopBroadcast();
        _;
    }

    modifier depositUSDCAsUser2() {
        vm.startBroadcast(user2);
        usdc.approve(address(vault), 6e6);
        vault.depositShares(6e6);
        vm.stopBroadcast();
        _;
    }

    modifier withdrawSharesAsUser2() {
        vm.startBroadcast(user2);
        vault.withdrawShares(6e6);
        vm.stopBroadcast();
        _;
    }

    modifier depositUSDCAsUser3() {
        vm.startBroadcast(user3);
        usdc.approve(address(vault), 24e6);
        vault.depositShares(24e6);
        vm.stopBroadcast();
        _;
    }

    modifier withdrawSharesAsUser3() {
        vm.startBroadcast(user3);
        vault.withdrawShares(24e6);
        vm.stopBroadcast();
        _;
    }
}
