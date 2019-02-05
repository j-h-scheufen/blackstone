pragma solidity ^0.4.25;

import "commons-management/DOUG.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";
import "commons-management/Upgradeable.sol";

/**
 * @title TestDoug
 * @dev DOUG implementation to be used in testing scenarios.
 */
contract TestDoug is DOUG {

	ArtifactsRegistry registry = new DefaultArtifactsRegistry();

	/**
	 * @dev Deploys the given contract by adding it without performing any checks or upgrades from previous versions.
	 * @param _id the key under which to register the contract
	 * @param _address the contract address
	 * @return always true
	 */
    function deploy(string _id, address _address) external returns (bool success) {
		registry.registerArtifact(_id, _address, [0,0,0], true);
		success = true;
	}

    function register(string _id, address _address) external returns (uint8[3] version) {
		registry.registerArtifact(_id, _address, [0,0,0], true);
	}

	/**
	 * @dev Returns the address registered under the given key
	 * @param _id the key to use for lookup
	 * @return the contract address or 0x0
	 */
    function lookup(string _id) external view returns (address contractAddress) {
		(contractAddress, ) = registry.getArtifact(_id);
	}

}