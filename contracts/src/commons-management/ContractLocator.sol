pragma solidity ^0.4.23;

/**
 * @title ContractLocator Interface
 * @dev Interface to look up contracts by name and register for changes.
 */
interface ContractLocator {
	
	/**
	 * @dev returns the address of the contract registered under the specified name.
	 * @param _name the registered name
	 * @return the address of the contract or 0x0
	 */
	function getContract(string _name) external view returns (address);

	/**
	 * @dev Adds the msg.sender as a listener for change events for the contract registered with the given name
	 * @param _name the key under which the contract is registered
	 */
	function addContractChangeListener(string _name) external;

	/**
	 * @dev Removes the msg.sender from the list of listeners for the contract with the given name
	 * @param _name the key under which the contract is registered
	 */
	function removeContractChangeListener(string _name) external;

}