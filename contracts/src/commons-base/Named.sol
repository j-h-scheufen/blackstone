pragma solidity ^0.4.25;

/**
 * @title Named Interface
 * @dev Interface definition for contracts providing a bytes32 name.
 */
interface Named {
	
	/**
	 * @dev Returns the name of this contract.
	 * @return the bytes32 name
	 */
	function getName() external view returns (string);
}