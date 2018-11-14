pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";
import "commons-standards/AbstractERC165.sol";

import "commons-management/ContractLocator.sol";
import "commons-management/ContractChangeListener.sol";

/**
 * @title ContractLocatorEnabled
 * @dev To be inherited by contracts that need to look up other contracts by name and
 * register themselves with a ContractLocator.
 */
contract ContractLocatorEnabled is AbstractERC165, ContractChangeListener {
	
	bytes4 public constant ERC165_ID_ContractLocatorEnabled = bytes4(keccak256(abi.encodePacked("setContractLocator(address)")));

	ContractLocator locator;
	
    /**
     * @dev Modifier to only allow access by the locator.
     */
    modifier pre_onlyByLocator() {
        ErrorsLib.revertIf(msg.sender != address(locator),
			ErrorsLib.UNAUTHORIZED(), "ContractLocatorEnabled.pre_onlyByLocator()", "msg.sender is not the locator");
        _;
    }

	/**
	 * @dev Internal constructor to enforce abstract charactoer of the contract.
	 */
	constructor() internal {
		addInterfaceSupport(ERC165_ID_ContractLocatorEnabled);
	}

	/**
	 * @dev Allows setting the ContractLocator address, if it hadn't been set before. Only the currently registered locator
	 * is allowed to replace itself.
	 * REVERTS if:
	 * - the locator is already set and the msg.sender is not the current locator
	 */
	function setContractLocator(address _locator) public {
        // Once the locator address is set, don't allow it to be set again,
		// except by the locator contract itself.
        ErrorsLib.revertIf(address(locator) != 0x0 && msg.sender != address(locator),
			ErrorsLib.OVERWRITE_NOT_ALLOWED(), "ContractLocatorEnabled.setContractLocator(address)", "Replacing an existing locator is only allowed by that locator");
		locator = ContractLocator(_locator);
	}
    
}