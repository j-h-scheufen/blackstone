pragma solidity ^0.4.25;

import "commons-management/ArtifactsFinder.sol";

/**
 * @title ArtifactsRegistry
 * @dev A place to store smart contract artifacts by name and version and track the active version.
 */
contract ArtifactsRegistry is ArtifactsFinder {

    function registerArtifact(string _artifactId, address _location, uint8[3] _version, bool _activeVersion) external;

}