// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/LibERC20.sol";
import {iOwnership} from "../Ownership/_Ownership.sol";

// Standard ERC-20 Events
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

// Internal contract containing reusable ERC-20 logic with event emission
 contract ERC20 is iOwnership {
    
    // Core ERC-20 Reusable Logic
    // These functions use LibERC20 and emit the necessary standard events.
    
    function _mint(address to, uint256 amount) internal {
        LibERC20._mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        LibERC20._transfer(from, to, amount);
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        LibERC20._approve(owner, spender, amount);
        emit Approval(owner, spender, amount);
    }
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal {
        // 1. Spend the allowance from the sender to the caller (which is msgSender() from Context)
        LibERC20._spendAllowance(sender, msgSender(), amount); 
        
        // 2. Perform the transfer
        _transfer(sender, recipient, amount);
    }

    function _balanceOf(address account) internal view returns (uint256) {
        return LibERC20._balanceOf(account);
    }
    
    function _allowance(address owner, address spender) internal view returns (uint256) {
        return LibERC20._allowance(owner, spender);
    }
    
    function _totalSupply() internal view returns (uint256) {
        return LibERC20._totalSupply();
    }
}