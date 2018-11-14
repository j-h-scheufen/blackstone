pragma solidity ^0.4.25;

import "commons-base/Owned.sol";
import "commons-standards/ERC165.sol";

import "./Upgradeable.sol";
import "./LifecycleEnabled.sol";
import "./HierarchyEnabled.sol";

/**
 * @title LifecycleModule
 * @dev Interface for an upgradeable container to support modular functionality within a hierarchy of other modules.
 */
contract LifecycleModule is Owned, Upgradeable, LifecycleEnabled, HierarchyEnabled, ERC165 {

	bytes4 public constant ERC165_ID_LifecycleModule = bytes4(keccak256(abi.encodePacked("getNumberOfRegistrationContracts()"))) ^
													   bytes4(keccak256(abi.encodePacked("getRegistrationContract(uint)")));

	/**
	 * @dev Is called when this module is being added to a ContractLocator, e.g. a LifecycleHub or DOUG to give the module the chance to register contracts contained in this module.
	 * @return the number of contracts
	 */
	function getNumberOfRegistrationContracts() external view returns (uint);
	
	/**
	 * @dev Returns information about the contract registered at the specified index.
	 * @return the registered name and address as (bytes32,address)
	 */
	function getRegistrationContract(uint _index) external view returns (bytes32, address);
}