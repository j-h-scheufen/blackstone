pragma solidity ^0.4.25;

import "commons-base/BaseErrors.sol";

import "commons-management/DOUG.sol";
import "commons-management/DefaultDoug.sol";
import "commons-management/DougProxy.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";

import "commons-management/test/TestService.sol";

contract DougProxyTest {

    string constant SUCCESS = "success";

    function testProxyDelegation() external returns (string) {

        ArtifactsRegistry artifactsRegistry = new DefaultArtifactsRegistry();
        DefaultArtifactsRegistry(address(artifactsRegistry)).initialize();

        DefaultDoug doug = new DefaultDoug();
        DougProxy proxy = new DougProxy(doug);
        if (proxy.getDelegate() != address(doug)) return "Doug should be set in the proxy";
        if (DefaultDoug(proxy).getOwner() != doug.getOwner()) return "DougProxy and Doug should point to the same owner";
        if (DefaultDoug(proxy).getOwner() != address(this)) return "The proxy owner should be set to this contract";

        artifactsRegistry.transferSystemOwnership(proxy);
        DefaultDoug(proxy).setArtifactsRegistry(address(artifactsRegistry));
        if (doug.getArtifactsRegistry() != 0x0) return "DOUG's ArtifactsRegistry should be empty since it's the delegate target";
        if (DefaultDoug(proxy).getArtifactsRegistry() != address(artifactsRegistry)) return "The proxy's ArtifactsRegistry should be set";

        uint currentSize = artifactsRegistry.getNumberOfArtifacts();
        DOUG(proxy).deploy("agreements-network/libraries/BaseErrors", this);
        if (artifactsRegistry.getNumberOfArtifacts() != currentSize+1) return "ArtifactsRegistry size should be +1 after adding library via DOUG proxy";
        
        TestService s1 = new TestService([1,0,0], "");
        s1.transferUpgradeOwnership(proxy);
        DOUG(proxy).deploy("agreements-network/services/ProxyDelegateTest1", s1);
        if (artifactsRegistry.getNumberOfArtifacts() != currentSize+2) return "ArtifactsRegistry size should be +2 after adding service via DOUG proxy";
        if (DOUG(proxy).lookup("agreements-network/services/ProxyDelegateTest1") != address(s1)) return "service should be retrievable via the DOUG proxy";

        return SUCCESS;
    }

}

