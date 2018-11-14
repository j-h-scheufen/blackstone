pragma solidity ^0.4.25;

import "commons-management/DOUG.sol";
import "commons-management/DefaultDoug.sol";
import "commons-management/ContractLocator.sol";
import "commons-management/ContractManagerDb.sol";
import "commons-management/DefaultContractManager.sol";

import "commons-management/test/TestService.sol";

contract DougTest {

    string keyService1 = "io.monax/agreements-network/services/TestService1";
    string keyService2 = "io.monax/agreements-network/services/TestService2";
    string keyService3 = "io.monax/agreements-network/services/TestService3";

    function testServiceDeployment() external returns (string) {

        ContractManagerDb contractsDb = new ContractManagerDb();
        DefaultContractManager contractMgr = new DefaultContractManager();
        contractsDb.transferSystemOwnership(contractMgr);
        contractMgr.acceptDatabase(contractsDb);

        DefaultDoug doug = new DefaultDoug();
        contractMgr.transferSystemOwnership(doug);
        contractMgr.transferUpgradeOwnership(doug);
        doug.setContractManager(contractMgr);

        TestService s1 = new TestService([1,0,0], "");
        TestService s2 = new TestService([2,0,0], keyService1); // service2 depends on service1
        TestService s3 = new TestService([3,0,0], keyService2); // service3 depends on service2

        s1.transferUpgradeOwnership(doug);
        s2.transferUpgradeOwnership(doug);
        s3.transferUpgradeOwnership(doug);
        if (!doug.deployContract(keyService1, s1)) return "Deployment of TestService1 should succeed";
        if (!doug.deployContract(keyService2, s2)) return "Deployment of TestService2 should succeed";
        if (!doug.deployContract(keyService3, s3)) return "Deployment of TestService3 should succeed";

        address[] memory listeners;
        listeners = contractsDb.getContractChangeListeners(keyService1);
        if (listeners.length != 1 && listeners[0] != address(s2)) return "TestService2 should be registered to listen for changes to TestService1";
        listeners = contractsDb.getContractChangeListeners(keyService2);
        if (listeners.length != 1 && listeners[0] != address(s3)) return "TestService3 should be registered to listen for changes to TestService2";

        if (s1.dependencyService() != 0x0) return "TestService1 should have no dependency";
        if (s2.dependencyService() != address(s1)) return "TestService2 should have s1 as dependency";
        if (s3.dependencyService() != address(s2)) return "TestService3 should have s2 as dependency";

        // test upgrading services
        TestService s2_1 = new TestService([3,1,0], keyService1);
        s2_1.transferUpgradeOwnership(doug);
        if (!doug.deployContract(keyService2, s2_1)) return "Deployment of TestService2_1 should succeed";
        if (s2_1.dependencyService() != address(s1)) return "TestService2_1 should have s1 as dependency after upgrade";
        if (s3.dependencyService() != address(s2_1)) return "TestService3 should have s2_1 as dependency after upgrade";

        listeners = contractsDb.getContractChangeListeners(keyService1);
        if (listeners.length != 1 && listeners[0] != address(s2_1)) return "TestService2_1 should now be a listener for changes to TestService1 instead of its predecessor";

        return "success";
    }

}
