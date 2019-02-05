pragma solidity ^0.4.25;

import "commons-base/SystemOwned.sol";
import "commons-base/Versioned.sol";
import "commons-standards/ERC165Utils.sol";

import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/ArtifactsFinderEnabled.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";

contract ArtifactsRegistryTest {

    string keyService1 = "agreements-network/services/Service1";
    string keyService2 = "agreements-network/services/Service2";

    string constant EMPTY_STRING = "";

    // the ERC165 ID of ArtifactsFinderEnabled
    bytes4 constant ERC165_ID_ArtifactsFinderEnabled = bytes4(keccak256(abi.encodePacked("setArtifactsFinder(address)")));

    function testArtifactsRegistry() external returns (string) {

        address location;
        uint8[3] memory version;

        ArtifactsRegistry registry = new DefaultArtifactsRegistry();

        TestServiceWithDependency s1 = new TestServiceWithDependency([1,0,0]);
        s1.setArtifactsFinder(registry);
        DefaultTestService s2 = new DefaultTestService([1,2,0]);
        ServiceDb service1Db = new ServiceDb(s1);
        ServiceDb service2Db = new ServiceDb(s2);
        s1.acceptDatabase(service1Db);
        s2.acceptDatabase(service2Db);

        if (registry.getNumberOfArtifacts() > 0) return "There should be no artifacts";

        // test failure scenarios
        version = [1,0,0];
        if (address(registry).call(abi.encodeWithSignature("registerArtifact(string,address,uint8[3],bool)", EMPTY_STRING, address(s1), version, false)))
            return "Registering an artifact with an empty ID should fail";
        if (address(registry).call(abi.encodeWithSignature("registerArtifact(string,address,uint8[3],bool)", keyService1, address(0), version, false)))
            return "Registering an artifact with an empty address should fail";

        if (!address(registry).call(abi.encodeWithSignature("registerArtifact(string,address,uint8[3],bool)", keyService1, address(s1), version, true)))
            return "Registering an artifact service1 correctly should succeed.";
        if (registry.getNumberOfArtifacts() != 1) return "There should be 1 artifact after service1 registration";

        if (address(registry).call(abi.encodeWithSignature("registerArtifact(string,address,uint8[3],bool)", keyService1, address(this), version, true)))
            return "Registering an service1 with same ID and version, but different address should fail";

        // performing without the dependency should fail
        if (address(s1).call(abi.encodeWithSignature("performWithDependency()"))) return "Calling service1 without the dependency registered should fail";
        if (s1.getDependency1() != address(0)) return "The dependency1 address on service1 should not be filled after the revert";

        registry.registerArtifact(keyService2, s2, [1,2,0], true);
        if (registry.getNumberOfArtifacts() != 2) return "There should be 2 artifacts after service2 registration";

        // now re-attempt to perform service1
        if (!address(s1).call(abi.encodeWithSignature("performWithDependency()"))) return "Calling service1 with the dependency registered should succeed";
        if (s1.getDependency1() != address(s2)) return "The dependency1 address on service1 should now point to service2";

        // perform an update to service 2 and check if dependencies were updated
        DefaultTestService s2_1 = new DefaultTestService([2,4,0]);
        registry.registerArtifact(keyService2, s2_1, [2,4,0], true);
        if (registry.getNumberOfArtifacts() != 2) return "There should still be 2 artifacts after service2 upgrade with new version";
        (location, version) = registry.getArtifact(keyService2);
        if (location != address(s2_1)) return "The active location for service2 should have been changed after the upgrade.";

        if (!address(s1).call(abi.encodeWithSignature("performWithDependency()"))) return "Calling service1 with an updated dependency registered should succeed";
        if (s1.getDependency1() != address(s2_1)) return "The dependency1 address on service1 should now point to service2_1";

        return "success";
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
 * @dev Extends the DefaultTestService with capabilities for dependency injection via a ArtifactsFinder
 */
contract TestServiceWithDependency is DefaultTestService, ArtifactsFinderEnabled {

    address dependency1;
    string dep1Name = "agreements-network/services/Service2";

    constructor(uint8[3] _version) DefaultTestService(_version) public {

    }

    function performWithDependency() external {
		(dependency1, ) = artifactsFinder.getArtifact(dep1Name);
		ErrorsLib.revertIf(address(dependency1) == address(0),
			ErrorsLib.DEPENDENCY_NOT_FOUND(), "TestServiceWithDependency.performWithDependency", "Dependency1 not found in ArtifactsFinder");
    }

    function getDependency1() public view returns (address) {
        return dependency1;
    }

}

contract ServiceDb is SystemOwned {

    constructor(address _systemOwner) public {
        systemOwner = _systemOwner;
    }

}
