pragma solidity ^0.4.25;

import "commons-base/BaseErrors.sol";

import "commons-management/DOUG.sol";
import "commons-management/DefaultDoug.sol";
import "commons-management/DougProxy.sol";
import "commons-management/ContractManagerDb.sol";
import "commons-management/DefaultContractManager.sol";

import "commons-management/test/TestService.sol";

contract DougProxyTest {

    string constant SUCCESS = "success";

    function testProxyDelegation() external returns (string) {

        ContractManagerDb contractsDb = new ContractManagerDb();
        DefaultContractManager contractMgr = new DefaultContractManager();
        contractsDb.transferSystemOwnership(contractMgr);
        contractMgr.acceptDatabase(contractsDb);

        DefaultDoug doug = new DefaultDoug();
        DougProxy proxy = new DougProxy(doug);
        if (proxy.getDelegate() != address(doug)) return "Doug should be set in the proxy";
        if (DefaultDoug(proxy).getOwner() != doug.getOwner()) return "DougProxy and Doug should point to the same owner";
        if (DefaultDoug(proxy).getOwner() != address(this)) return "The proxy owner should be set to this contract";

        contractMgr.transferSystemOwnership(proxy);
        contractMgr.transferUpgradeOwnership(proxy);
        DefaultDoug(proxy).setContractManager(contractMgr);
        if (doug.getContractManager() != 0x0) return "DOUG's manager should be empty";
        if (DefaultDoug(proxy).getContractManager() != address(contractMgr)) return "The proxy's manager should be set to the ContractManager";

        uint currentSize = contractsDb.getNumberOfContracts();
        DOUG(proxy).deployContract("io.monax/agreements-network/libraries/BaseErrors", this);
        if (contractsDb.getNumberOfContracts() != currentSize+1) return "ContractsDb size should be +1 after adding library via proxy";
        
        TestService s1 = new TestService([1,0,0], "");
        s1.transferUpgradeOwnership(proxy);
        DOUG(proxy).deployContract("io.monax/agreements-network/services/ProxyDelegateTest1", s1);
        if (contractsDb.getNumberOfContracts() != currentSize+2) return "ContractsDb size should be +2 after adding service via proxy";
        if (DOUG(proxy).lookupContract("io.monax/agreements-network/services/ProxyDelegateTest1") != address(s1)) return "service should be retrievable via the proxy";

        return SUCCESS;
    }

}

