// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "src/modules/VaultModifiers.sol";

contract VaultClaims is VaultModifiers {

    event Claim(address indexed claimant, uint256 amount);
    event MerkleRootSet(bytes32 indexed newRoot);

    function setMerkleRoot(bytes32 root) external onlyOwner {

        require(root != bytes32(0), "invalid root");

        merkleRoot = root;

        emit MerkleRootSet(root);
    }

    function claim(bytes32[] calldata proof, uint256 amount)
        external
        notPaused
    {

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));

        bytes32 computed = MerkleProof.processProof(proof, leaf);

        require(computed == merkleRoot, "invalid proof");

        require(!claimed[msg.sender], "already claimed");

        claimed[msg.sender] = true;

        (bool success,) = payable(msg.sender).call{value: amount}("");

        require(success, "claim failed");

        totalVaultValue -= amount;

        emit Claim(msg.sender, amount);
    }
}