pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";

import "commons-management/DOUG.sol";
import "commons-management/AbstractDelegateProxy.sol";

/**
 * @title ObjectProxy
 * @dev Implementation of a proxy contract that supports unstructured data storage, i.e. leaves the definition and management of data storage to the proxied contract.
 * The data fields required for proxying and delegating calls are stored in reserved storage slots that are extremely unlikely to ever interfere with the structured storage space of the proxied contract.
 */
contract ObjectProxy is AbstractDelegateProxy {

    /**
     * Storage position of the address for DOUG
     */
    bytes32 private constant storagePositionDoug = keccak256("AN://contract/storage/doug");
    /**
     * Storage position of the object class identifier's length
     */
    bytes32 private constant storagePositionObjectClassLength = keccak256("AN://contract/storage/object-class/length");
    /**
     * Storage position of the object class identifier's value
     */
    bytes32 private constant storagePositionObjectClassValue = keccak256("AN://contract/storage/object-class/value");

    /**
     * @dev Creates a new ObjectProxy with the given address as the proxied contract
     * @param _doug the address of a DOUG contract
     * @param _objectClass the identifier for the proxied implementation
     */
    constructor(address _doug, string memory _objectClass) public {
        bytes32 dougPos = storagePositionDoug;
        bytes32 classLengthPos = storagePositionObjectClassLength;
        bytes32 classValuePos = storagePositionObjectClassValue;
        assembly {
            sstore(dougPos, _doug)
            sstore(classLengthPos, mload(_objectClass)) // size of the string
            sstore(classValuePos, mload(add(_objectClass, 0x20))) // string value
        }
    }

    /**
     * @dev Implements AbstractDelegateProxy.getDelegate()
     * Retrieves and returns the delegate address for this proxy by querying DOUG using the obect class identifier.
     * @return the address of the proxied contract
     */
    function getDelegate() public view returns (address) {
        address dougAddress = getDoug();
        ErrorsLib.revertIf(dougAddress == address(0),
            ErrorsLib.INVALID_STATE(), "ObjectProxy.getDelegate", "DOUG address cannot be determined for lookup of delegate implementation");
        return DOUG(dougAddress).lookupContract(getObjectClass());
    }

    // TODO instead of DOUG this should be a more generic interface to lookup object class (implementation) information
    function getDoug() public view returns (address dougAddress) {
        bytes32 dougPos = storagePositionDoug;
        assembly {
            dougAddress := sload(dougPos)
        }
    }

    function getObjectClass() public view returns (string objectClass) {
        bytes32 classLengthPos = storagePositionObjectClassLength;
        bytes32 classValuePos = storagePositionObjectClassValue;
        assembly {
            objectClass := mload(0x40) // free mem storage pointer
            mstore(objectClass, sload(classLengthPos))
            mstore(add(objectClass, 0x20), sload(classValuePos))
            mstore(0x40, add(objectClass, 0x40)) // set the pointer to free memory
        }
    }

}