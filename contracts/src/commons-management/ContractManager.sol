pragma solidity ^0.4.25;

import "commons-management/ContractLocator.sol";

/**
 * @title ContractManager
 * @dev The interface for a contract-managing contract (CMC) that provides contract registration and lookup funcionality.
 */
contract ContractManager is ContractLocator {

	/**
	 * @dev Adds the specified contract address to the locator under the given name.
	 * @param _name the name to register
	 * @param _address the contract address
	 * @return the number of contracts registered after this operation
	 */
	function addContract(string _name, address _address) public returns (uint size);

	/**
	 * @dev Returns the number of registered contracts.
	 * @return the number of contracts in this ContractManager
	 */
	function getNumberOfContracts() external view returns (uint size);

	/**
	 * @dev Returns the primary key of the contract at the given index
	 * @param _index the index position
	 * @return the string key under which the contract is registered
	 */
	function getContractKeyAtIndex(uint _index) external view returns (string primaryKey);

	/**
	 * @dev Returns detailed data for the contract with the given key
	 * @param _key the string key
	 * @return contractAddress - contract's address
     * @return version - the semantic version, if the contract supports the Versioned interface
	 */
	function getContractDetails(string _key) external view returns (address contractAddress, uint8[3] version);

}