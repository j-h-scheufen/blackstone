pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";
import "commons-base/SystemOwned.sol";
import "commons-standards/ERC165Utils.sol";

import "commons-management/ContractManager.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/ContractLocatorEnabled.sol";
import "commons-management/ContractChangeListener.sol";
import "commons-management/ContractManagerDb.sol";

/**
 * @title DefaultContractManager
 * @dev This contract implements the CMC (Contract Management Contract) approach to 
 * allow registration of other contracts by name and therefore facilitate the
 * communication between them, e.g. as part of a group.
 */
contract DefaultContractManager is Versioned(1,0,0), SystemOwned, AbstractDbUpgradeable, ContractManager {

    bytes4 constant ERC165_ID_ContractLocatorEnabled = bytes4(keccak256(abi.encodePacked("setContractLocator(address)")));
	bytes4 constant ERC165_ID_Versioned = bytes4(keccak256(abi.encodePacked("getVersion()")));
	bytes4 constant ERC165_ID_Upgradeable = bytes4(keccak256(abi.encodePacked("upgrade(address)")));

    /**
     * @dev Creates a new DefaultContractManager and sets the msg.sender as the systemOwner.
     */
    constructor() public {
        systemOwner = msg.sender;
    }

    /**
     * @dev Allows the systemOwner to add the given contract address under the specified name. An existing address at
     * the same name will be overwritten. If the provided contract implements ContractLocatorEnabled, this
     * ContractManager attempts to set itself as the ContractLocator and a REVERT is triggered, if setting the ContractLocator
     * was unsuccessful.
     * @param _name the registration key
     * @param _contract the contract's address to be registered
     * @return the number of registered contracts after the specified contract was inserted
     */
    function addContract(string _name, address _contract) pre_onlyBySystemOwner public returns (uint size) {
        // TODO since we're calling into the added contract, this function needs a re-entrancy guard
        ErrorsLib.revertIf(bytes(_name).length == 0,
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultContractsManager.addContract", "The name parameter must not be empty");
        ErrorsLib.revertIf(_contract == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultContractsManager.addContract", "The contract address parameter must not be empty");
        // setting contract locator gives the contract the chance to bootstrap, load dependencies, and initialize
        if (ERC165Utils.implementsInterface(_contract, ERC165_ID_ContractLocatorEnabled)) {
            ContractLocatorEnabled(_contract).setContractLocator(this);
        }
        address current = ContractManagerDb(database).getContract(_name);
	    size = ContractManagerDb(database).addContract(_name, _contract);
        // inform change listeners of the updated address
        if (current != _contract) {
            address[] memory changeListeners = ContractManagerDb(database).getContractChangeListeners(_name);
            for (uint i=0; i<changeListeners.length; i++) {
                ContractChangeListener(changeListeners[i]).contractChanged(_name, current, _contract);
            }
        }
    }
	
    /**
     * @dev Upgrades this DefaultContractManager to the specified successor by transfering control over the database
     * and updating the contractLocator reference in all managed contracts that implement ContractLocatorEnabled.
     * @param _successor the new version of DefaultContractsManager
     * @return true if successful, otherwise a REVERT is triggered to rollback any changes of the upgrade
     */
    function upgrade(address _successor) public pre_onlyByUpgradeOwner pre_higherVersionOnly(_successor) returns (bool success) {
        require(super.upgrade(_successor));
        address addr;
        for (uint i=0; i<ContractManagerDb(database).getNumberOfContracts(); i++) {
            addr = ContractManagerDb(database).getContract(ContractManagerDb(database).getContractKeyAtIndex(i));
            // update contract locator reference in all managed contracts that signal support
            if (ERC165Utils.implementsInterface(addr, ERC165_ID_ContractLocatorEnabled)) {
                ContractLocatorEnabled(addr).setContractLocator(_successor);
            }
        }
        success = true;
    }

	/**
	 * @dev Adds the msg.sender as a listener for change events for the contract registered with the given name.
	 * @param _name the key under which the contract is registered
	 */
	function addContractChangeListener(string _name) external {
        ContractManagerDb(database).addContractChangeListener(_name, msg.sender);
    }

	/**
	 * @dev Removes the msg.sender from the list of listeners for the contract with the given name
	 * @param _name the key under which the contract is registered
	 */
	function removeContractChangeListener(string _name) external {
        ContractManagerDb(database).removeContractChangeListener(_name, msg.sender);
    }

	/**
	 * @dev Returns the address of a registered contract
	 *
	 * @param _name the registered key
	 * @return the contract address or 0x0, if it does not exist
	*/
	function getContract(string _name) external view returns (address contractAddress) {
		contractAddress = ContractManagerDb(database).getContract(_name);
	}

	/**
	 * @dev Returns the number of registered contracts.
	 * @return the number of contracts in this ContractManager
	 */
	function getNumberOfContracts() external view returns (uint size) {
        size = ContractManagerDb(database).getNumberOfContracts();
    }

	/**
	 * @dev Returns the primary key of the contract at the given index
	 * @param _index the index position
	 * @return the string key
	 */
	function getContractKeyAtIndex(uint _index) external view returns (string primaryKey) {
        primaryKey = ContractManagerDb(database).getContractKeyAtIndex(_index);
    }

	/**
	 * @dev Returns detailed data for the contract with the given key
	 * @param _key the string key
	 * @return contractAddress - contract's address
     * @return version - the semantic version, if the contract supports the Versioned interface
	 */
	function getContractDetails(string _key) external view returns (address contractAddress, uint8[3] version) {
        contractAddress = ContractManagerDb(database).getContractDetails(_key);
        if (ERC165Utils.implementsInterface(contractAddress, ERC165_ID_Versioned)) {
            version = Versioned(contractAddress).getVersion();
        }
    }

}