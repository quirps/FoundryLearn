// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../deploy/IDiamondDeploy.sol"; 
import "../facets/Diamond/IDiamondCut.sol"; 

import {LibOwnership} from "../facets/Ownership/LibOwnership.sol";
import "hardhat/console.sol";
import "../facets/Ownership/_Ownership.sol";
import "../exchangeFinal/interfaces/ITicketExchange.sol";
import {IEcosystemRegistry} from "./IRegistry.sol";
/**
TODO
Need to add Owner/Global freeze logic as inherited contract
Need to hardcoded facet <--> constructor dependencies and types
Would be accomplished better with Diamond

Ultimately have a diamond where the owner can only implement new versions.
Would need to add new versions, but have logic in main diamond. 
Upgrades - Get first version (earlier). Step up version upgrades
What changes do we need to watch out for? Forget localized optimizations for now.
    1. Consistent constructor inputs as prior. 
    2. Changing/Adding/Removing relevant facets

For 2, we loop starting at version i + 1  (i is starting version) and go to N (target version)
We should create an array of DiamondCuts. DiamondCuts must have constructor information too. 

 */ 
contract EcosystemRegistry is IEcosystemRegistry, iOwnership {
    // State Variables
    address public owner;
    mapping(bytes32 => Version) public versions;
    mapping(address => Ecosystem[]) userEcosystems;
    mapping(bytes32 => bool) uniqueNamespace;
    address public immutable ticketExchangeAddress;
    //mapping(uint240 => mapping(bytes32 => address)) optimizedFacet;



    // Constructor
    constructor( address _ticketExchangeAddress ) {
        ticketExchangeAddress = _ticketExchangeAddress;
        owner = msgSender();
    }

    // Owner-Only Functions
    function uploadVersion(
        bytes32 versionNumber,
        address diamondDeployAddress, 
        IDiamondCut.FacetCut[] memory facetCuts
    ) public onlyOwner {
        require(msgSender() == owner, "Only the owner may upload new ecosystem versions.");
        require(! versions[versionNumber].exists, "Version already exists");

        Version storage newVersion = versions[versionNumber];
        newVersion.uploadedTimestamp = uint32(block.timestamp);
        newVersion.exists = true;
        newVersion.diamondDeployAddress = diamondDeployAddress;

        for (uint i = 0; i < facetCuts.length; i++) {
            
            newVersion.facetCuts.push(facetCuts[i]);
        }

        emit VersionUploaded(versionNumber);
    }

    // Public Functions
    function getVersion(bytes32 versionNumber) external view returns (Version memory) {
        return versions[versionNumber];
    }

    function getUserEcosystems(address ecosystemsOwner) external view returns (Ecosystem[] memory ecosystems_) {
        ecosystems_ = userEcosystems[ecosystemsOwner];
    }

    // Placeholder for future optimization related functions
    function registerOptimizationFacet(uint240 mainVersion, bytes2 optimizationType, bytes memory bytecode, bytes memory params) external {
        // Placeholder
    }

function initiateMigration(address ecosystem) external {
    try IDiamondCut(ecosystem).initiateMigration() returns (uint32 expirationTimestamp_) {
        ITicketExchange(ticketExchangeAddress).updateTrustStatus(ecosystem, expirationTimestamp_);
        emit MigrationStateChange(ecosystem, expirationTimestamp_);
    } catch Error(string memory reason) {
        revert(string(abi.encodePacked("initiateMigration failed: ", reason)));
    } catch {
        revert("initiateMigration failed: unknown error");
    }
}

function cancelMigration(address ecosystem) external {
    try IDiamondCut(ecosystem).cancelMigration() returns (uint32 expirationTimestamp_) {
        ITicketExchange(ticketExchangeAddress).updateTrustStatus(ecosystem, expirationTimestamp_);
        emit MigrationStateChange(ecosystem, expirationTimestamp_);
    } catch Error(string memory reason) {
        revert(string(abi.encodePacked("cancelMigration failed: ", reason)));
    } catch {
        revert("cancelMigration failed: unknown error");
    }
}

    //change to 
    function deployVersion(bytes32 versionNumber, string memory name, uint256 salt, bytes calldata diamondBytecode) public returns (address ecosystemAddress_) {
        Version storage _version = versions[versionNumber];
        // Step 1: Check version number validity
        console.log(1);
        require(_version.exists, "Version is not valid or not active");
         console.log(2);
        bytes32 nameHash = keccak256( abi.encode(name) );

        bool isNamespaceOccupied = uniqueNamespace[ nameHash ];
        require( !isNamespaceOccupied , "Ecosystem name must be unique in the registry namespace");
        uniqueNamespace[ nameHash ] = !isNamespaceOccupied;

        ecosystemAddress_ = IDiamondDeploy(_version.diamondDeployAddress).deploy(msgSender(), salt, diamondBytecode, _version.facetCuts);
        // Step 4: Update the user's ecosystems
        Ecosystem memory newEcosystem = Ecosystem(name, ecosystemAddress_, versionNumber);
        userEcosystems[msg.sender].push(newEcosystem);
        //Step 5: Add marketplace trust status
        ITicketExchange( ticketExchangeAddress ).updateTrustStatus(ecosystemAddress_ , LibOwnership.MAX_TIMESTAMP);
        // Emit Event
        emit EcosystemDeployed(msg.sender, ecosystemAddress_, versionNumber, name);
    }

}
