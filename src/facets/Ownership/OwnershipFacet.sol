// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {iOwnership} from "./_Ownership.sol";  
import { LibOwnership } from "./LibOwnership.sol"; 

contract OwnershipFacet is iOwnership {
    function setEcosystemOwner(address _newOwner) external {
        _setEcosystemOwner(_newOwner);  
    }

    function ecosystemOwner() external   view returns (address owner_) {
        owner_ = _ecosystemOwner(); 
    }

    /**
     * @notice this method is used externally to check if it's an owner as well as an ecosystem
     * @param _tenativeOwner user that is being verified as owner
     */
    function isEcosystemOwnerVerify(address _tenativeOwner) external view {
        require( _ecosystemOwner() == _tenativeOwner , "Must be the ecosystem owner.");
    }
    function owner() external view returns( address owner_){
        LibOwnership.OwnershipStorage storage os = LibOwnership.ownershipStorage();
        owner_ = os.ecosystemOwner; 
    }
}
 