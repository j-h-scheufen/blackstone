pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";

/**
 * @title AbstractDelegateProxy
 * @dev Abstract contract implementing a fallback function to delegate calls to a proxied implementation.
 */
contract AbstractDelegateProxy {

    /**
     * @dev Returns the address of the proxied conract to which all calls will be delegated.
     * @return the address of the contract used as delegate
     */
    function getDelegate() public view returns (address);

    /**
     * @dev Fallback function that dispatches any invocation of this contract via delegatecall to a proxied contract.
     * @return This function will return whatever the implementation call returns
     */
    function () public {
        address target = getDelegate();
        ErrorsLib.revertIf(target == address(0),
            ErrorsLib.INVALID_STATE(), "AbstractDelegateProxy", "Proxied target address must not be empty");

        assembly {
            let freeMemSlot := mload(0x40)
            calldatacopy(freeMemSlot, 0, calldatasize)
            let result := delegatecall(gas, target, freeMemSlot, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(freeMemSlot, 0, size)

            switch result
            case 0 { revert(freeMemSlot, size) }
            default { return(freeMemSlot, size) }
        }
    }
}