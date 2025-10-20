// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../deploy/IDiamondDeploy.sol";
import "../facets/Diamond/IDiamondCut.sol";

import {LibOwnership} from "../facets/Ownership/LibOwnership.sol";
import "../facets/Ownership/_Ownership.sol";
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
    //mapping(uint240 => mapping(bytes32 => address)) optimizedFacet;

    // Constructor
    constructor() {
        owner = msgSender();
    }

    // Owner-Only Functions
    function uploadVersion(
        bytes32 versionNumber,
        address diamondDeployAddress,
        IDiamondCut.FacetCut[] memory facetCuts
    ) public onlyOwner {
        require(
            msgSender() == owner,
            "Only the owner may upload new ecosystem versions."
        );
        require(!versions[versionNumber].exists, "Version already exists");

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
    function getVersion(
        bytes32 versionNumber
    ) external view returns (Version memory) {
        return versions[versionNumber];
    }

    function getUserEcosystems(
        address ecosystemsOwner
    ) external view returns (Ecosystem[] memory ecosystems_) {
        ecosystems_ = userEcosystems[ecosystemsOwner];
    }





    //change to
    function deployVersion(
        bytes32 versionNumber,
        string memory name,
        uint256 salt,
        bytes calldata diamondBytecode
    ) public returns (address ecosystemAddress_) {
        Version storage _version = versions[versionNumber];
        // Step 1: Check version number validity
        require(_version.exists, "Version is not valid or not active");
        bytes32 nameHash = keccak256(abi.encode(name));

        bool isNamespaceOccupied = uniqueNamespace[nameHash];
        require(
            !isNamespaceOccupied,
            "Ecosystem name must be unique in the registry namespace"
        );
        uniqueNamespace[nameHash] = !isNamespaceOccupied;

        ecosystemAddress_ = IDiamondDeploy(_version.diamondDeployAddress)
            .deploy(msgSender(), salt, diamondBytecode, _version.facetCuts);
        // Step 4: Update the user's ecosystems
        Ecosystem memory newEcosystem = Ecosystem(
            name,
            ecosystemAddress_,
            versionNumber
        );
        userEcosystems[msg.sender].push(newEcosystem);
    
        // Emit Event
        emit EcosystemDeployed(
            msg.sender,
            ecosystemAddress_,
            versionNumber,
            name
        );
    }
}
