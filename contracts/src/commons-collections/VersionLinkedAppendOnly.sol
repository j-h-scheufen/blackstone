pragma solidity ^0.4.25;

import "commons-base/BaseErrors.sol";
import "commons-base/Owned.sol";

import "commons-base/Versioned.sol";

contract VersionLinkedAppendOnly is Owned, Versioned {

  VersionLinkedAppendOnly latest;
  VersionLinkedAppendOnly successor;
  VersionLinkedAppendOnly predecessor;

  modifier pre_successorOnly() {
    if (msg.sender != address(successor)) {
      return;
    }
    _;
  }

  constructor(uint8[3] _version) Versioned(_version[0], _version[1], _version[2]) public {
    owner = msg.sender;
    latest = this;
  }

  /**
    * @dev Appends the given version as the latest in version linked list
    *
    * @return error - failure to append due to various reasons
    */
  function appendNewVersion(VersionLinkedAppendOnly _link) external returns (uint error) {
    error = BaseErrors.NO_ERROR();
    if (address(_link) == 0x0) { return BaseErrors.NULL_PARAM_NOT_ALLOWED(); }
    if (_link.getOwner() != owner) { return BaseErrors.INVALID_PARAM_STATE(); }

    int comp = _link.compareVersion(this); // -1 if _link > this
    
    if (comp == 0 || address(_link) == address(this)) { // same version or same contract address
      return BaseErrors.INVALID_PARAM_STATE();
    }

    if (comp < 0) { // _link > this, accept _link
      
      if (address(successor) != 0x0 && _link.compareVersion(successor) <= 0) {
        // there is a successor, and it's lower than or equal to _link, pass the request on
        return successor.appendNewVersion(_link);
      } else if (address(successor) != 0x0 && _link.compareVersion(successor) > 0) {
        // there is a successor, and it's higher than _link, reject _link
        return BaseErrors.INVALID_PARAM_STATE(); 
      }

      if (predecessor == address(0) || 
         (predecessor != address(0) && predecessor.setLatest(_link))) {
        _link.setPredecessor();
        if (_link.getPredecessor() == address(this) && 
            _link.getLatest() == address(_link)) {
          successor = _link;
          latest = _link;
        } else {
          return BaseErrors.INVALID_STATE();
        }
      } else {
        predecessor.setLatest(this);
      }
    } else { // _link < this, reject _link
      return BaseErrors.INVALID_PARAM_STATE();
    }
  }

  /**
    * @dev Sets the predecessor to msg.sender who should also have the same owner
    *
    * @return error - if a predecessor is already set (i.e. no overwriting allowed), or if there is a owner mismatch
    */
  function setPredecessor() external returns (uint error) {
    // msg.sender is the current tail
    if (VersionLinkedAppendOnly(msg.sender).getOwner() != owner) {
      return BaseErrors.INVALID_PARAM_STATE();
    }
    if (predecessor != address(0)) {
      return BaseErrors.OVERWRITE_NOT_ALLOWED();
    }
    predecessor = VersionLinkedAppendOnly(msg.sender);
    return BaseErrors.NO_ERROR();
  }

  /**
    * @dev Sets the latest version, and recursively sets latest for preceeding links
    *
    * @param _latest - the latest version
    * @return success - representing whether latest was successfully set for all links
    */
  function setLatest(VersionLinkedAppendOnly _latest) pre_successorOnly external returns (bool success) {
    if (predecessor != address(0)) {
      if (!predecessor.setLatest(_latest)) {
        success = false;
      } else {
        latest = _latest;
        success = true;
      }
      return;
    } else {
      latest = _latest;
      return true;
    }
  }

  /**
    * @dev Retrieves the specified version
    *
    * @param _targetVer - the version to retrieve
    * @return targetAddr - address of the version to retrieve, 0x0 if not found
    */
  function getTargetVersion(uint8[3] _targetVer) external view returns (address targetAddr) {
    int comp = this.compareVersion(_targetVer); // -1 if _targetVer < this
    
    if (comp == 0) { return this; }
    
    // target version is lower than this version and higher than predecessor version
    // OR
    // target version is higher than this version and lower than successor version 
    bool notFound = 
      (comp < 0 && predecessor != address(0) && Versioned(predecessor).compareVersion(_targetVer) > 0) ||
      (comp > 0 && successor != address(0) && Versioned(successor).compareVersion(_targetVer) < 0);
    
    if (notFound) { 
      return address(0);
    }

    if (comp < 0) { // _targetVer < this
      if (predecessor != address(0)) {
        return VersionLinkedAppendOnly(predecessor).getTargetVersion(_targetVer);
      }
    } else { // _targetVer > this
      if (successor != address(0)) {
        return VersionLinkedAppendOnly(successor).getTargetVersion(_targetVer);
      }
    }
    return address(0);
  }

  function getLatest() external view returns (address) {
    return latest;
  }

  function getSuccessor() external view returns (address) {
    return successor;
  }

  function getPredecessor() external view returns (address) {
    return predecessor;
  }

}