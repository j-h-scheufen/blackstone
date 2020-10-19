import "commons-base/ErrorsLib.sol";

// Just a dumb parties container that will satisfy authorizePartyActor in the simple case (no organisation)
contract MockAgreement {
    address[] parties;

    constructor(address[] memory _parties) public {
        parties = _parties;
    }

    function getNumberOfParties() external view returns (uint size) {
        return parties.length;
    }

    function getPartyAtIndex(uint _index) external view returns (address party) {
        if (_index < parties.length) {
            party = parties[_index];
        }
    }
}

contract MockParty {
    function forwardCall(address _target, bytes calldata _payload)
    external
    returns (bytes memory returnData)
    {
        ErrorsLib.revertIf(_target == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultUserAccount.forwardCall", "Target address must not be empty");
        bool success;
        bytes memory data = _payload;
        assembly {
            let freeMemSlot := mload(0x40)
            success := call(gas, _target, 0, add(data, 0x20), mload(data), freeMemSlot, 0)
        }
        uint returnSize;
        assembly {
            returnSize := returndatasize
        }
        returnData = new bytes(returnSize);
        // allocates a new byte array with the right size
        assembly {
            returndatacopy(add(returnData, 0x20), 0, returnSize) // copies the returned bytes from the function call into the return variable
        }
        if (!success) {
            if (returnData.length > 0) {
                assembly {
                    revert(add(returnData, 0x20), returnSize) // a revert(string(returnData)) would add add another 4 bytes for this functions signature to the beginning of the reason, so we'll use assembly here
                }
            }
            else
                revert(ErrorsLib.format(ErrorsLib.RUNTIME_ERROR(), "DefaultUserAccount.forwardCall", "The target function of the forward call reverted without a reason"));
        }
    }
}
