pragma solidity ^0.4.25;

import "commons-standards/ERC165Utils.sol";

import "./LifecycleHub.sol";
import "./DefaultContractLocator.sol";
import "./DefaultLifecycleModule.sol";

/**
 * @title DefaultLifecycleHub
 * @dev Default implementation of the LifecycleHub interface
 */
contract DefaultLifecycleHub is LifecycleHub, DefaultLifecycleModule, DefaultContractLocator {

	/**
	 * @dev Creates a new DefaultLifecycleHub with the given version
	 * @param _version UINT8 array in the form of [maj, min, patch]
	 */
    constructor(uint8[3] _version) DefaultLifecycleModule(_version) DefaultContractLocator() public {

    }
    
    /**
     * @dev Overwrites HierarchyEnabled.addChild()
	 * @return BaseErrors.INVALID_TYPE() if the address is not a LifecycleModule
	 * @return BaseErrors.NO_ERROR() if sucessfull
     */
    function addChild(address _module) public returns (uint error) {
		// only accept LifecycleModule
		if (!ERC165Utils.implementsInterface(_module, ERC165_ID_LifecycleModule)) {
			return BaseErrors.INVALID_TYPE();
		}
		error = super.addChild(_module);
		if (error == BaseErrors.NO_ERROR()) {
			bytes32 name;
			address addr;
			for (uint i=0; i<LifecycleModule(_module).getNumberOfRegistrationContracts(); i++) {
				(name, addr) = LifecycleModule(_module).getRegistrationContract(i);
				addContractInternal(name, addr);
			}
			// TODO if the registration failed, the child should be removed since it can be assumed to not be fully functioning. Needs remove() function on HiearchyEnabled.
		}
    }
   
}