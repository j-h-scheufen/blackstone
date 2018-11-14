pragma solidity ^0.4.25;

import "commons-utils/ArrayUtilsAPI.sol";

contract ArrayUtilsTest {

	using ArrayUtilsAPI for bytes32[];

	bytes32[] values;

	function testContainsBytes32() external returns (string) {

		delete values;
		values.push("1");
		values.push("2");
		values.push("3");

		if (!values.contains("2")) { return "Contains failed for value 2"; }
		if (values.contains("987sdf")) { return "Contains wrongly detected non-existing value"; }
		return "success";
	}

	// function testAddBytes32() external returns (string) {

	// 	bool updated;

	// 	delete values;
	// 	values.push("a");
	// 	values.push("b");

	// 	uint lenBefore = values.length;
	// 	(updated, values) = values.add("def", false);

	// 	if (!updated) { return "Bool updated should be true"; }
	// 	if (lenBefore+1 != values.length) { return "Length of updated array should have increased"; }
	// 	if (values[values.length-1] != "def") { return "Added value not found in last index position of the updated array"; }

	// 	return "success";
	// }
}