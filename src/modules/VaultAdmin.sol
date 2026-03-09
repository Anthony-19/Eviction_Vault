// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/modules/VaultModifiers.sol";

contract VaultAdmin is VaultModifiers {

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function emergencyWithdrawAll()
        external
        onlyOwner
    {
        require(paused, "must pause first");

        uint256 balance = address(this).balance;

        (bool success,) = payable(msg.sender).call{value: balance}("");

        require(success, "withdraw failed");

        totalVaultValue = 0;
    }
}