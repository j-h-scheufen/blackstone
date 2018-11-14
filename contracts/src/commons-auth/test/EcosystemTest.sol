pragma solidity ^0.4.25;

import "commons-auth/Ecosystem.sol";
import "commons-auth/DefaultEcosystem.sol";
import "commons-auth/DefaultEcosystemRegistry.sol";
import "commons-auth/EcosystemRegistryDb.sol";

contract EcosystemTest {
	
	string constant SUCCESS = "success";

	/**
	 * @dev Tests the functions of a single Ecosystem
	 */
	function testEcosystemLifecycle() external returns (string) {

		Ecosystem ecosystem = new DefaultEcosystem();
		ecosystem.addExternalAddress(this);
		if (!ecosystem.isKnownExternalAddress(this)) return "Ecosystem should detect registered address as known address";
		if (ecosystem.isKnownExternalAddress(msg.sender)) return "Ecosystem should detect unknown address";

		return SUCCESS;
	}

	/**
	 * @dev Tests the EcoystemRegistry
	 */
	function testEcosystemRegistry() external returns (string) {

		EcosystemRegistryDb registryDb = new EcosystemRegistryDb();
		DefaultEcosystemRegistry registry = new DefaultEcosystemRegistry();
		registryDb.transferSystemOwnership(registry);
		registry.acceptDatabase(registryDb);

		Ecosystem ecosystem = new DefaultEcosystem();
		registry.registerEcosystem("MyEcosystem", address(ecosystem));
		if (address(registry).call( bytes4(keccak256(abi.encodePacked("registerEcosystem(string,address)"))), "MyEcosystem", this))
			return "It should not be possible to register an ecosystem with an already taken name";

		return SUCCESS;
	}

}