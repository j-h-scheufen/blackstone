pragma solidity ^0.4.25;

import "commons-base/BaseErrors.sol";
import "commons-base/SystemOwned.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";
import "commons-utils/ArrayUtilsAPI.sol";

import "agreements/Agreements.sol";

contract ArchetypeRegistryDb is SystemOwned {

  using MappingsLib for Mappings.AddressStringMap;
  using ArrayUtilsAPI for address[];

  Mappings.AddressStringMap archetypes;
  Agreements.ArchetypePackageMap packages;

  constructor() public {
    systemOwner = msg.sender;
  }

  function addArchetype(address _archetype, string _name) external pre_onlyBySystemOwner returns (uint error) {
    error = archetypes.insert(_archetype, _name);
  }

  function archetypeExists(address _archetype) external view returns (bool) {
    return archetypes.exists(_archetype);
  }

  function getNumberOfArchetypes() external view returns (uint) {
    return archetypes.keys.length;
  }
  
  function getArchetypeAtIndex(uint _index) external view returns (uint error, address archetype) {
    (error, archetype) = archetypes.keyAtIndex(_index);
  }

  function getArchetypeName(address _archetype) external view returns (string name) {
    return archetypes.get(_archetype);
  }

  function createPackage(bytes32 _id, string _name, string _description, address _author, bool _isPrivate, bool _active) external pre_onlyBySystemOwner returns (uint) {
    if (packages.rows[_id].exists) return BaseErrors.RESOURCE_ALREADY_EXISTS();
    packages.rows[_id].keyIdx = packages.keys.push(_id);
    packages.rows[_id].value.id = _id;
    packages.rows[_id].value.name = _name;
    packages.rows[_id].value.description = _description;
    packages.rows[_id].value.author = _author;
    packages.rows[_id].value.isPrivate = _isPrivate;
    packages.rows[_id].value.active = _active;
    packages.rows[_id].exists = true;
    return BaseErrors.NO_ERROR();
  }

  function addArchetypeToPackage(bytes32 _id, address _archetype) external pre_onlyBySystemOwner returns (uint) {
    if (!packages.rows[_id].exists) return BaseErrors.RESOURCE_NOT_FOUND();
    if (!packages.rows[_id].value.archetypes.contains(_archetype)) 
      packages.rows[_id].value.archetypes.push(_archetype);
    return BaseErrors.NO_ERROR();
  }

  function packageExists(bytes32 _id) external view returns (bool) {
    return packages.rows[_id].exists;
  }

  function getNumberOfPackages() external view returns (uint) {
    return packages.keys.length;
  }

  function getPackageAtIndex(uint _index) external view returns (bytes32) {
    return packages.keys[_index];
  }

  function getPackageData(bytes32 _id) external view returns (string name, string description, address author, bool isPrivate, bool active) {
    name = packages.rows[_id].value.name;
    description = packages.rows[_id].value.description;
    author = packages.rows[_id].value.author;
    isPrivate = packages.rows[_id].value.isPrivate;
    active = packages.rows[_id].value.active;
  }

  function activatePackage(bytes32 _id) external {
    packages.rows[_id].value.active = true;
  }

  function deactivatePackage(bytes32 _id) external {
    packages.rows[_id].value.active = false;
  }

  function getNumberOfArchetypesInPackage(bytes32 _packageId) external view returns (uint) {
    return packages.rows[_packageId].value.archetypes.length;
  }

  function getArchetypeAtIndexInPackage(bytes32 _packageId, uint _index) external view returns (address) {
    return packages.rows[_packageId].value.archetypes[_index];
  }

}