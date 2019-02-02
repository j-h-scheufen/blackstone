pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";

import "commons-management/Management.sol";
import "commons-management/ArtifactsRegistry.sol";

/**
 * @title DefaultArtifactRegistry
 * @dev Default implementation of the ArtifactRegistry interface
 */
contract DefaultArtifactsRegistry is ArtifactsRegistry {

    // TODO How do we best upgrade this thing? ContractManager got pretty complex with the entire DbUpgradeable thing. Can this be avoided via proxy? Similar to DougProxy
    // Question is if structured data proxy like DougProxy or unstructured?

    mapping (string => Management.Artifact) artifacts;
    string[] artifactKeys;

    function registerArtifact(string _artifactId, address _location, uint8[3] _version, bool _activeVersion) external {
        ErrorsLib.revertIf(bytes(_artifactId).length == 0 || _location == address(0),
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultArtifactsRegistry.registerArtifact", "_artifactId and _location must not be empty");
        address current = artifacts[_artifactId].locations[keccak256(abi.encodePacked(_version))];
        ErrorsLib.revertIf(current != address(0) && current != _location, 
            ErrorsLib.OVERWRITE_NOT_ALLOWED(), "DefaultArtifactsRegistry.registerArtifact", "An artifact with the same ID, but a different address is already registered");
        if (current == address(0)) {
            artifacts[_artifactId].locations[keccak256(abi.encodePacked(_version))] = _location;
            artifacts[_artifactId].versions[_location] = _version;
            if (_activeVersion) {
                artifacts[_artifactId].activeVersion = _location;
            }
        }
    }

    function getArtifact(string _artifactId) external view returns (address location, uint8[3] version) {
        location = artifacts[_artifactId].activeVersion;
        version = artifacts[_artifactId].versions[location];
    }

    function getArtifactByVersion(string _artifactId, uint8[3] _version) external view returns (address location) {
        location = artifacts[_artifactId].locations[keccak256(abi.encodePacked(_version))];
    }
}