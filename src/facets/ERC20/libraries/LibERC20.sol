pragma solidity ^0.8.6;

library LibERC20{
    uint256 public constant PRIMARY_CURRENCY_ID = 0; 
    bytes32 constant ERC20_STORAGE_POSITION = keccak256("diamond.standard.erc20.storage");
    struct ERC20_Storage{
        uint256 totalSupply;
        string name;
        string symbol;
    }

    function erc20Storage() internal pure returns (ERC20_Storage storage es){
        bytes32 ERC20_STORAGE_POSITION = ERC20_STORAGE_POSITION;
        assembly{
            es.slot := ERC20_STORAGE_POSITION
        }
    }

    function _setName(string memory _name) internal{
        ERC20_Storage storage es = erc20Storage();
        es.name = _name;
    }
    function _setSymbol(string memory _symbol) internal{
        ERC20_Storage storage es = erc20Storage();
        es.symbol = _symbol;
    }
    function getName() internal view returns(string memory name_) {
        name_ = erc20Storage().name;
    }
    function getSymbol() internal view returns(string memory name_) {
        name_ = erc20Storage().symbol;
    }

}