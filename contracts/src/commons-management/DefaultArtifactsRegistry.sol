pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";

import "commons-management/Management.sol";
import "commons-management/ArtifactsRegistry.sol";

/**
 * @title DefaultArtifactRegistry
 * @dev Default implementation of the ArtifactRegistry interface
 */
contract DefaultArtifactsRegistry is ArtifactsRegistry {

    mapping (string => Management.Artifact) artifacts;
    string[] artifactIds;

    /**
     * @dev Registers an artifact with the provided information.
     * REVERTS if:
     * - the artifact ID or location are empty
     * - the artifact ID and version are already registered with a different address location
     * @param _artifactId the ID of the artifact
     * @param _location the address of the smart contract artifact
     * @param _version the semantic version of the artifact
     * @param _activeVersion whether this version of the artifact should be tracked as the active version
     */
    function registerArtifact(string _artifactId, address _location, uint8[3] _version, bool _activeVersion) external {
        ErrorsLib.revertIf(bytes(_artifactId).length == 0 || _location == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultArtifactsRegistry.registerArtifact", "_artifactId and _location must not be empty");
        address current = artifacts[_artifactId].locations[keccak256(abi.encodePacked(_version))];
        ErrorsLib.revertIf(current != address(0) && current != _location, 
            ErrorsLib.OVERWRITE_NOT_ALLOWED(), "DefaultArtifactsRegistry.registerArtifact", "An artifact with the same ID, but a different address is already registered");
        if (!artifacts[_artifactId].exists) {
            artifactIds.push(_artifactId);
            artifacts[_artifactId].exists = true;
        }
        if (current == address(0)) {
            artifacts[_artifactId].locations[keccak256(abi.encodePacked(_version))] = _location;
            artifacts[_artifactId].versions[_location] = _version;
            if (_activeVersion) {
                artifacts[_artifactId].activeVersion = _location;
            }
        }
    }

    /**
     * @dev Sets the specified artifact and version to be tracked as the active version.
     * REVERTS if:
     * - the specified artifact ID and version don't exist in this ArtificactsRegistry
     * @param _artifactId the ID of the artifact
     * @param _version the semantic version of the artifact
     */
    function setActiveVersion(string _artifactId, uint8[3] _version) external {
        address current = artifacts[_artifactId].locations[keccak256(abi.encodePacked(_version))];
        ErrorsLib.revertIf(current == address(0),
            ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultArtifactsRegistry.setActiveVersion", "The specified ID and version is not registered");
    }

    /**
     * @dev Returns the number of artifacts registered in this ArtifactsRegistry irrespective of how many version of an artifact exist.
     * @return the number of unique artifact IDs
     */
    function getNumberOfArtifacts() external view returns (uint) {
        return artifactIds.length;
    }

    /**
     * @dev See ArtifactsFinder.getArtifact(string)
     */
    function getArtifact(string _artifactId) external view returns (address location, uint8[3] version) {
        location = artifacts[_artifactId].activeVersion;
        version = artifacts[_artifactId].versions[location];
    }

    /**
     * @dev See ArtifactsFinder.getArtifactByVersion(string,uint8[3])
     */
    function getArtifactByVersion(string _artifactId, uint8[3] _version) external view returns (address location) {
        location = artifacts[_artifactId].locations[keccak256(abi.encodePacked(_version))];
    }
}