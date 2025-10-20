// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IDiamondCut} from "../src/facets/Diamond/IDiamondCut.sol"; // Adjust to your imports

contract DeployDiamond is Script {
    // Configurable list: Add new facet names here (e.g., "MarketplaceFacet")
    string[] public facetNames = [
        "DiamondCutFacet",
        "DiamondLoupeFacet",
        "OwnershipFacet",
        "ERC20Facet",
        "ERC2771Recipient"
        // Add "MarketplaceFacet" here for auto-inclusion
    ];

    // Parallel list: Subdirectories for each facet (in same order as facetNames)
    string[] public subdirs = [
        "Diamond",
        "Diamond",
        "Ownership",
        "ERC20",
        "ERC2771Recipient"
        // Add corresponding subdir for new facets
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
        // IDiamondCut(address(diamond)).diamondCut(facetCuts, IDiamondCut.DiamondCutFunctionType.Add, ""); // Initial cut
        // OwnershipFacet(address(diamond)).transferOwnership(msg.sender); // Example

        // Optional: Persist selectors to JSON for reuse
        _persistSelectors(facetCuts);

        vm.stopBroadcast();
    }

    /// @dev Builds FacetCut[] by dynamically fetching selectors and deploying facets.
    /// Now stack-safe: Loop has minimal locals; heavy work delegated.
    function _buildFacetCuts() internal returns (IDiamondCut.FacetCut[] memory cuts) {
        uint256 numFacets = facetNames.length;
        cuts = new IDiamondCut.FacetCut[](numFacets);

        for (uint256 i = 0; i < numFacets; ++i) {
            string memory name = facetNames[i];
            string memory subdir = subdirs[i]; // Fetch corresponding subdir
            string memory contractId = string.concat("src/facets/", subdir, "/", name, ".sol:", name);

            // Delegate to sub-functions to avoid stack bloat
            bytes4[] memory selectors = _getSelectors(contractId);
            bytes memory bytecode = _getBytecode(contractId);
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

    /// @dev Fetches and parses method selectors via FFI.
    function _getSelectors(string memory contractId) internal returns (bytes4[] memory selectors) {
        string[] memory inspectCmd = new string[](5);
        inspectCmd[0] = "forge";
        inspectCmd[1] = "inspect";
        inspectCmd[2] = contractId;
        inspectCmd[3] = "methodIdentifiers";
        inspectCmd[4] = "--json";

        bytes memory outputBytes = vm.ffi(inspectCmd);
        string memory json = string(outputBytes);

        // Parse JSON: Root is { "sig": "sel", ... } → ".*" selects all values as string[] of hex selectors (no "0x")
        bytes memory selBytes = vm.parseJson(json, ".*");
        string[] memory selStrings = abi.decode(selBytes, (string[]));

        // Edge case: No selectors (e.g., abstract contract)
        if (selStrings.length == 0) {
            selectors = new bytes4[](0);
            return selectors;
        }

        selectors = new bytes4[](selStrings.length);
        for (uint256 j = 0; j < selStrings.length; ++j) {
            // Prepend "0x" since forge inspect outputs raw hex without prefix
            string memory hexWithPrefix = string.concat("0x", selStrings[j]);
            console2.log("Parsed selector hex: %s", hexWithPrefix); // Debug: Confirm prepending
            // vm.parseBytes32 converts "0x..." hex string to bytes32; cast to bytes4 (first 4 bytes)
            selectors[j] = bytes4(vm.parseBytes32(hexWithPrefix));
            console2.log("Selector %d: %s", j, hexWithPrefix); // Debug: Log each selector
        }
    }

    /// @dev Fetches bytecode via FFI.
    function _getBytecode(string memory contractId) internal returns (bytes memory bytecode) {
        string[] memory bytecodeCmd = new string[](5);
        bytecodeCmd[0] = "forge";
        bytecodeCmd[1] = "inspect";
        bytecodeCmd[2] = contractId;
        bytecodeCmd[3] = "bytecode";
        bytecodeCmd[4] = "--json";

        bytes memory outputBytes = vm.ffi(bytecodeCmd);
        string memory bytecodeJson = string(outputBytes);

        string memory bytecodeStr = abi.decode(vm.parseJson(bytecodeJson, ".bytecode"), (string));
        bytecode = vm.parseBytes(bytecodeStr);
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

        // Build JSON manually (simple array of objects)
        string memory jsonContent = '{"facets": [';
        for (uint256 i = 0; i < cuts.length; ++i) {
            string memory name = facetNames[i]; // Map back via index
            jsonContent = string.concat(jsonContent, '{"name":"', name, '","selectors":[');
            bytes4[] memory selectors = cuts[i].functionSelectors;
            for (uint256 j = 0; j < selectors.length; ++j) {
                jsonContent = string.concat(jsonContent, '"', _toHexString(selectors[j]), '"');
                if (j < selectors.length - 1) jsonContent = string.concat(jsonContent, ",");
            }
            jsonContent = string.concat(jsonContent, ']}');
            if (i < cuts.length - 1) jsonContent = string.concat(jsonContent, ",");
        }
        jsonContent = string.concat(jsonContent, ']}');

        vm.writeFile(filePath, jsonContent);
        console2.log("Persisted selectors to %s", filePath);
    }

    // Helper: bytes4 to hex string (e.g., "0xa9059cbb")
    function _toHexString(bytes4 value) internal pure returns (string memory) {
        bytes memory str = new bytes(10); // "0x" + 8 hex chars
        str[0] = bytes1(uint8(48)); // '0'
        str[1] = bytes1(uint8(120)); // 'x'
        uint256 temp = uint256(uint32(value));
        for (uint256 i = 0; i < 4; ++i) {
            uint8 byteVal = uint8(temp >> (8 * (3 - i)));
            str[2 + i * 2] = _toHexDigit(uint8(byteVal >> 4));
            str[3 + i * 2] = _toHexDigit(uint8(byteVal & 0x0f));
        }
        return string(str);
    }

    function _toHexDigit(uint8 digit) internal pure returns (bytes1) {
        uint8 c = digit < 10 ? uint8(48 + digit) : uint8(97 + digit - 10); // '0'-'9', 'a'-'f'
        return bytes1(c);
    }
}