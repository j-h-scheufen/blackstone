pragma solidity ^0.5;

import "../Completables.sol";

// lol solidity - just give me the constants
contract CompletablesTest is CompletableOptions {
    string constant SUCCESS = "success";

    string constant initSignature = "init(bytes32,address,address[],uint256,bool,string)";
    string constant ratifySignature = "ratify(bytes32,int256)";

    function testCompletables() external returns (string memory) {
        address us = address(this);
        MockParty them = new MockParty();
        address[] memory parties = new address[](2);
        parties[0] = us;
        parties[1] = address(them);
        MockAgreement agreement = new MockAgreement(parties);
        Completables comp = new Completables();
        address[] memory franchisees = new address[](2);
        franchisees[0] = address(this);
        franchisees[1] = address(them);

        uint threshold = 2;
        bytes32 intervalId = "foo";
        uint options = COMPLETE_ON_RATIFICATION;

        comp.init(intervalId, address(agreement), franchisees, threshold, options, "nada");
        comp.begin(intervalId, 0);
        comp.ratify(intervalId, 0);

        bool success;
        // Duplicate completable not allowed
        (success,) = address(comp).call(abi.encodeWithSignature(initSignature,
            intervalId,
            address(agreement),
            franchisees,
            threshold,
            options,
            "nada"));
        if (success) return "Should revert when trying to init a Completable with same intervalId as existing open interval";

        // Let's ratify
        them.forwardCall(address(comp), abi.encodeWithSignature(ratifySignature, intervalId, 0));

        // Now the Completable has closed and been deleted so we should be able to re-init with the same intervalId
        comp.init(intervalId, address(agreement), franchisees, threshold, options & PERSIST_ON_COMPLETION, "nada");

        comp.begin(intervalId, 0);

        comp.ratify(intervalId, 0);
        them.forwardCall(address(comp), abi.encodeWithSignature(ratifySignature, intervalId, 0));

        return SUCCESS;
    }

}

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
