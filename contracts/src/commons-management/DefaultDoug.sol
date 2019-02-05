pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";
import "commons-base/Versioned.sol";
import "commons-base/Owned.sol";
import "commons-base/SystemOwned.sol";
import "commons-base/StorageDefOwner.sol";
import "commons-standards/ERC165Utils.sol";

import "commons-management/StorageDefProxied.sol";
import "commons-management/StorageDefRegistry.sol";
import "commons-management/DOUG.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/ArtifactsFinderEnabled.sol";
import "commons-management/UpgradeOwned.sol";
import "commons-management/Upgradeable.sol";

/**
 * @title DefaultDoug
 * @dev Standard DOUG implementation.
 * NOTE: This contract is intended to by used in conjunction with a DougProxy.
 * Therefore, the order of storage variables _must_ match the one in the DougProxy. This is
 * partly achieved by using the same StorageDef* contracts as a basis.
 */
contract DefaultDoug is StorageDefProxied, StorageDefOwner, StorageDefRegistry, Owned, DOUG {

	/**
	 * @dev Creates a new DefaultDoug with the msg.sender set to be the owner
	 */
	constructor () public {
		owner = msg.sender;
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
    function deploy(string _id, address _address) external pre_onlyByOwner returns (bool success) {
		uint8[3] memory version = ERC165Utils.implementsInterface(_address, getERC165IdVersioned()) ?
			Versioned(_address).getVersion() : [0,0,0];
		(address existingArtifact, uint8[3] memory existingVersion) = ArtifactsRegistry(registry).getArtifact(_id);

		if (ERC165Utils.implementsInterface(_address, getERC165IdUpgradeable())) {
			ErrorsLib.revertIf(UpgradeOwned(_address).getUpgradeOwner() != address(this),
				ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultDoug.deploy", "DOUG must be upgradeOwner of the provided contract");
		}
		if (existingArtifact != 0x0 &&
			ERC165Utils.implementsInterface(existingArtifact, getERC165IdUpgradeable()) &&
			ERC165Utils.implementsInterface(_address, getERC165IdUpgradeable()) &&
			Versioned(existingArtifact).compareVersion(_address) > 0)
		{
			ErrorsLib.revertIf(!Upgradeable(existingArtifact).upgrade(_address),
				ErrorsLib.INVALID_STATE(), "DefaultDoug.deploy", "Failed to upgrade from an existing contract with the same ID");
		}
        // setting ArtifactsFinder gives the contract the chance to bootstrap, load dependencies, and initialize
        if (ERC165Utils.implementsInterface(_address, getERC165ArtifactsFinderEnabled())) {
            ArtifactsFinderEnabled(_address).setArtifactsFinder(registry);
        }

		ArtifactsRegistry(registry).registerArtifact(_id, _address, version, true);
		success = true;
	}

    /**
     * @dev Registers the contract with the given address under the specified ID in DOUG's ArtifactsRegistry.
	 * If the contract is not an ERC165 Versioned contract, it will be registered as version 0.0.0. This allows
	 * for simple registration scenarios of contract resources that don't need to be versioned.
	 * However, if these resources ever need to be updated, i.e. a new address should be registered under the same ID,
	 * versioning is required!
	 * REVERTS if:
	 * - the ArtifactRegistry rejects the artifact, most commonly because an artifact with the same ID
	 * and version, but a different address is already registered.
     * @param _id the ID under which to register the contract
     * @param _address the address of the contract
	 * @return version - the version under which the contract was registered.
     */
    function register(string _id, address _address) external returns (uint8[3] version) {
		if (ERC165Utils.implementsInterface(_address, getERC165IdVersioned())) {
			version = Versioned(_address).getVersion();
		}
		ArtifactsRegistry(registry).registerArtifact(_id, _address, version, true);
	}

	/**
	 * @dev Sets the given version of the artifact registered under the specified ID as active version in the ArtifactsRegistry.
	 * This function wraps the ArtifactsRegistry.setActiveVersion(string,uint8[3]) function.
	 * @param _id the ID of a registered artifact
	 * @param _version the version of the artifact which should be the active one
	 * REVERTS if:
	 * - the specified ID and version combination does not exist
	 */
	function setActiveVersion(string _id, uint8[3] _version) external {
		ArtifactsRegistry(registry).setActiveVersion(_id, _version);
	}

    /**
     * @dev Returns the address of the active version of a contract registered under the given ID.
	 * If a specific (or non-active) version of a registered contract needs to be retrieved, please use
	 * #getArtifactsRegistry().getArtifactVersion(string,uint8[3])
     * @param _id the ID under which the contract is registered
     * @return the contract's address of 0x0 if no active version for the given ID is registered.
     */
    function lookup(string _id) external view returns (address contractAddress) {
		(contractAddress, ) = ArtifactsRegistry(registry).getArtifact(_id);
	}

	/**
	 * @dev Returns the address of the ArtifactsRegistry used in this DefaultDoug
	 * @return the address of the ArtifactsRegistry
	 */
	function getArtifactsRegistry() external view returns (address) {
		return registry;
	}

	/**
	 * @dev Sets the given address to be this DOUG's ArtifactsRegistry.
	 * REVERTS if:
	 * - the ArtifactsRegistry is not a SystemOwned contract or if the system owner is not set to this DOUG.
	 * @param _artifactsRegistry the address of an ArtifactsRegistry contract
	 */
	function setArtifactsRegistry(address _artifactsRegistry) external pre_onlyByOwner {
		ErrorsLib.revertIf(SystemOwned(_artifactsRegistry).getSystemOwner() != address(this),
	    	ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultDoug.setArtifactsRegistry", "DOUG must be the system owner of the ArtifactsRegistry");
		registry = _artifactsRegistry;
	}

	/**
	 * @dev Internal pure function to return the ERC165 ID for the Upgreadable interface
	 * This avoids storing the ID as a field in this contract which would not be usable in a proxied scenario.
	 */
	function getERC165IdUpgradeable() internal pure returns (bytes4) {
		return bytes4(keccak256(abi.encodePacked("upgrade(address)")));
	}

	/**
	 * @dev Internal pure function to return the ERC165 ID for the Versioned interface
	 * This avoids storing the ID as a field in this contract which would not be usable in a proxied scenario.
	 */
	function getERC165IdVersioned() internal pure returns (bytes4) {
		return bytes4(keccak256(abi.encodePacked("getVersion()")));
	}

	/**
	 * @dev Internal pure function to return the ERC165 ID for the ArtifactsFinderEnabled interface
	 * This avoids storing the ID as a field in this contract which would not be usable in a proxied scenario.
	 */
	function getERC165ArtifactsFinderEnabled() internal pure returns (bytes4) {
		return bytes4(keccak256(abi.encodePacked("setArtifactsFinder(address)")));
	}

}