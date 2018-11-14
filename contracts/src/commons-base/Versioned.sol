pragma solidity ^0.4.25;

/**
 * @title Versioned
 * @dev supports semantic versioning and comparison
 */
contract Versioned {

    uint8[3] semanticVersion;

	bytes4 public constant ERC165_ID_Versioned = bytes4(keccak256(abi.encodePacked("getVersion()")));

    /// @dev Constructor
    constructor(uint8 _major, uint8 _minor, uint8 _patch) public {
        semanticVersion[0] = _major;
        semanticVersion[1] = _minor;
        semanticVersion[2] = _patch;
    }

    /**
     * @dev Compares this contract's version to the version of the contract at the specified address.
     *
     * @param _other the address to which this contract is compared
     * @return 0 (equal), -1 (the other version is lower), or 1 (the other version is higher).
     */
    function compareVersion(address _other) public view returns (int result) {
        result = compare(semanticVersion, Versioned(_other).getVersion());
    }

    /**
     * @dev Compares this contract's version to the specified version.
     *
     * @param _version the version to which this contract's version is compared
     * @return 0 (equal), -1 (the other version is lower), or 1 (the other version is higher).
     */
    function compareVersion(uint8[3] _version) public view returns (int result) {
		result = compare(semanticVersion, _version);
    }

    /**
     * @dev Compares the two specified versions.
     *
     * @param _a version A
     * @param _b version B
     * @return 0 (equal), -1 (B version is lower), or 1 (B version is higher).
     * //TODO move to a math library
     */
	function compare(uint8[3] _a, uint8[3] _b) private pure returns (int result) {
        result = uint8Compare(_a[0], _b[0]);
        if (result != 0) { return result; }
        result = uint8Compare(_a[1], _b[1]);
        if (result != 0) { return result; }
        result = uint8Compare(_a[2], _b[2]);
	}
	
    /**
     * @dev returns 0 (equal), -1 (b is lower), or 1 (b is higher).
     * //TODO move to a math library
     */
    function uint8Compare(uint8 _a, uint8 _b) private pure returns (int) {
        if (_b == _a) { return 0; }
        else if (_b < _a) { return -1; }
        else { return 1; }
    }

	/**
	 * @dev returns the major version number
	 */
    function major() external view returns (uint8) { return semanticVersion[0]; }
	/**
	 * @dev returns the minor version number
	 */
    function minor() external view returns (uint8) { return semanticVersion[1]; }
	/**
	 * @dev returns the patch version number
	 */
    function patch() external view returns (uint8) { return semanticVersion[2]; }

    /**
     * @dev Returns the version as 3-digit array
     * @return the version as unit8[3]
     */
    function getVersion() external view returns (uint8[3]) {
    	return semanticVersion;
    }
}
