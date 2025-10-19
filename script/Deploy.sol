// script/DeployDiamond.s.sol
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";

// 1. Manually import all required contracts/facets
import {Registry} from "../src/registry/Registry.sol";
import {Diamond} from "../src/Diamond/Diamond.sol";
import {DiamondCutFacet} from "../src/facets/Diamond/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/Diamond/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/Ownership/OwnershipFacet.sol";
import {ERC20Facet} from "../src/facets/ERC20/ERC20Facet.sol";

contract DeployDiamondScript is Script {
    // Define the contract owner/governance
    address public constant OWNER = address(0xBEEF);// Replace with your desired owner address

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // vm.startBroadcast() is called with the private key to sign and submit transactions
        vm.startBroadcast(deployerPrivateKey);

        // --- 1. Deploy Facets and Registry ---
        console2.log("1. Deploying Facets and Registry...");
        DiamondCutFacet cutFacet = new DiamondCutFacet();
        DiamondLoupeFacet loupeFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        ERC20Facet erc20Facet = new ERC20Facet();
        Registry registry = new Registry();
        
        console2.log("Registry Address:", address(registry));

        // --- 2. Deploy the Diamond Proxy ---
        console2.log("2. Deploying Diamond Proxy...");
        Diamond diamond = new Diamond();
        address diamondAddress = address(diamond);
        console2.log("Diamond Address:", diamondAddress);

        // --- 3. Construct the DiamondCut array (The 'Add' operation) ---
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](4);

        cuts[0] = buildCut(address(cutFacet));
        cuts[1] = buildCut(address(loupeFacet));
        cuts[2] = buildCut(address(ownershipFacet));
        cuts[3] = buildCut(address(erc20Facet));

        // --- 4. Execute the Initial DiamondCut ---
        console2.log("4. Executing initial DiamondCut...");
        IDiamondCut diamondCut = IDiamondCut(diamondAddress);

        // Execute the cut to link all facets to the Diamond proxy
        diamondCut.diamondCut(
            cuts, 
            address(0),  // _init: Address of initializer contract (0x0 since we use an immediate cut)
            ""           // _calldata: Calldata for the initializer function
        );

        // --- 5. Optional: Initialize/Configure ---
        // Call the OwnershipFacet function on the Diamond address to set the final owner
        OwnershipFacet(diamondAddress).transferOwnership(OWNER);
        
        // Register the Diamond itself in the registry for tracking
        registry.register("Diamond_V1", diamondAddress, 1);

        console2.log("Deployment and initial DiamondCut completed.");

        // vm.stopBroadcast() tells Foundry to stop recording transactions
        vm.stopBroadcast();
    }
    
    // --- Helper Function using vm.parseSelectors ---
    function buildCut(address _facetAddress)
        internal
        view // Changed to view since we are using vm.parseSelectors which is off-chain
        returns (IDiamondCut.FacetCut memory)
    {
        // vm.parseSelectors reads the bytecode of the contract at _facetAddress 
        // and returns all exposed function signatures (bytes[]).
        bytes[] memory sigs = vm.parseSelectors(_facetAddress);
        bytes4[] memory selectors = new bytes4[](sigs.length);

        for (uint256 i = 0; i < sigs.length; i++) {
            // Convert the full signature bytes to the 4-byte selector
            selectors[i] = bytes4(sigs[i]);
        }

        return IDiamondCut.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
    }
}