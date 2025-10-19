// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "./IDiamondCut.sol"; 
import { LibDiamond } from "./LibDiamond.sol";

import {iOwnership} from "../Ownership/_Ownership.sol";  

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

contract DiamondCutFacet is IDiamondCut, iOwnership {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        isEffectiveOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
    
    /**
     * @notice Initiate a migration away from the massDX ecosystem versions. 
     * There is a 3 day minimum required timespan
     */
    function initiateMigration() external returns (uint32 expireTime) {
        isEcosystemOwnerVerification();

        return _initiateMigration();
    }

    /**
     * @notice If an ongoing migration exists and hasn't surpassed the 3 day 
     * minimum wait time, then the migration will be cancelled.
     */
    function cancelMigration() external returns (uint32 expireTime){
        isEcosystemOwnerVerification();

        return _cancelMigration();
    }
}
