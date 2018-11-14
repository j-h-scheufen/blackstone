pragma solidity ^0.4.25;

import "commons-base/BaseErrors.sol";

/**
 * @title HierarchyEnabled
 * @dev This contract defines the relationship between parent and children in a component hierarchy
 */
contract HierarchyEnabled {

    struct HierarchyStruct {
        address root;
        address parent;
        address[] children;
    }

    HierarchyStruct hierarchy;

	/**
	 * @dev Sets the hierarchy root to the given address, if it had not been set before and is not empty (0x0)
	 * If the root had already been set, only the root as msg.sender can change it to a new value.
	 * @param _address the hierarchy root
	 * @return BaseErrors.NO_ERROR() when successful, BaseErrors.INVALID_PARAM_VALUE() if address is empty, BaseErrors.OVERWRITE_NOT_ALLOWED() if already set and caller is not the current root
	 */
    function setRoot(address _address) public returns (uint) {
    	if (0x0 == _address) return BaseErrors.INVALID_PARAM_VALUE();
		// return early if someone is trying to set it to the same value
    	if (hierarchy.root == _address) return BaseErrors.NO_ERROR();
    	if (0x0 != hierarchy.root && msg.sender != hierarchy.root) return BaseErrors.OVERWRITE_NOT_ALLOWED();

        hierarchy.root = _address;
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Sets the parent of this component
     * @param _parent the parent
     * @return NO_ERROR if successful or OVERWRITE_NOT_ALLOWED if this module's parent had already been set.
     */
    function setParent(address _parent) public returns (uint) {
        if(hierarchy.parent != 0x0) { return BaseErrors.OVERWRITE_NOT_ALLOWED(); }
        hierarchy.parent = _parent;
        return BaseErrors.NO_ERROR();
    }

    /**
     * @dev Returns the parent address
     * @return the parent or 0x0, if this is the root of the hierarchy
     */
    function getParent() external view returns (address) {
        return hierarchy.parent;
    }

    /**
     * @dev Adds the given address as a child of this component
     * @param _child the child to add
     * @return NO_ERROR if successful or INVALID_PARAM_VALUE if the parent-child relationship cannot be established.
     */
    function addChild(address _child) public returns (uint) {
        HierarchyEnabled child = HierarchyEnabled(_child);
        uint error = child.setRoot(hierarchy.root);
        if ( error != BaseErrors.NO_ERROR()) {
        	return error;
        }
        if (child.setParent(this) != BaseErrors.NO_ERROR()) { throw; } // no other chance than to throw here to revert TX since root had already been changed on the child
        
        hierarchy.children.push(_child);
        return BaseErrors.NO_ERROR();
    }

	/**
	 * @dev returns the number of child sub-modules
	 * @return the number of children
	 */
    function getNumberOfChildren() external view returns (uint) {
        return hierarchy.children.length;
    }

}