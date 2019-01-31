pragma solidity ^0.4.25;

import "commons-base/SystemOwned.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";

/**
 * @title EcosystemRegistryDb
 * @dev Stores and manages Ecosystem references.
 */
contract EcosystemRegistryDb is SystemOwned {
  
  using MappingsLib for Mappings.StringAddressMap;

  Mappings.StringAddressMap ecosystems;

  /**
   * @dev Creates a new EcosystemRegistryDb and registers the msg.sender as the systemOwner.
   */
  constructor() public {
    systemOwner = msg.sender;
  }

  function addEcosystem(string _name, address _address)
    external
    pre_onlyBySystemOwner
  {
    ecosystems.insertOrUpdate(_name, _address);
  }

  function removeEcosystem(string _name)
    external
    pre_onlyBySystemOwner
  {
    ecosystems.remove(_name);
  }

  function ecosystemExists(string _name)
    external view
    returns (bool)
  {
    return ecosystems.exists(_name);
  }

  function getNumberOfEcosystems()
    external view
    returns (uint)
  {
    return ecosystems.keys.length;
  }

  function getEcosystemKeyAtIndex(uint _index)
    external view
    returns (string key)
  {
    ( ,key) = ecosystems.keyAtIndex(_index);
  }

  function getEcosystemDetails(string _name)
    external view
    returns (address ecosystemAddress)
  {
    ecosystemAddress = ecosystems.rows[_name].value;
  }

}