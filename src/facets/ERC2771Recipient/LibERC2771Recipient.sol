// LibEventStorage.sol
pragma solidity ^0.8.0;



library LibERC2771Recipient {
    bytes32 constant STORAGE_POSITION = keccak256("diamond.storage.ERC2771Recipient");

   
    struct ERC2771RecipientStorage {
        address trustedForwarder;
    }

    function erc2771RecipientStorage() internal pure returns ( ERC2771RecipientStorage storage es) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }


   function __getTrustedForwarder() internal  view returns (address trustedForwarder_){
       ERC2771RecipientStorage storage es =  erc2771RecipientStorage();
        trustedForwarder_ =  es.trustedForwarder;
    }

    function __setTrustedForwarder(address _forwarder) internal {
        ERC2771RecipientStorage storage es =  erc2771RecipientStorage();
        es.trustedForwarder = _forwarder; 
    }
 
  
    function _isTrustedForwarder(address forwarder) public  view returns(bool) {
        ERC2771RecipientStorage storage es =  erc2771RecipientStorage();
        return forwarder == es.trustedForwarder;
    }
 
    
    function _msgSender() internal  view returns (address ret) {
        if (msg.data.length >= 20 && _isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    
    function _msgData() internal  view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && _isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}
