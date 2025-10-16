// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenVault {
    mapping(address => uint256) public balances;
    uint256 public totalValue;

    // A simple, unoptimized deposit function
    function deposit(uint256 amount) public payable {
        require(msg.value == amount, "Must send exact ETH amount");
        balances[msg.sender] += amount;
        totalValue += amount;
        // ... imagine logic for interacting with a separate ERC20 token here
    }

    // A slightly complex function for optimization comparison
    function _transferEth(address recipient, uint256 amount) internal {
        // Option 1: Low-level call (more gas efficient for simple transfers)
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    function withdrawOptimized(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        totalValue -= amount;
        _transferEth(msg.sender, amount); // Uses the optimized internal transfer
    }
    // In src/TokenVault.sol
function withdrawUnoptimized(uint256 amount) public {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    balances[msg.sender] -= amount;
    totalValue -= amount;
    // Less gas-efficient way (e.g., using transfer, which forwards a fixed amount of gas)
    // The previous 'withdrawOptimized' uses call, which is typically cheaper for simple transfers
    payable(msg.sender).transfer(amount); 
}
}