pragma solidity ^0.4.25;

import "commons-auth/Ecosystem.sol";
import "commons-auth/DefaultEcosystem.sol";
import "commons-auth/EcosystemRegistry.sol";
import "commons-auth/DefaultEcosystemRegistry.sol";
import "commons-auth/EcosystemRegistryDb.sol";
import "commons-management/ArtifactsFinderEnabled.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";
import "commons-management/AbstractDbUpgradeable.sol";

contract EcosystemTest {
	
	string constant SUCCESS = "success";

	ArtifactsRegistry artifactsRegistry;

	Ecosystem defaultEcosystemImpl = new DefaultEcosystem();

	constructor () public {
		// ArtifactsRegistry
		artifactsRegistry = new DefaultArtifactsRegistry();
	}

	/**
	 * This function can be used in the beginning of a test to have a fresh BpmService instance.
	 */
	function createNewEcosystemRegistry() internal returns (EcosystemRegistry newRegistry) {
		EcosystemRegistryDb registryDb = new EcosystemRegistryDb();
		newRegistry = new DefaultEcosystemRegistry();
		registryDb.transferSystemOwnership(newRegistry);
		AbstractDbUpgradeable(newRegistry).acceptDatabase(registryDb);
		ArtifactsFinderEnabled(newRegistry).setArtifactsFinder(artifactsRegistry);
        artifactsRegistry.registerArtifact(newRegistry.OBJECT_CLASS_ECOSYSTEM(), address(defaultEcosystemImpl), defaultEcosystemImpl.getArtifactVersion(), true);
	}

	/**
	 * @dev Tests the functions of a single Ecosystem
	 */
	function testEcosystemLifecycle() external returns (string) {

		Ecosystem ecosystem = new DefaultEcosystem();
		ecosystem.initialize();
		ecosystem.addExternalAddress(this);
		if (!ecosystem.isKnownExternalAddress(this)) return "Ecosystem should detect registered address as known address";
		if (ecosystem.isKnownExternalAddress(msg.sender)) return "Ecosystem should detect unknown address";

		return SUCCESS;
	}

	/**
	 * @dev Tests the EcoystemRegistry
	 */
	function testEcosystemRegistry() external returns (string) {

		EcosystemRegistry registry = createNewEcosystemRegistry();

		address ecosystemAddress = registry.createEcosystem("MyEcosystem");
		if (ecosystemAddress == address(0)) return "Ecosystem not created successfully";
		if (address(registry).call( bytes4(keccak256(abi.encodePacked("registerEcosystem(string,address)"))), "MyEcosystem", this))
			return "It should not be possible to register an ecosystem with an already taken name";

		return SUCCESS;
	}

}