// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Internal dependencies for access control and reusable logic
import "./libraries/LibERC20.sol";
import "./_ERC20.sol"; // NEW: Import the internal logic contract

// Ownership interface kept for type-compatibility in Diamond setup

// Events for configuration changes
event CurrencyNameChanged(string name);
event CurrencySymbolChanged(string name);

// The facet now inherits the reusable logic and access control interfaces
contract ERC20Facet is ERC20 {
    // Assuming Ownable/LibOwnership provides the onlyOwner modifier
    // Note: Ownable is typically included here to use the 'onlyOwner' modifier
    // If your diamond manages ownership externally, you may need a different access pattern.

    // ------------------- Configuration Functions -------------------

    function setCurrencyName(string memory _name) external onlyOwner {
        LibERC20.setName(_name); 
        emit CurrencyNameChanged(_name);
    }

    function setCurrencySymbol(string memory _symbol) external onlyOwner {
        LibERC20.setSymbol(_symbol);
        emit CurrencySymbolChanged(_symbol);
    }

    // ------------------- External ERC-20 View Functions -------------------

    function name() external view returns (string memory) {
        return LibERC20.getName(); 
    }

    function symbol() external view returns (string memory) {
        return LibERC20.getSymbol();
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        // Uses the internal helper from ERC20Internal (which uses LibERC20)
        return _totalSupply();
    }

    function balanceOf(address account) external view returns (uint256) {
        // Uses the internal helper
        return _balanceOf(account);
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        // Uses the internal helper
        return _allowance(owner, spender);
    }

    // ------------------- External ERC-20 State-Changing Functions -------------------

    function mint(address to, uint256 amount) external onlyOwner {
        // Calls the internal mint logic with event emission
        _mint(to, amount);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool) {
        // Calls the internal transfer logic with event emission
        _transfer(msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        // Calls the internal approve logic with event emission
        _approve(msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        // Calls the internal transferFrom logic (which handles allowance and transfer)
        _transferFrom(sender, recipient, amount);
        return true;
    }

    // Internal function for 'permit' if implemented later, using internal logic
    function approvePermit(
        address owner,
        address spender,
        uint256 amount
    ) internal returns (bool) {
        _approve(owner, spender, amount);
        return true;
    }
}
