pragma solidity ^0.4.25;

import "../contracts/LifecycleModule.sol";
import "../contracts/DefaultLifecycleModule.sol";
import "../contracts/LifecycleHub.sol";
import "../contracts/DefaultLifecycleHub.sol";
import "./LocatorEnabledDummy.sol";

contract LifecycleHubTest {

    function testModuleRegistration() external returns (string) {

        LifecycleHub hub = new DefaultLifecycleHub([1,0,0]);
        MyCustom c1 = new MyCustom();
        MyCustom c2 = new MyCustom();
        LifecycleModule myModule = new MyModule([1,0,0], c1, c2);

        bytes32 cName;
        address cAddress;

        hub.setRoot(hub); // the hierarchy always needs a root! Setting the hub to be the root for testing.

        if (hub.addChild(myModule) != BaseErrors.NO_ERROR()) { return "Error adding custom module as child to hub."; }
        if (myModule.getNumberOfRegistrationContracts() != 2) { return "Number of registered contracts should be 2."; }
        (cName, cAddress) = myModule.getRegistrationContract(0);
        if ( cName != "C1") { return "Registered contract at index 0 does not match C1 name."; }
        if ( cAddress != address(c1)) { return "Registered contract at index 0 does not match C1 address."; }
        (cName, cAddress) = myModule.getRegistrationContract(1);
        if ( cName != "C2") { return "Registered contract at index 0 does not match C2 name."; }
        if ( cAddress != address(c2)) { return "Registered contract at index 0 does not match C2 address."; }

        return "success";
    }
}


contract MyCustom is LocatorEnabledDummy {

}

contract MyModule is DefaultLifecycleModule {

    MyCustom c1;
    MyCustom c2;

    constructor(uint8[3] _version, address _c1, address _c2) DefaultLifecycleModule(_version) public {
        c1 = MyCustom(_c1);
        c2 = MyCustom(_c2);
    }
    
    function getNumberOfRegistrationContracts() external view returns (uint) {
        return 2;
    }
    
    function getRegistrationContract(uint _index) external view returns (bytes32, address) { 
        if (_index == 0)
            return ("C1", c1);
        else if (_index == 1)
            return ("C2", c2);
        else
            return ("", 0x0);
    }
}

