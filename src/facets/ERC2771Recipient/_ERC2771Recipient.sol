// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.8.0;



import { LibERC2771Recipient } from "./LibERC2771Recipient.sol";  
/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
contract iERC2771Recipient {
 
    /*
     * Forwarder singleton we accept calls from
     */
     
    

    function _getTrustedForwarder() internal  view returns (address forwarder){
        return LibERC2771Recipient.__getTrustedForwarder();
    }

    function _setTrustedForwarder(address _forwarder) internal {
        LibERC2771Recipient.__setTrustedForwarder(_forwarder); 
    }
  
  
    function _isTrustedForwarder(address forwarder) internal  view returns(bool) {
        return LibERC2771Recipient._isTrustedForwarder(forwarder);
    } 

    
    function msgSender() internal  view returns (address ret_) {
        ret_ = LibERC2771Recipient._msgSender();
    }
    
    function msgData() internal  view returns (bytes calldata ret_) {
        ret_ = LibERC2771Recipient._msgData();
    }
}