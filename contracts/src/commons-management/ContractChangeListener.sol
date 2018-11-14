pragma solidity ^0.4.25;

/**
 * @title ContractChangeListener
 * @dev Interface for contracts to subscribe to update events from a ContractLocator about changes to registered contracts.
 */
contract ContractChangeListener {

    // the ERC165 ID of ContractChangeListener
    bytes4 constant ERC165_ID_ContractChangeListener = bytes4(keccak256(abi.encodePacked("contractChanged(string,address,address)")));

    /**
     * @dev Signals to the implementing contract that the registered contract with the specified name has changed from the old address to the new
     * @param _name the name under which the contract is known
     * @param _oldAddress the former address registered under that name
     * @param _newAddress the new address registered under that name
     */
    function contractChanged(string _name, address _oldAddress, address _newAddress) external;

}