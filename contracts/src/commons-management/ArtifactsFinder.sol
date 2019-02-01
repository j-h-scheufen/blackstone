pragma solidity ^0.4.25;

/**
 *
 */
interface ArtifactsFinder {

    function getArtifact(string _artifactId) external view returns (address location, uint8[3] version);

    function getArtifactByVersion(string _artifactId, uint8[3] _version) external view returns (address location);

}