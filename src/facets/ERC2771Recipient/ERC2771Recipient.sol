

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.8.0;



import { LibERC2771Recipient } from "./LibERC2771Recipient.sol";  
import { iERC2771Recipient} from "./_ERC2771Recipient.sol"; 

import {iOwnership} from "../Ownership/_Ownership.sol";
/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
contract ERC2771Recipient is iERC2771Recipient, iOwnership{
 
    /*
     * Forwarder singleton we accept calls from
     */
     
    
    constructor(address _forwarder){ 
        _setTrustedForwarder(_forwarder); 
    }

    function getTrustedForwarder() public  view returns (address forwarder){
        return _getTrustedForwarder();
    }

    function setTrustedForwarder(address _forwarder) private {
        _setTrustedForwarder(_forwarder); 
    }
    
    function isTrustedForwarder(address forwarder) external view returns( bool trusted_){
        trusted_ = _isTrustedForwarder(forwarder);
    } 
}
