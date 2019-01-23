pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";

import "commons-management/ObjectFactory.sol";

/**
 * @title AbstractObjectFactory
 * @dev The interface for a contract able to produce upgradeable objects belonging to an object class.
 */
contract AbstractObjectFactory is ObjectFactory {

	address doug;

	/**
	 * @dev Sets the DOUG address from where object class information is looked up.
	 * @param _dougAddress the address of a DOUG contract
	 */
	function setDoug(address _dougAddress) external {
		ErrorsLib.revertIf(doug != address(0),
			ErrorsLib.OVERWRITE_NOT_ALLOWED(), "AbstractObjectFactory.setDoug", "DOUG address has already been set and cannot be overwritten");
		doug = _dougAddress;
	}

}