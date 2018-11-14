pragma solidity ^0.4.25;

import "commons-management/DOUG.sol";
import "commons-management/DefaultContractManager.sol";
import "commons-management/ContractManagerDb.sol";
import "commons-management/Upgradeable.sol";

/**
 * @title TestDoug
 * @dev DOUG implementation to be used in testing scenarios.
 */
contract TestDoug is DOUG, DefaultContractManager {

	constructor() public {
		database = new ContractManagerDb();
	}

	/**
	 * @dev Deploys the given contract by adding it without performing any checks or upgrades from previous versions.
	 * @param _id the key under which to register the contract
	 * @param _address the contract address
	 * @return always true
	 */
    function deployContract(string _id, address _address) external returns (bool success) {
		addContract(_id, _address);
		success = true;
	}

	/**
	 * @dev Returns the address registered under the given key
	 * @param _id the key to use for lookup
	 * @return the contract address or 0x0
	 */
    function lookupContract(string _id) external view returns (address contractAddress) {
		contractAddress = ContractManagerDb(database).getContract(_id);
	}

}