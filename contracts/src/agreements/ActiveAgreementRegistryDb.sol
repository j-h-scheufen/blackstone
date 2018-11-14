pragma solidity ^0.4.25;

import "commons-base/SystemOwned.sol";
import "commons-base/BaseErrors.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";
import "commons-utils/ArrayUtilsAPI.sol";

import "agreements/Agreements.sol";

contract ActiveAgreementRegistryDb is SystemOwned {

  using MappingsLib for Mappings.AddressStringMap;
  using ArrayUtilsAPI for address[];

  Mappings.AddressStringMap activeAgreements;
  Agreements.AgreementCollectionMap collections;
  
  // Tracks the formation and execution workflows per agreement
  mapping(address => address[2]) agreementProcesses;
  

  constructor() public {
    systemOwner = msg.sender;
  }

  function agreementIsRegistered(address _activeAgreement) external view returns (bool) {
    return activeAgreements.exists(_activeAgreement);
  }

  function registerActiveAgreement(address _activeAgreement, string _name) external pre_onlyBySystemOwner returns (uint error) {
    error = activeAgreements.insert(_activeAgreement, _name);
  }

  function getAgreementFormationProcess(address _activeAgreement) external view returns (address) {
    return agreementProcesses[_activeAgreement][0];
  }

  function getAgreementExecutionProcess(address _activeAgreement) external view returns (address) {
    return agreementProcesses[_activeAgreement][1];
  }

  function setAgreementFormationProcess(address _activeAgreement, address _processInstance) external pre_onlyBySystemOwner {
    agreementProcesses[_activeAgreement][0] = _processInstance;
  }

  function setAgreementExecutionProcess(address _activeAgreement, address _processInstance) external pre_onlyBySystemOwner {
    agreementProcesses[_activeAgreement][1] = _processInstance;
  }

  function getNumberOfActiveAgreements() external view returns (uint size) {
    return activeAgreements.keys.length;
  }

  function getActiveAgreementAtIndex(uint _index) external view returns (address activeAgreement) {
    uint error;
    (error, activeAgreement) = activeAgreements.keyAtIndex(_index);
  }

  function getActiveAgreementName(address _activeAgreement) external view returns (string name) {
    return activeAgreements.get(_activeAgreement);
  }

  function createCollection(bytes32 _id, string _name, address _author, uint8 _collectionType, bytes32 _packageId) external pre_onlyBySystemOwner returns (uint) {
    if (collections.rows[_id].exists) return BaseErrors.RESOURCE_ALREADY_EXISTS();
    collections.rows[_id].keyIdx = collections.keys.push(_id);
    collections.rows[_id].value.id = _id;
    collections.rows[_id].value.name = _name;
    collections.rows[_id].value.author = _author;
    collections.rows[_id].value.collectionType = _collectionType;
    collections.rows[_id].value.packageId = _packageId;
    collections.rows[_id].exists = true;
    return BaseErrors.NO_ERROR();
  }

  function addAgreementToCollection(bytes32 _id, address _agreement) external pre_onlyBySystemOwner returns (uint) {
    if (!collections.rows[_id].exists) return BaseErrors.RESOURCE_NOT_FOUND();
    if (!collections.rows[_id].value.agreements.contains(_agreement))
      collections.rows[_id].value.agreements.push(_agreement);
    return BaseErrors.NO_ERROR();
  }

  function collectionExists(bytes32 _id) external view returns (bool) {
    return collections.rows[_id].exists;
  }

  function getNumberOfCollections() external view returns (uint) {
    return collections.keys.length;
  }

  function getCollectionAtIndex(uint _index) external view returns (bytes32) {
    return collections.keys[_index];
  }

  function getCollectionData(bytes32 _id) external view returns (string name, address author, uint8 collectionType, bytes32 packageId) {
    name = collections.rows[_id].value.name;
    author = collections.rows[_id].value.author;
    collectionType = collections.rows[_id].value.collectionType;
    packageId = collections.rows[_id].value.packageId;
  }

  function getNumberOfAgreementsInCollection(bytes32 _id) external view returns (uint) {
    return collections.rows[_id].value.agreements.length;
  }

  function getAgreementAtIndexInCollection(bytes32 _id, uint _index) external view returns (address) {
    return collections.rows[_id].value.agreements[_index];
  }

}