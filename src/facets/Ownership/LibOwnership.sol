pragma solidity ^0.8.0;



library LibOwnership {
bytes32 constant OWNERSHIP_STORAGE_POSITION = keccak256("diamond.ownership.storage");
uint32 constant MIGRATION_TRANSITION_LOCK_TIMESPAN = 259200; // 3 days
uint32 constant MAX_TIMESTAMP = type( uint32 ).max;
struct OwnershipStorage{
    address ecosystemOwner;
    address registry;
    Migration migration;
}
struct Migration{
    bool isMigrating;
    uint32 expirationTimestamp;
}

function ownershipStorage() internal pure returns (OwnershipStorage storage os) {
        bytes32 position = OWNERSHIP_STORAGE_POSITION;
        assembly {
            os.slot := position 
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
        Should never be used outside of iOwnership.sol (exception for the initial diamond constructor)
        @notice Sets the owner of this ecosystem
        @param _newEcosystemOwner  new ecosystem owner 
     */
    function _setEcosystemOwner(address _newEcosystemOwner) internal {
        OwnershipStorage storage os = ownershipStorage();
        address previousOwner = os.ecosystemOwner;
        os.ecosystemOwner = _newEcosystemOwner;
        emit OwnershipTransferred(previousOwner, _newEcosystemOwner);
    }

    function _ecosystemOwner() internal view returns (address ecosystemOwner_) {
        ecosystemOwner_ = ownershipStorage().ecosystemOwner;
    }

    function _setRegistry(address _registry) internal {
        OwnershipStorage storage os = ownershipStorage();
        os.registry = _registry;
    }
    function _getRegistry() internal view returns (address registry_) {
        OwnershipStorage storage os = ownershipStorage();
        registry_ = os.registry;
    }
    
    
} 