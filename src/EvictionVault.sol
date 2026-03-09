// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/modules/VaultStorage.sol";
import "src/modules/VaultMultisig.sol";
import "src/modules/VaultClaims.sol";
import "src/modules/VaultAdmin.sol";

contract EvictionVault is
    VaultMultisig,
    VaultClaims,
    VaultAdmin
{

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);

    constructor(address[] memory _owners, uint256 _threshold) payable {

        require(_owners.length > 0, "no owners");

        threshold = _threshold;

        for (uint i; i < _owners.length; i++) {

            address owner = _owners[i];

            require(owner != address(0));

            isOwner[owner] = true;

            owners.push(owner);
        }

        totalVaultValue = msg.value;
    }

    receive() external payable {

        balances[msg.sender] += msg.value;

        totalVaultValue += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable {

        balances[msg.sender] += msg.value;

        totalVaultValue += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount)
        external
        notPaused
    {
        require(balances[msg.sender] >= amount, "insufficient");

        balances[msg.sender] -= amount;

        totalVaultValue -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");

        require(success, "withdraw failed");

        emit Withdrawal(msg.sender, amount);
    }
}