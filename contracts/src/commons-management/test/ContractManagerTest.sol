pragma solidity ^0.4.25;

import "commons-base/SystemOwned.sol";
import "commons-base/Versioned.sol";
import "commons-standards/ERC165Utils.sol";

import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/ContractLocatorEnabled.sol";
import "commons-management/ContractManager.sol";
import "commons-management/DefaultContractManager.sol";
import "commons-management/ContractManagerDb.sol";
import "commons-management/ContractChangeListener.sol";

contract ContractManagerTest {

    string keyService1 = "io.monax/agreements-network/services/Service1";
    string keyService2 = "io.monax/agreements-network/services/Service2";

    // the ERC165 ID of ContractLocatorEnabled
    bytes4 constant ERC165_ID_ContractLocatorEnabled = bytes4(keccak256(abi.encodePacked("setContractLocator(address)")));

    function testContractManager() external returns (string) {

        // Setup
        ContractManagerDb contractsDb = new ContractManagerDb();
        if (contractsDb.getSystemOwner() != address(this)) return "DB should have this contract as systemOwner";
        DefaultContractManager mgr = new DefaultContractManager();
        if (mgr.getUpgradeOwner() != address(this)) return "Manager should have this contract as upgradeOwner";
        contractsDb.transferSystemOwnership(mgr);
        if (!mgr.acceptDatabase(contractsDb)) return "DB not accepted in manager";

        TestServiceWithDependency s1 = new TestServiceWithDependency([1,0,0]);
        DefaultTestService s2 = new DefaultTestService([1,2,0]);
        ServiceDb service1Db = new ServiceDb(s1);
        ServiceDb service2Db = new ServiceDb(s2);
        s1.acceptDatabase(service1Db);
        s2.acceptDatabase(service2Db);

        // deploy service A which tries to lookup non-existent service B
        // this needs to be done via a delegatecall to be able to catch the throw
        if (safeAddContract(mgr, keyService1, s1))
            return "Adding service1 one should fail due to unfulfilled dependency to service2";
        if (mgr.getNumberOfContracts() > 0) return "There should be no contract after service1 failure";

        if (mgr.addContract(keyService2, s2) != 1) return "Adding service1 should succeed and return size 1";
        // new re-attempt to register service1
        if (mgr.addContract(keyService1, s1) != 2) return "Adding service1 should succeed and return size 1";
        if (s1.getContractLocator() != address(mgr)) return "ContractLocator on service1 should be set";
        if (s1.getDependency1() != address(s2)) return "Dependency on service2 should be set in service1";
        address[] memory listeners = contractsDb.getContractChangeListeners(keyService2);
        if (listeners.length != 1) return "There should be 1 change listener for service2";
        if (listeners[0] != address(s1)) return "Service1 should be a change listener for service2";

        // perform an update to service 2 and check if dependencies were updated
        DefaultTestService s2_1 = new DefaultTestService([2,4,0]);
        if (mgr.addContract(keyService2, s2_1) != 2) return "The number of contracts should still be 2 after updating service2";
        if (s1.getDependency1() != address(s2_1)) return "Dependency on service2 in service1 should've been updated to service2_1";

        // perform an upgrade to service 1 and check if dependency to service2 is intact as well as listener 
        TestServiceWithDependency s1_1 = new TestServiceWithDependency([2,0,0]);
        if (mgr.addContract(keyService1, s1_1) != 2) return "The number of contracts should still be 2 after updating service1";
        if (s1.getDependency1() != address(s2_1)) return "Dependency on service2 in service1_1 should point to latest service2_1";

        // finally, upgrade ContractManager to a new version and verify that all contracts are pointing to the new ContractLocator
        NewVersionContractManager mgrNew = new NewVersionContractManager();
        if (mgrNew.major() != uint8(8) && mgrNew.minor() != uint8(3) && mgrNew.patch() != uint8(2)) return "NewVersionContractManager does not have the right version";

        if (!mgr.upgrade(mgrNew)) return "Upgrading to a new ContractManager should succeed";

        address addr;
        for (uint i=0; i<contractsDb.getNumberOfContracts(); i++) {
            addr = contractsDb.getContract(contractsDb.getContractKeyAtIndex(i));
            if (ERC165Utils.implementsInterface(addr, ERC165_ID_ContractLocatorEnabled)) {
                // at this point we can assume we're dealing with a test service contract defined below that actually uses a contractLocator
                if (TestServiceWithDependency(addr).getContractLocator() != address(mgrNew))
                    return "ContractLocatorEnabled services should point to the new ContractManager";
            }
        }
        
        return "success";
    }

    function safeAddContract(address _contractManager, string _name, address _service) internal returns (bool) {
        return _contractManager.call(bytes4(keccak256(abi.encodePacked("addContract(string,address)"))), _name, _service);
    }
}

/**
 * @dev A versioned service implementation with an upgradeable DB
 */
contract DefaultTestService is Versioned, AbstractDbUpgradeable {

    constructor(uint8[3] _version) Versioned(_version[0], _version[1], _version[2]) public {

    }

    function getDatabase() public view returns (address) {
        return database;
    }
}

/**
 * @dev Extends the DefaultTestService with capabilities for dependency injection via a ContractLocator
 */
contract TestServiceWithDependency is DefaultTestService, ContractLocatorEnabled {

    address dependency1;
    string dep1Name = "io.monax/agreements-network/services/Service2";

    constructor(uint8[3] _version) DefaultTestService(_version) {

    }

    function contractChanged(string _name, address, address _newAddress) external pre_onlyByLocator {
        if (keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(dep1Name))){
            dependency1 = _newAddress;
        }
    }

    function setContractLocator(address _locator) public {
        super.setContractLocator(_locator);
        dependency1 = ContractLocator(_locator).getContract(dep1Name);
        require(dependency1 != 0x0, "dependency not found");
        ContractLocator(_locator).addContractChangeListener(dep1Name);
    }

    function getDependency1() public view returns (address) {
        return dependency1;
    }

    function getContractLocator() public view returns (address) {
        return locator;
    }
}

contract ServiceDb is SystemOwned {

    constructor(address _systemOwner) public {
        systemOwner = _systemOwner;
    }

}

/**
 * ContractManager with a higher version to test manager upgrades.
 */
contract NewVersionContractManager is DefaultContractManager {

    constructor() public DefaultContractManager() {
        semanticVersion = [8,3,2]; // overriding DefaultContractManager version
    }

}