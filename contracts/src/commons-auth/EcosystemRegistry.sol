pragma solidity ^0.4.25;

import "commons-management/Upgradeable.sol";
import "commons-management/ObjectFactory.sol";

/**
 * @title EcosystemRegistry Interface
 * @dev The interface describing interaction with an Ecosystem
 */
contract EcosystemRegistry is ObjectFactory, Upgradeable {

    /**
     * @dev Registers the given Ecosystem in this registry.
     * @param _name the name under which to register the Ecosystem
     * @param _ecosystem the address of an Ecosystem
     */
    function registerEcosystem(string _name, address _ecosystem) external;

    /**
     * @dev Creates a new Ecosystem with the given name.
     * @param _name the name under which to register the Ecosystem
     * @return the address of the new Ecosystem
     */
    function createEcosystem(string _name) external returns (address);
}