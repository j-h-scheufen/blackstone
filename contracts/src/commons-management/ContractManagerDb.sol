pragma solidity ^0.4.25;

import "commons-base/BaseErrors.sol";
import "commons-base/SystemOwned.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";

/**
 * @title ContractsManagerDb
 * @dev Database contract to manage the data for a ContractsManager
 */
contract ContractManagerDb is SystemOwned {

    using MappingsLib for Mappings.StringAddressMap;
	using MappingsLib for Mappings.Bytes32AddressArrayMap;

    // Contract reference storage
	Mappings.StringAddressMap contractRegistry;
    // Change listeners
	Mappings.Bytes32AddressArrayMap listeners;

    /**
     * @dev Creates a new ContractsManagerDb and sets the msg.sender as the systemOwner
     */
    constructor() public {
        systemOwner = msg.sender;
    }

    /**
     * @dev Registers the given contract address under the specified name. An existing address at
     * the same name will be overwritten.
     * @param _name the registration key
     * @param _address the contract's address to be registered
     * @return the number of registered contracts after the specified contract was inserted
     */
    function addContract(string _name, address _address) external pre_onlyBySystemOwner returns (uint size) {
		return contractRegistry.insertOrUpdate(_name, _address);
    }

    /**
     * @dev Adds the specified listener for change events to the specified contract name, if it exists.
     * @param _name the name of the contract to subscribe to
     * @param _listener the address of the listener
     */
    function addContractChangeListener(string _name, address _listener) external pre_onlyBySystemOwner {
        if (contractRegistry.exists(_name)) {
            listeners.addToArray(keccak256(abi.encodePacked(_name)), _listener, true);
        }
    }

    /**
     * @dev Removes the specified listener from the list of listeners for the specified contract name.
     * @param _name the name of the contract to unsubscribe from
     * @param _listener the address of the listener
     */
    function removeContractChangeListener(string _name, address _listener) external pre_onlyBySystemOwner {
        listeners.removeFromArray(keccak256(abi.encodePacked(_name)), _listener, false);
    }

    /**
     * @dev Returns the listeners subscribed to the given contract name
     * @param _name the name of a registered contract
     * @return the listeners as address[]
     */
    function getContractChangeListeners(string _name) external view returns (address[]) {
        return listeners.get(keccak256(abi.encodePacked(_name)));
    }

	/**
	 * @dev Returns the address of a registered contract
	 *
	 * @param _name the registered key
	 * @return the contract address or 0x0, if it does not exist
	*/
	function getContract(string _name) external view returns (address contractAddress) {
		contractAddress = contractRegistry.get(_name);
	}

	/**
	 * @dev Returns the number of registered contracts.
	 * @return the number of contracts in this ContractManager
	 */
	function getNumberOfContracts() external view returns (uint size) {
        size = contractRegistry.keys.length;
    }

	/**
	 * @dev Returns the primary key of the contract at the given index
	 * @param _index the index position
	 * @return the string key
	 */
	function getContractKeyAtIndex(uint _index) external view returns (string primaryKey) {
        primaryKey = contractRegistry.keys[_index];
    }

	/**
	 * @dev Returns detailed data for the contract with the given key
	 * @param _key the string key
	 * @return contractAddress - contract's address
	 */
	function getContractDetails(string _key) external view returns (address contractAddress) {
        contractAddress = contractRegistry.get(_key);
    }

}