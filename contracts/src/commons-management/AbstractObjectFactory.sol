pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";

import "commons-management/ObjectFactory.sol";

/**
 * @title AbstractObjectFactory
 * @dev The abstract implementation for a contract able to produce upgradeable objects belonging to an object class.
 */
contract AbstractObjectFactory is ObjectFactory {

	address artifactsRegistry;

	constructor() internal {}

}