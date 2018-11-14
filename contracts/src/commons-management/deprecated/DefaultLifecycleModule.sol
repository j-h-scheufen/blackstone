pragma solidity ^0.4.25;

import "commons-base/BaseErrors.sol";
import "commons-standards/AbstractERC165.sol";

import "./LifecycleModule.sol";

/**
 * @title DefaultLifecycleModule
 * @dev Default implementation of the LifecycleModule interface
 */
contract DefaultLifecycleModule is AbstractERC165, LifecycleModule {

	/**
	 * @dev Creates a new DefaultLifecycleModule and sets the msg.sender as owner
	 * @param _version UINT8 array in the form of [maj, min, patch]
	 */
    constructor(uint8[3] _version) Versioned(_version[0], _version[1], _version[2]) public {
        owner = msg.sender;
		addInterfaceSupport(ERC165_ID_LifecycleModule);
		// commented out due to compiler warnings for using "this" in constructor
		// addInterfaceSupport(this.getNumberOfRegistrationContracts.selector ^ this.getRegistrationContract.selector);
    }
	
	/**
	 * @dev Default implementation of Upgradeable.migrateFrom(address).
	 * @return BaseErrors.UNSUPPORTED_OPERATION()
	 */
    function migrateFrom(address /*_predecessor*/) public returns (uint error) { return BaseErrors.UNSUPPORTED_OPERATION(); }

	/**
	 * @dev Default implementation of Upgradeable.migrateTo(address).
	 * @return BaseErrors.UNSUPPORTED_OPERATION()
	 */
    function migrateTo(address /*_successor*/) public returns (uint error) { return BaseErrors.UNSUPPORTED_OPERATION(); }

	/**
	 * @dev Returns the number of contracts registered in this module
	 * @return 0
	 */
	function getNumberOfRegistrationContracts() external view returns (uint) { return 0; }
	
	/**
	 * @dev Returns information about the contract registered at the specified index
	 * @return ("", 0x0)
	 */
	function getRegistrationContract(uint /*_index*/) external view returns (bytes32, address) { return ("", 0x0); }

}