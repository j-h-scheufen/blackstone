pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";
import "commons-base/Versioned.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/ContractLocatorEnabled.sol";

import "commons-auth/Ecosystem.sol";
import "commons-auth/DefaultEcosystem.sol";
import "commons-auth/EcosystemRegistry.sol";
import "commons-auth/EcosystemRegistryDb.sol";

/**
 * @title DefaultEcosystemRegistry
 * @dev Default implementation of the EcosystemRegistry interface.
 */
contract DefaultEcosystemRegistry is Versioned(1,0,0), AbstractDbUpgradeable, EcosystemRegistry {

    /**
     * @dev Registers the given Ecosystem in this registry.
     * REVERTS if:
     * - the name is already registered
     * @param _ecosystem the address of an Ecosystem
     */
    function registerEcosystem(string _name, address _ecosystem) external {
        ErrorsLib.revertIf(EcosystemRegistryDb(database).ecosystemExists(_name),
            ErrorsLib.OVERWRITE_NOT_ALLOWED(), "DefaultEcosystemRegistry.registerEcosystem", "An ecosystem with the same name is already registered");
        EcosystemRegistryDb(database).addEcosystem(_name, _ecosystem);
    }

    /**
     * @dev Creates a new Ecosystem with the given name.
     * REVERTS if:
     * - the name is already registered
     * @param _name the name under which to register the Ecosystem
     * @return the address of the new Ecosystem
     */
    function createEcosystem(string _name) external returns (address) {
        ErrorsLib.revertIf(EcosystemRegistryDb(database).ecosystemExists(_name),
            ErrorsLib.OVERWRITE_NOT_ALLOWED(), "DefaultEcosystemRegistry.registerEcosystem", "An ecosystem with the same name is already registered");
        Ecosystem ecosystem = new DefaultEcosystem();
        ecosystem.transferOwnership(msg.sender);
        EcosystemRegistryDb(database).addEcosystem(_name, ecosystem);
        return address(ecosystem);
    }

}