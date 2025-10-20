// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../facets/Diamond/IDiamondCut.sol";
import "./IDiamondDeploy.sol";  

contract DiamondDeploy {
    address public registryAddress;
    bool isRegistrySet = false;
    bytes32 bytecodeHash;

    
    constructor(address registry, bytes memory _bytecode ) { 
        registryAddress = registry; 
        bytecodeHash = keccak256(_bytecode);
    }

    function deploy(address owner, uint256 _salt, bytes calldata _bytecode, IDiamondCut.FacetCut[] memory _facetCuts) external returns (address diamond_) {
        require(msg.sender == registryAddress,"Must be initiated from the MassDX registry.");
        // Initialize a variable to hold the deployed address
        address deployedAddress; 

        require(keccak256(_bytecode) == bytecodeHash, "Bytecode must match that of the Diamond associated with this contract.");
        // ABI encode the constructor parameters
        bytes memory encodedParams = abi.encode(owner, msg.sender, _facetCuts); 

        // Concatenate the pseudoBytecode and encoded constructor parameters
        bytes memory finalBytecode = abi.encodePacked(_bytecode, encodedParams);

        // Use CREATE2 opcode to deploy the contract with static bytecode
        // Generate a unique salt based on msg.sender
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, _salt, encodedParams)); 
        // The following assembly block deploys the contract using CREATE2 opcode
        assembly {
            deployedAddress := create2(
                0, // 0 wei sent with the contract
                add(finalBytecode, 32), // skip the first 32 bytes (length)
                mload(finalBytecode), // size of bytecode
                salt // salt
            )
            // Check if contract deployment was successful
            if iszero(extcodesize(deployedAddress)) {
                revert(0, 0)
            }
        }
        return deployedAddress;
    }

 
}
