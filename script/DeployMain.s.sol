// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IDiamondCut} from "../src/facets/Diamond/IDiamondCut.sol"; // Adjust to your imports
import {DiamondCutFacet} from "../src/facets/Diamond/DiamondCutFacet.sol"; // Example; not used directly

contract DeployDiamond is Script {
    // Configurable list: Add new facet names here (e.g., "MarketplaceFacet")
    string[] public facetNames = [
        "DiamondCutFacet",
        "DiamondLoupeFacet",
        "OwnershipFacet",
        "ERC20Facet"
        // Add "MarketplaceFacet" here for auto-inclusion
    ];

    function setUp() public {} // Optional setup

    function run() public {
        vm.startBroadcast();

        // Step 1: Dynamically deploy facets and build FacetCut[]
        IDiamondCut.FacetCut[] memory facetCuts = _buildFacetCuts();

        // Step 2: Your existing Registry registration (pseudo-code; adapt as needed)
        // Registry registry = new Registry();
        // registry.registerFacets(facetCuts);

        // Step 3: Deploy Diamond (adapt to your DiamondDeploy logic)
        // address diamond = address(new DiamondDeploy(facetCuts));
        // ... (e.g., cut the diamond, transfer ownership)

        // Optional: Persist selectors to JSON for reuse
        _persistSelectors(facetCuts);

        vm.stopBroadcast();
    }

    /// @dev Builds FacetCut[] by dynamically fetching selectors and deploying facets.
    function _buildFacetCuts() internal returns (IDiamondCut.FacetCut[] memory cuts) {
        uint256 numFacets = facetNames.length;
        cuts = new IDiamondCut.FacetCut[](numFacets);

        for (uint256 i = 0; i < numFacets; ++i) {
            string memory name = facetNames[i];
            string memory contractId = string.concat("src/facets/", name, ".sol:", name);

            // Fetch methodIdentifiers JSON
            string[] memory inspectCmd = new string[](5);
            inspectCmd[0] = "forge";
            inspectCmd[1] = "inspect";
            inspectCmd[2] = contractId;
            inspectCmd[3] = "methodIdentifiers";
            inspectCmd[4] = "--json";

            bytes memory outputBytes = vm.ffi(inspectCmd);
            string memory json = string(outputBytes);

            // Parse all selector hex strings (e.g., ["0xa9059cbb", ...])
            bytes memory selBytes = vm.parseJson(json, ".methodIdentifiers.[]");
            string[] memory selStrings = abi.decode(selBytes, (string[]));

            // Convert to bytes4[]
            bytes4[] memory selectors = new bytes4[](selStrings.length);
            for (uint256 j = 0; j < selStrings.length; ++j) {
                selectors[j] = bytes4(vm.parseBytes32(selStrings[j])); 
            }

            // Fetch bytecode JSON for deployment
            string[] memory bytecodeCmd = new string[](5);
            bytecodeCmd[0] = "forge";
            bytecodeCmd[1] = "inspect";
            bytecodeCmd[2] = contractId;
            bytecodeCmd[3] = "bytecode";
            bytecodeCmd[4] = "--json";

            bytes memory bytecodeOutputBytes = vm.ffi(bytecodeCmd);
            string memory bytecodeJson = string(bytecodeOutputBytes);

            // Parse bytecode hex string (e.g., "0x6080604052...")
            string memory bytecodeStr = abi.decode(vm.parseJson(bytecodeJson, ".bytecode"), (string));
            bytes memory bytecode = vm.parseBytes(bytecodeStr); // Handles full hex

            // Deploy facet
            address facetAddr = _deployCode(bytecode);

            // Build cut (Add action; adjust if Replace/Remove needed)
            cuts[i] = IDiamondCut.FacetCut({
                facetAddress: facetAddr,
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectors
            });

            console2.log("Deployed %s at %s with %d selectors", name, facetAddr, selectors.length);
        }
    }

    /// @dev Deploys raw creation bytecode (assumes no constructor args).
    function _deployCode(bytes memory code) internal returns (address addr) {
        assembly {
            addr := create(0, add(code, 0x20), mload(code))
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }

    /// @dev Optional: Persist all selectors to JSON (e.g., for tests or reuse).
    function _persistSelectors(IDiamondCut.FacetCut[] memory cuts) internal {
        string memory root = vm.projectRoot();
        string memory filePath = string.concat(root, "/facet-selectors.json");

        // Manual JSON build (simple; use forge-std/StdJson.sol for complex structs)
        string memory jsonContent = '{"facets": [';
        for (uint256 i = 0; i < cuts.length; ++i) {
            string memory name = facetNames[i]; // Map back via index 
            jsonContent = string.concat(jsonContent, '{"name":"', name, '","selectors":[');
            for (uint256 j = 0; j < cuts[i].functionSelectors.length; ++j) {
                // Convert bytes4 back to hex string for JSON
                bytes memory selHex = new bytes(10); // "0x" + 8 hex chars
                selHex[0] = bytes1(hex"30"); // '0'
                selHex[1] = bytes1(hex"78"); // 'x'
                // ... (assembly or loop to append hex; simplified here)
                // Full impl: Use toHexString from forge-std/Test.sol
                jsonContent = string.concat(jsonContent, '"0x', _toHexString(cuts[i].functionSelectors[j]), '"');
                if (j < cuts[i].functionSelectors.length - 1) jsonContent = string.concat(jsonContent, ",");
            }
            jsonContent = string.concat(jsonContent, ']}}');
            if (i < cuts.length - 1) jsonContent = string.concat(jsonContent, ",");
        }
        jsonContent = string.concat(jsonContent, ']}');

        vm.writeFile(filePath, jsonContent);
        console2.log("Persisted selectors to %s", filePath);
    }

    // Helper: bytes4 to hex string (adapt from forge-std/Test.sol)
    function _toHexString(bytes4 value) internal pure returns (string memory) {
        bytes memory str = new bytes(10);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 4; ++i) {
            uint8 _byte = uint8(uint32(value) >> (8 * (3 - i)));
            str[2 + i * 2] = _toHexDigit(_byte >> 4);
            str[3 + i * 2] = _toHexDigit(_byte & 0x0f);
        }
        return string(str);
    }

    function _toHexDigit(uint8 digit) internal pure returns (bytes1) {
        if (digit < 10) return bytes1(char(uint8(48 + digit)));
        return bytes1(char(uint8(97 + digit - 10)));
    }

    function char(uint8 b) internal pure returns (bytes1) {
        return bytes1(b);
    }
}