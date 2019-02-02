pragma solidity ^0.4.25;

import "commons-base/Owned.sol";

/**
 * @title UserAccount Interface
 * @dev API for interacting with a user account
 */
contract UserAccount is Owned {

   event LogUserCreation(
        bytes32 indexed eventId,
        address userAccountAddress,
        address owner
    );

	/**
	 * @dev Event IDs
	 */
    bytes32 public constant EVENT_ID_USER_ACCOUNTS = "AN://user-accounts";

    /**
     * @dev Forwards a call to the specified target using the given bytes message.
     * @param _target the address to call
     * @param _payload the function payload consisting of the 4-bytes function hash and the abi-encoded function parameters
     * @return success - whether the forwarding call returned normally
     * @return returnData - the bytes returned from calling the target function
     */
    function forwardCall(address _target, bytes _payload) external returns (bool success, bytes returnData);

}
