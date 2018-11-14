pragma solidity ^0.4.25;

/**
 * @title DOUG - Decentralized Organization Upgrade Guy
 * @dev DOUG is the main Singleton contract to support the lifecycle of solutions and products.
 * It serves as the single point of entry to all administrative functions.
 * Doug is a marmot that lives in Connecticut. We have named our smart contract kernel after this marmot.
 */
interface DOUG {
    
    /**
     * @dev Registers the contract with the given address under the specified ID and performs a deployment
     * procedure which involves dependency injection and upgrades from previously deployed contracts with
     * the same ID.
     * @param _id the ID under which to register the contract
     * @param _address the address of the contract
     * @return true if successful, false otherwise
     */
    function deployContract(string _id, address _address) external returns (bool success);

    /**
     * @dev Returns the address of a contract registered under the given ID.
     * @param _id the ID under which the contract is registered
     * @return the contract's address
     */
    function lookupContract(string _id) external view returns (address contractAddress);

}