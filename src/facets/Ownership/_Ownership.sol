// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibOwnership} from "./LibOwnership.sol";
import {iERC2771Recipient} from "../ERC2771Recipient/_ERC2771Recipient.sol";     

contract iOwnership is iERC2771Recipient {
    error MigrationAlreadyInitiated();
    error MigrationAlreadyCompleted();
    error MigrationNotInitiated();

    event MigrationInitiated(address initiatior, uint32 timeInitiatied);
    event MigrationCancelled(address cancellor, uint32 timeCancelled);
    event OwnershipChanged(address oldOwner, address newOwner); 
    
    modifier onlyOwner(){
        msgSender() == _ecosystemOwner();
        _;
    }
    function _setEcosystemOwner( address _newOwner) internal {
        isEcosystemOwnerVerification();
        LibOwnership._setEcosystemOwner(_newOwner);
    }

    function _ecosystemOwner() internal view returns (address owner_) {
        owner_ = LibOwnership._ecosystemOwner();
    }

    function isEcosystemOwnerVerification() internal view {
        require( msgSender() == _ecosystemOwner(), "Must be the Ecosystem owner"); 
    }
    

    //Migration related methods

    /**
     * @dev sole purpose is to restrict user from having access to ecosystem modularity
     * until they initiate a migration. only modular changes are done via registry until
     * then. 
     */
    function isEffectiveOwner() internal view {
        LibOwnership.OwnershipStorage storage os = LibOwnership.ownershipStorage();
        LibOwnership.Migration storage _migration = os.migration;
        if( _migration.isMigrating && uint32(block.timestamp) >= _migration.expirationTimestamp ){
            require( msgSender() == os.ecosystemOwner, "Sender must be the owner.");
        }
        else{
            require(msgSender() == os.registry, "Sender must be from the registry.");
        }
    }

    
    /**
     * @dev start the migration 
     */
    function _initiateMigration() internal returns (uint32 expirationTime_) {
        LibOwnership.OwnershipStorage storage os = LibOwnership.ownershipStorage();
        LibOwnership.Migration storage _migration = os.migration;
        if( _migration.isMigrating ){
            revert MigrationAlreadyInitiated();
        }
        else{
            _migration.isMigrating = true;
            expirationTime_ =  uint32(block.timestamp) + LibOwnership.MIGRATION_TRANSITION_LOCK_TIMESPAN;
            _migration.expirationTimestamp = expirationTime_; 
            emit MigrationInitiated(msgSender(), uint32(block.timestamp) );
        } 
    }
    function _cancelMigration() internal returns (uint32 expirationTime_) {
        LibOwnership.OwnershipStorage storage os = LibOwnership.ownershipStorage();
        LibOwnership.Migration storage _migration = os.migration;
        uint32 _expirationTimestamp = _migration.expirationTimestamp;
        if( _migration.isMigrating  ) {
            if( uint32(block.timestamp) >= _expirationTimestamp ){
                revert MigrationAlreadyCompleted();
            }
            else{
                _migration.isMigrating = false;
                expirationTime_ = LibOwnership.MAX_TIMESTAMP;
                emit MigrationCancelled(msgSender(), expirationTime_);
            }
        }
        else {
            revert MigrationNotInitiated();
        }
        
    }
   
}
 