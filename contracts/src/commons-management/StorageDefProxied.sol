pragma solidity ^0.4.25;

/**
 * @dev Provides the storage layout for both proxied and proxy contracts.
 */
contract StorageDefProxied {

    address internal proxied;

    /**
     * @dev Internal constructor to enforce abstract contract.
     */
    constructor() internal {}
}