// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../deploy/IDiamondDeploy.sol";
import "../facets/Diamond/IDiamondCut.sol";
import "../exchangeFinal/interfaces/ITicketExchange.sol";

interface IEcosystemRegistry  { // Assuming iOwnership is an interface
    // Structs
    struct Version {
        bool exists;
        uint32 uploadedTimestamp;
        address diamondDeployAddress;
        IDiamondCut.FacetCut[] facetCuts;
    }

    struct Ecosystem {
        string name;
        address ecosytemAddress;
        bytes32 versionNumber;
    }

    // Events
    event VersionUploaded(bytes32 versionNumber);
    event EcosystemDeployed(address user, address ecosystem, bytes32 versionNumber, string name);
    event VersionUpgraded(bytes32 newVersion, bytes32 oldVersion, address ecosystemOwner);
    event MigrationStateChange(address ecosystem, uint32 expirationTimestamp);

    // Owner-Only Functions (assuming onlyOwner is an internal modifier, so functions are public/external)
    function uploadVersion(
        bytes32 versionNumber,
        address diamondDeployAddress,
        IDiamondCut.FacetCut[] memory facetCuts
    ) external; // Changed to external as it's called by owner

    // Public Functions
    function getVersion(bytes32 versionNumber) external view returns (Version memory);
    function getUserEcosystems(address ecosystemsOwner) external view returns (Ecosystem[] memory ecosystems_);
    function registerOptimizationFacet(uint240 mainVersion, bytes2 optimizationType, bytes memory bytecode, bytes memory params) external;
    function initiateMigration(address ecosystem) external;
    function cancelMigration(address ecosystem) external;
    function deployVersion(bytes32 versionNumber, string memory name, uint256 salt, bytes calldata diamondBytecode) external returns (address ecosystemAddress_);

    // State Variables (public variables automatically generate getter functions)
    function owner() external view returns (address);
    function versions(bytes32) external view returns (bool exists, uint32 uploadedTimestamp, address diamondDeployAddress); // Note: facetCuts array cannot be returned directly by public mapping getter
    function ticketExchangeAddress() external view returns (address);
}
