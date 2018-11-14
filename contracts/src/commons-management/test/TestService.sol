pragma solidity ^0.4.25;

import "commons-management/AbstractUpgradeable.sol";
import "commons-management/ContractLocatorEnabled.sol";
import "commons-management/ContractLocator.sol";

contract TestService is AbstractUpgradeable, ContractLocatorEnabled {

    bytes32 public name;
    uint16 public status;
    string public dependencyKey;
    address public dependencyService;

    constructor(uint8[3] _v, string _depKey) public Versioned(_v[0],_v[1],_v[2]) {
        dependencyKey = _depKey;
    }

    function setName(bytes32 _name) public {
        name = _name;
    }

    function setStatus(uint16 _status) public {
        status = _status;
    }

    function setContractLocator(address _locator) public {
        super.setContractLocator(_locator);
        if (bytes(dependencyKey).length > 0) {
            dependencyService = ContractLocator(_locator).getContract(dependencyKey);
            require(dependencyService != 0x0, "dependency not found");
            ContractLocator(_locator).addContractChangeListener(dependencyKey);
        }
    }

    function contractChanged(string, address, address _contractNew) external pre_onlyByLocator {
        dependencyService = _contractNew;
    }

    function migrateFrom(address) public returns (bool success) {
        success = true;
    }

    function migrateTo(address) public returns (bool success) {
        success = true;
    }

    function upgrade(address _successor) public returns (bool success) { 
        success = super.upgrade(_successor);
        if (success && address(locator) != address(0)) {
            locator.removeContractChangeListener(dependencyKey);
        }
    }
}