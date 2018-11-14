pragma solidity ^0.4.25;

import "commons-base/Owned.sol";

/**
 * @title Destructible
 * @dev Contract to be inherited if 'selfdestruct' behavior is desired. This is the case, for example,
 * for non-entity contracts that support the management of a solution and are upgraded/replaced with a
 * new version.
 */
contract Destructible is Owned {

	/**
	 * @dev Transfers this contract's value to the owner and frees up storage
	 */
	function destroy() external pre_onlyByOwner {
	    selfdestruct(owner);
	}

    /**
     * @dev Function that can be actively checked to detect if the contract is a destructible contract.
     */
	function isDestructible() external pure returns (bool) {
	    return true;
	}
}