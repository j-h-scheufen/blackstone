pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";

import "commons-auth/UserAccount.sol";
import "commons-auth/Ecosystem.sol";
import "commons-auth/Governance.sol";

/**
 * @title DefaultUserAccount
 * @dev The default implementation of a UserAccount
 */
contract DefaultUserAccount is UserAccount {

    using MappingsLib for Mappings.AddressBoolMap;

    Governance.UserAccount account;

    /**
     * @dev Modifier that restricts the function access to the owner address or one of the address known to belong to an ecosystem that this account is connected to.
     * REVERTS if:
     * - the msg.sender is not the owner and not one of the addresses associated with one of the account's ecosystems
     */
    modifier pre_onlyAuthorizedCallers() {
        bool authorized = msg.sender == owner;
        if (!authorized) {
            for (uint i=0; i<account.ecosystems.keys.length; i++) {
                if (Ecosystem(account.ecosystems.keys[i]).isKnownExternalAddress(msg.sender)) {
                    authorized = true;
                    break;
                }
            }
        }
        ErrorsLib.revertIf(!authorized, ErrorsLib.UNAUTHORIZED(), "DefaultUserAccount.pre_onlyAuthorizedCallers", "Caller is neither owner nor known ecosystem");
        _;
    }

    /**
     * @dev Creates a new UserAccount belonging to the specified owner and/or ecosystem.
     * One or both owner/ecosystem are required to be set to guarantee another entity has control over this UserAccount
     * REVERTS if:
     * - both owner and ecosystem are empty.
     * @param _owner public external address of individual owner (optional)
     * @param _ecosystem address of an ecosystem (optional)
     */
    constructor(address _owner, address _ecosystem) public {
        ErrorsLib.revertIf(_owner == address(0) && _ecosystem == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultUserAccount.constructor", "One of owner or ecosystem must be provided");
        owner = _owner;
        if (_ecosystem != address(0)) {
            account.ecosystems.insertOrUpdate(_ecosystem, true);
        }
        account.exists = true;
    }
    
    /**
     * @dev Forwards a call to the specified target using the given bytes message.
     * @param _target the address to call
     * @param _payload the function payload consisting of the 4-bytes function hash and the abi-encoded function parameters which is typically created by
     * calling abi.encodeWithSelector(bytes4, args...) or abi.encodeWithSignature(signatureString, args...) 
     * @return success - whether the forwarding call returned normally
     * @return returnData - the bytes returned from calling the target function, if successful (NOTE: this is currently not supported, yet, and the returnData will always be empty)
     * REVERTS if:
     * - the target address is empty (0x0)
     */
    function forwardCall(address _target, bytes _payload)
        external
        pre_onlyAuthorizedCallers
        returns (bool success, bytes returnData)
    {
        ErrorsLib.revertIf(_target == address(0), 
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultUserAccount.forwardCall", "Target address must not be empty");
        bytes memory data = _payload;
        assembly {
            success := call(gas, _target, 0, add(data, 0x20), mload(data), data, 0)
        }
        if (success) {
            uint returnSize;
            assembly {
                returnSize := returndatasize
            }
            returnData = new bytes(returnSize); // allocates a new byte array with the right size
            assembly {
                returndatacopy(add(returnData, 0x20), 0, returnSize) // copies the returned bytes from the function call into the return variable
            }
        }
    }
}
