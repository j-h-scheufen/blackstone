pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";
import "commons-base/Owned.sol";
import "commons-base/SystemOwned.sol";
import "commons-base/StorageDefOwner.sol";
import "commons-standards/ERC165Utils.sol";

import "commons-management/StorageDefProxied.sol";
import "commons-management/StorageDefManager.sol";
import "commons-management/DOUG.sol";
import "commons-management/ContractManager.sol";
import "commons-management/UpgradeOwned.sol";
import "commons-management/Upgradeable.sol";

/**
 * @title DefaultDoug
 * @dev Standard DOUG implementation.
 * NOTE: This contract is intended to by used in conjunction with a DougProxy.
 * Therefore, the order of storage variables _must_ match the one in the DougProxy. This is
 * partly achieved by using the same StorageDef* contracts as a basis.
 */
contract DefaultDoug is StorageDefProxied, StorageDefOwner, StorageDefManager, Owned, DOUG {

	/**
	 * @dev Creates a new DefaultDoug with the msg.sender set to be the owner
	 */
	constructor() public {
		owner = msg.sender;
	}

    /**
     * @dev Allows the owner of this DefaultDoug to set or upgrade the ContractManager.
	 * REVERTS if:
	 * - this contract is not the system owner of the provided ContractManager
	 * - this contract is not the upgrade owner of the provided ContractManager
	 * @param _contractManager a ContractManager address 
     */
    function setContractManager(address _contractManager) external pre_onlyByOwner {
		ErrorsLib.revertIf(SystemOwned(_contractManager).getSystemOwner() != address(this),
			ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultDoug.setContractManager", "DOUG must be systemOwner of the ContractManager");
		ErrorsLib.revertIf(UpgradeOwned(_contractManager).getUpgradeOwner() != address(this),
			ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultDoug.setContractManager", "DOUG must be upgradeOwner of the ContractManager");
		if (manager != 0x0) {
			ErrorsLib.revertIf(!Upgradeable(manager).upgrade(_contractManager),
				"", "DefaultDoug.setContractManager", "Failed to upgrade from an existing ContractManager");
		}
		manager = _contractManager;
	}

	/**
     * @dev Registers the contract with the given address under the specified ID and performs a deployment
     * procedure which involves dependency injection and upgrades from previously deployed contracts with
     * the same ID.
	 * If the given contract implements ContractLocatorEnabled, it will be passed an instance of the ContractManager, so that
	 * it can perform dependency lookups and register for changes.
	 * REVERTS if:
	 * - the provided contract is Upgradeable, but this DOUG contract is not the upgradeOwner
	 * - a contract with the same ID is being replaced, but the upgrade between predecessor and successor failed (see Upgradeable.upgrade(address))
     * @param _id the ID under which to register the contract
     * @param _address the address of the contract
     * @return true if successful, false otherwise
	 */
    function deployContract(string _id, address _address) external pre_onlyByOwner returns (bool success) {
		if (ERC165Utils.implementsInterface(_address, getERC165IdUpgradeable())) {
		ErrorsLib.revertIf(UpgradeOwned(_address).getUpgradeOwner() != address(this),
			ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultDoug.deployContract", "DOUG must be upgradeOwner of the provided contract");
		}
		address existing = ContractManager(manager).getContract(_id);
		if (existing != 0x0 && ERC165Utils.implementsInterface(existing, getERC165IdUpgradeable())) {
			ErrorsLib.revertIf(!Upgradeable(existing).upgrade(_address),
				ErrorsLib.INVALID_STATE(), "DefaultDoug.deployContract", "Failed to upgrade from an existing contract with the same ID");
		}
		ContractManager(manager).addContract(_id, _address);
		success = true;
	}

    /**
     * @dev Returns the address of a contract registered under the given ID.
     * @param _id the ID under which the contract is registered
     * @return the contract's address
     */
    function lookupContract(string _id) external view returns (address contractAddress) {
		contractAddress = ContractManager(manager).getContract(_id);
	}

	/**
	 * @dev Returns the address of the ContractManager used in this DefaultDoug
	 * @return the address or 0x0 if it hasn't been set
	 */
	function getContractManager() external view returns (address) {
		return manager;
	}

	/**
	 * @dev Internal pure function to return the ERC165 ID for the Upgreadable interface
	 * This avoids storing the ID as a field in this contract which would not be usable in a proxied scenario.
	 */
	function getERC165IdUpgradeable() internal pure returns (bytes4) {
		return bytes4(keccak256(abi.encodePacked("upgrade(address)")));
	}
}