pragma solidity ^0.4.25;

import "commons-management/ContractLocator.sol";

/**
 * @title ObjectFactory
 * @dev The interface for a contract able to produce upgradeable objects belonging to an object class.
 */
contract ObjectFactory {

	bytes4 constant ERC165_ID_ObjectFactory = bytes4(keccak256(abi.encodePacked("setDoug(address)")));

	/**
	 * @dev Sets the DOUG address from where object class information is looked up.
	 * @param _dougAddress the address of a DOUG contract
	 */
	function setDoug(address _dougAddress) external;

}