pragma solidity ^0.4.25;

import "commons-base/NamedElement.sol";
import "commons-base/AbstractNamedElement.sol";

/**
 * @dev Auxiliary contract to implement AbstractNamedElement
 */
contract TestElement is AbstractNamedElement {
	
	constructor(bytes32 _id, string _name) AbstractNamedElement(_id, _name) public {}
}

contract BaseTest {

	string name = "MyName";
	
	function testNamedElement() external returns (string) {
		
		NamedElement element = new TestElement("MyId", name);
		if (element.getId() != "MyId") return "ID not set correctly.";
		if (bytes(element.getName()).length != bytes(name).length) return "Name not set correctly.";
		
		return "success";
	}
	
}