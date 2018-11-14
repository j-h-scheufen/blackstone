pragma solidity ^0.4.25;

import "commons-base/BaseErrors.sol";

import "commons-utils/TypeUtilsAPI.sol";

import "commons-management/DOUG.sol";
import "commons-management/DefaultDoug.sol";
import "commons-management/DougProxy.sol";
import "commons-management/ContractManagerDb.sol";
import "commons-management/DefaultContractManager.sol";
import "commons-management/ObjectProxy.sol";

contract ObjectProxyTest {

    string constant SUCCESS = "success";
    string objectClass = "AN://test-object";

    function testProxyHandling() external returns (string) {

        ContractManagerDb contractsDb = new ContractManagerDb();
        DefaultContractManager contractMgr = new DefaultContractManager();
        contractsDb.transferSystemOwnership(contractMgr);
        contractMgr.acceptDatabase(contractsDb);

        DefaultDoug doug = new DefaultDoug();
        DougProxy dougProxy = new DougProxy(doug);
        contractMgr.transferSystemOwnership(dougProxy);
        contractMgr.transferUpgradeOwnership(dougProxy);
        DefaultDoug(dougProxy).setContractManager(contractMgr);

        ObjectInterface impl1 = new ObjectImplV1();
        ObjectInterface impl2 = new ObjectImplV2();
        DOUG(dougProxy).deployContract(objectClass, address(impl1)); // Set first version of impl

        ObjectProxy object = new ObjectProxy(dougProxy, objectClass);
        if (object.getDoug() != address(dougProxy)) return "The DOUG proxy address should be retrievable in the ObjectProxy";
        if (keccak256(abi.encodePacked(object.getObjectClass())) != keccak256(abi.encodePacked((objectClass)))) return "The object class string should be retrievable in the ObjectProxy";
        if (object.getDelegate() != address(impl1)) return "The ObjectProxy delegate should point to impl1";
        ObjectInterface(address(object)).setNumber(2);
        if (ObjectInterface(address(object)).getNumber() != 2) return "The ObjectProxy should return v1 number initially";

        // change the implementation version in DOUG
        DOUG(dougProxy).deployContract(objectClass, address(impl2));
        if (object.getDelegate() != address(impl2)) return "The ObjectProxy delegate should point to impl2";
        if (ObjectInterface(address(object)).getNumber() != 4) return "The ObjectProxy should return v2 double number after impl upgrade in DOUG";

        return SUCCESS;
    }
}

// object interface
contract ObjectInterface {
    function setNumber(uint _v) external;
    function getNumber() external view returns (uint);
}

// object implementation v1
contract ObjectImplV1 is ObjectInterface {

    uint number;

    function setNumber(uint _v) external {
        number = _v;
    }

    function getNumber() external view returns (uint) {
        return number;
    }
}

// overwrites V1 to return double the number
contract ObjectImplV2 is ObjectImplV1 {

    function getNumber() external view returns (uint) {
        return number*2;
    }
}
