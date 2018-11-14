pragma solidity ^0.4.25;

/**
 * @title ArrayUtils Library Implementation
 * @dev Library containing utility functions for arrays of primitive Solidity data types.
 */
library ArrayUtilsImpl {

	/**
	 * @dev Returns whether the specified value is present in the given array
	 * @param _list the array
	 * @param _value the value
	 * @return true if the value is found in the array, false otherwise
	 */
    function contains(bytes32[] _list, bytes32 _value) public pure returns (bool) {
	    for (uint i=0; i<_list.length; i++) {
	        if (_list[i] == _value) return true;
	    }
	    return false;
    }

	/**
	 * @dev Returns whether the specified value is present in the given array
	 * @param _list the array
	 * @param _value the value
	 * @return true if the value is found in the array, false otherwise
	 */
    function contains(address[] _list, address _value) public pure returns (bool) {
	    for (uint i=0; i<_list.length; i++) {
	        if (_list[i] == _value) return true;
	    }
	    return false;
    }

	/**
	 * @dev Returns whether the specified value is present in the given array
	 * @param _list the array
	 * @param _value the value
	 * @return true if the value is found in the array, false otherwise
	 */
    function contains(uint[] _list, uint _value) public pure returns (bool) {
	    for (uint i=0; i<_list.length; i++) {
	        if (_list[i] == _value) return true;
	    }
	    return false;
    }

	/**
	 * @dev Returns whether the specified value is present in the given array
	 * @param _list the array
	 * @param _value the value
	 * @return true if the value is found in the array, false otherwise
	 */
    function contains(int[] _list, int _value) public pure returns (bool) {
	    for (uint i=0; i<_list.length; i++) {
	        if (_list[i] == _value) return true;
	    }
	    return false;
    }

}