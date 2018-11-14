pragma solidity ^0.4.25;

import "commons-base/Versioned.sol";

contract VersionedTest {

    /**
     * @dev Tests the compare function of the Versioned contract
     */
    function testCompare() external returns (string) {

        // Test access functions
        SubContract sub = new SubContract([2,5,17]);
        if (sub.getVersion()[0] != 2) return "getVersion()[0] expected to be 2"; 
        if (sub.getVersion()[1] != 5) return "getVersion()[0] expected to be 5"; 
        if (sub.getVersion()[2] != 17) return "getVersion()[0] expected to be 17"; 
        if (sub.major() != 2) return "major() expected to be 2";
        if (sub.minor() != 5) return "minor() expected to be 5";
        if (sub.patch() != 17) return "patch() expected to be 17";

        // Test comparison
        Versioned v731 = new Versioned(7, 3, 1);
        Versioned v731_2 = new Versioned(7, 3, 1);
        Versioned v020 = new Versioned(0, 2, 0);
        Versioned v240 = new Versioned(2, 4, 0);

        if( v731.compareVersion(v731_2) != 0 ) { return "Comparison (7.3.1 = 7.3.1) failed"; }
        if( v731.compareVersion(v240) != -1 ) { return  "Comparison (7.3.1 > 2.4.0) failed"; }
        if( v731.compareVersion(v020) != -1 ) { return  "Comparison (7.3.1 > 0.2.0) failed"; }
        if( v240.compareVersion(v020) != -1 ) { return  "Comparison (2.4.0 > 0.2.0) failed"; }
        if( v020.compareVersion(v240) != 1 ) { return  "Comparison (0.2.0 < 2.4.0) failed"; }
        if( v020.compareVersion(v731) != 1 ) { return  "Comparison (0.2.0 < 7.3.1) failed"; }
        if( v240.compareVersion(v731) != 1 ) { return  "Comparison (2.4.0 < 7.3.1) failed"; }
        
        return "success";
    }
}

contract SubContract is Versioned {

    constructor(uint8[3] _version) Versioned(_version[0], _version[1], _version[2]) public {

    }
}