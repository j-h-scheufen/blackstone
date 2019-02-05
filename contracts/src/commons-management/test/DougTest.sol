pragma solidity ^0.4.25;

import "commons-management/DOUG.sol";
import "commons-management/DefaultDoug.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";

import "commons-management/test/TestService.sol";

contract DougTest {

    string keyService1 = "agreements-network/services/TestService1";
    string keyService2 = "agreements-network/services/TestService2";
    string keyService3 = "agreements-network/services/TestService3";

    function testServiceDeployment() external returns (string) {

        ArtifactsRegistry artifactsRegistry = new DefaultArtifactsRegistry();
        DefaultArtifactsRegistry(address(artifactsRegistry)).initialize();

        DefaultDoug doug = new DefaultDoug();
        artifactsRegistry.transferSystemOwnership(doug);
        doug.setArtifactsRegistry(address(artifactsRegistry));

        TestService s1 = new TestService([1,0,0], "");
        TestService s2 = new TestService([2,0,0], keyService1); // service2 depends on service1
        TestService s3 = new TestService([3,0,0], keyService2); // service3 depends on service2

        s1.transferUpgradeOwnership(doug);
        s2.transferUpgradeOwnership(doug);
        s3.transferUpgradeOwnership(doug);
        if (!doug.deploy(keyService1, s1)) return "Deployment of TestService1 should succeed";
        if (!doug.deploy(keyService2, s2)) return "Deployment of TestService2 should succeed";
        if (!doug.deploy(keyService3, s3)) return "Deployment of TestService3 should succeed";

        uint8[3] memory v;
        address location;
        (location, v) = artifactsRegistry.getArtifact(keyService1);
        if (location != address(s1)) return "Service1 location should be in the registry";
        if (v[0] != 1 || v[1] != 0 || v[2] != 0) return "Service1 version should be in the registry";

        (location, v) = artifactsRegistry.getArtifact(keyService2);
        if (location != address(s2)) return "Service2 location should be in the registry";
        if (v[0] != 2 || v[1] != 0 || v[2] != 0) return "Service2 version should be in the registry";

        if (s1.dependencyService() != 0x0) return "TestService1 should have no dependency";
        if (s2.dependencyService() != address(s1)) return "TestService2 should have s1 as dependency";
        if (s3.dependencyService() != address(s2)) return "TestService3 should have s2 as dependency";

        // test upgrading services
        TestService s2_1 = new TestService([3,1,0], keyService1);
        s2_1.transferUpgradeOwnership(doug);
        if (!doug.deploy(keyService2, s2_1)) return "Deployment of TestService2_1 should succeed";
        if (s2_1.dependencyService() != address(s1)) return "TestService2_1 should have s1 as dependency after upgrade";
        if (s3.dependencyService() != address(s2)) return "TestService3 should still have s2 as dependency before refresh";
        s3.refreshDependencies();
        if (s3.dependencyService() != address(s2_1)) return "TestService3 should have s2_1 as dependency after upgrade";

        return "success";
    }

}
