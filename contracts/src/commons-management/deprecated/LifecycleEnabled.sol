pragma solidity ^0.4.25;

/**
 * @title LifecycleEnabled
 * @dev Contract to participate in the lifecycle management.
 */
contract LifecycleEnabled {

    address lifecycleOwner;

	/**
	 * @dev Sets the lifecycle owner to the given address
	 * @param _address the new owner
	 */
    function setLifecycleOwner(address _address) public {
        lifecycleOwner = _address;
    }

}