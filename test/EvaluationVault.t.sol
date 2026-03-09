// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/EvictionVault.sol";

contract EvictionVaultTest is Test {

    EvictionVault vault;

    address owner1;
    address owner2;
    address user;

    function setUp() public {
        owner1 = makeAddr("owner1");
        owner2 = makeAddr("owner2");
        user = makeAddr("user");

        // ✅ Create a memory array of owners for constructor
        address[] memory owners = new address[](2);
        owners[0] = owner1;
        owners[1] = owner2;

        // Deploy the vault with the owners and threshold
        vault = new EvictionVault(owners, 2);

        // Fund addresses for testing
        vm.deal(owner1, 10 ether);
        vm.deal(owner2, 10 ether);
        vm.deal(user, 10 ether);
    }

    /* ------------------------------------------------------------ */
    /* Deposit Test */
    /* ------------------------------------------------------------ */
    function testDeposit() public {
        vm.prank(user);
        vault.deposit{value: 1 ether}();

        uint256 balance = vault.balances(user);
        assertEq(balance, 1 ether);
    }

    /* ------------------------------------------------------------ */
    /* Withdraw Test */
    /* ------------------------------------------------------------ */
    function testWithdraw() public {
        vm.startPrank(user);

        vault.deposit{value: 2 ether}();
        vault.withdraw(1 ether);

        vm.stopPrank();

        uint256 balance = vault.balances(user);
        assertEq(balance, 1 ether);
    }

    /* ------------------------------------------------------------ */
    /* Pause Test */
    /* ------------------------------------------------------------ */
    function testPause() public {
        vm.prank(owner1);
        vault.pause();

        bool paused = vault.paused();
        assertTrue(paused);
    }

    /* ------------------------------------------------------------ */
    /* Unpause Test */
    /* ------------------------------------------------------------ */
    function testUnpause() public {
        vm.startPrank(owner1);

        vault.pause();
        vault.unpause();

        vm.stopPrank();

        bool paused = vault.paused();
        assertTrue(!paused);
    }

    /* ------------------------------------------------------------ */
    /* Multisig Submit + Confirm */
    /* ------------------------------------------------------------ */
    function testSubmitAndConfirmTransaction() public {
        vm.prank(owner1);
        vault.submitTransaction(user, 1 ether, "");

        vm.prank(owner2);
        vault.confirmTransaction(0);

        (address to, uint256 value, , , uint256 confirmations, , uint256 executionTime) =
            vault.transactions(0);

        assertEq(to, user);
        assertEq(value, 1 ether);
        assertEq(confirmations, 2);
        assertTrue(executionTime > 0);
    }

    /* ------------------------------------------------------------ */
    /* Emergency Withdraw */
    /* ------------------------------------------------------------ */
    function testEmergencyWithdraw() public {
        vm.prank(user);
        vault.deposit{value: 1 ether}();

        vm.startPrank(owner1);

        vault.pause();

        uint256 beforeBalance = owner1.balance;

        vault.emergencyWithdrawAll();

        uint256 afterBalance = owner1.balance;

        vm.stopPrank();

        assertTrue(afterBalance > beforeBalance);
    }
}