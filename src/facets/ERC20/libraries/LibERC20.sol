// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibERC20{
    bytes32 constant ERC20_STORAGE_POSITION = keccak256("diamond.standard.erc20.storage");
    
    struct ERC20_Storage{
        uint256 totalSupply;
        string name;
        string symbol;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    function erc20Storage() internal pure returns (ERC20_Storage storage es){
        bytes32 storagePosition = ERC20_STORAGE_POSITION;
        assembly{
            es.slot := storagePosition
        }
    }

    // Storage Accessors (getName, getSymbol, _setName, _setSymbol) ... (omitted for brevity)

    // Core ERC-20 Logic Functions (Same as previous response)
    function _totalSupply() internal view returns (uint256) {
        return erc20Storage().totalSupply;
    }

    function _balanceOf(address account) internal view returns (uint256) {
        return erc20Storage().balances[account];
    }

    function _allowance(address owner, address spender) internal view returns (uint256) {
        return erc20Storage().allowances[owner][spender];
    }
    //symbol and name getters/setters
    function getName() internal view returns (string memory) {
        return erc20Storage().name;
    }
    function setName(string memory _name) internal {
        erc20Storage().name = _name;
    }
    function setSymbol(string memory _symbol) internal {
        erc20Storage().symbol = _symbol;
    }
    function getSymbol() internal view returns (string memory) {
        return erc20Storage().symbol;
    }

    // Internal ERC-20 Logic Implementations
    function _mint(address to, uint256 amount) internal {
        // ... (Mint logic without event emission)
        require(to != address(0), "ERC20: mint to the zero address");
        ERC20_Storage storage es = erc20Storage();
        es.totalSupply += amount;
        es.balances[to] += amount;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        // ... (Transfer logic without event emission)
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        ERC20_Storage storage es = erc20Storage();
        require(es.balances[from] >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            es.balances[from] -= amount;
        }
        es.balances[to] += amount;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        // ... (Approve logic without event emission)
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        erc20Storage().allowances[owner][spender] = amount;
    }
    
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        // ... (SpendAllowance logic)
        uint256 currentAllowance = _allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}