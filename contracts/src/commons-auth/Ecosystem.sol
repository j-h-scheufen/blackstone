pragma solidity ^0.4.25;

import "commons-base/Owned.sol";

/**
 * @title Ecosystem Interface
 * @dev The interface describing interaction with an Ecosystem
 */
contract Ecosystem is Owned {

    function addExternalAddress(address _address) external;

    function removeExternalAddress(address _address) external;

    function isKnownExternalAddress(address _address) external view returns (bool);
    
    function addUserAccount(bytes32 _id, address _userAccount) external;

    function getUserAccount(bytes32 _id) external view returns (address _account);

}