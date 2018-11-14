pragma solidity ^0.4.25;

import "documents-commons/Agreement.sol";

contract SignatoryProxy {

	Agreement public agreement;

	/**
	 * @dev Deploy agreement.
	 *
	 * @param _name is _name
	 */
	function createAgreementAsOwner(string _name) external returns (address) {
		agreement = new Agreement(_name);
		return agreement;
	}

	/**
	 * @dev Invokes confirmExecutionAgreement on the provided agreement using the specified version.
	 *
	 * @param _agreement the agreement
	 */
	function signAgreement(address _agreement, string version) external returns (uint) {
		return Agreement(_agreement).confirmExecutionVersion(version);
	}

    /**
     * Sets the agreement that this signatory is working with to the specified one.
     * NOTE: an existing agreement reference stored for the SignatoryProxy is replaced by this one
     */
    function setAgreement(address _address) external {
        agreement = Agreement(_address);
    }

	/**
	 * @dev Enable calling `addVersion` on `agreement`.
	 *
	 * @param _version is _version
	 */
    function addVersion(string _version) external {
    	agreement.addVersion(_version);
	}

	/**
	 * @dev Enable calling `addSignatories` on `agreement`.
	 *
	 * @param _signatory is _signatory
	 */
	function addSignatory(address _signatory) external returns (uint) {
		return agreement.addSignatory(_signatory);
	}
	
	/**
	* @dev Enable calling `confirmExecutionVersion` on `agreement`.
	*
	* @param _version is _version
	*/
	function confirmExecutionVersion(string _version) external {
		agreement.confirmExecutionVersion(_version);
	}

}
