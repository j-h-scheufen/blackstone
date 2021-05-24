import "agreements/AgreementsAPI.sol";
import "commons-base/ErrorsLib.sol";
import "commons-utils/Strings.sol";
import "commons-management/AbstractUpgradeable.sol";
import "commons-management/AbstractVersionedArtifact.sol";

// SPDX-License-Identifier: Parity-6.0.0
pragma solidity >=0.5;

contract DateRelations is AbstractVersionedArtifact(1, 0, 0), AbstractUpgradeable {
  using Strings for *;

  // This is a placeholder value for the marker field - it could be anything
  int constant DELETION = 0;

  bytes32 constant EVENT_ID_AGREEMENT_DATE_RELATION = "AN://date-relation";

  event LogInitAgreementDateRelation(
    bytes32 indexed eventURN,
    address indexed agreementAddress,
    bytes32 indexed derived,
    bytes32 base,
    string offset
  );

  event LogDeleteAgreementDateRelation(
    bytes32 indexed eventURN,
    address indexed agreementAddress,
    bytes32 indexed derived,
    int __DELETE__
  );

  struct DateRelation {
    bytes32 relationId;
    address agreementAddress;
    bytes32 derived;
    bytes32 base;
    string offset;
    bool exists;
  }

  mapping(bytes32 => DateRelation) relations;

  modifier noCircularRelations(address agreementAddress, bytes32 base, bytes32 derived) {
    if (circularRelationExists(agreementAddress, base, derived)) {
      revert("Date ".concat(base.quote(), " on agreement ", agreementAddress.quote(), "is derived from ", derived.quote()));
    }
    _;
  }

  modifier partiesOnly(address agreementAddress) {
    address actor;
    (actor,) = AgreementsAPI.authorizePartyActor(agreementAddress);
    if (actor == address(0)) {
      revert(Strings.concat("Caller is not party to agreement: ", agreementAddress.toHex()));
    }
    _;
  }

  /**
  * @notice Registers a new DateRelation. The agreement address + derived form the primary key for relations.
  * If a relation already exists for the given key, this will simply overwrite the existing base and offset for the rlation.
  * @param agreementAddress The agreement under which the base and derived dates live
  * @param base identifier for the date on which the derived date is dependent
  * @param derived identifier for the date whose value can be derived from the base date
  * @param offset the duration from the base date to the derived date
  */
  function relate(
    address agreementAddress,
    bytes32 derived,
    bytes32 base,
    string calldata offset
  )
  external
  partiesOnly(agreementAddress)
  noCircularRelations(agreementAddress, derived, base)
  {
    bytes32 relationId = getRelationId(agreementAddress, derived);
    relations[relationId].relationId = relationId;
    relations[relationId].agreementAddress = agreementAddress;
    relations[relationId].derived = derived;
    relations[relationId].base = base;
    relations[relationId].offset = offset;
    relations[relationId].exists = true;

    emit LogInitAgreementDateRelation(
      EVENT_ID_AGREEMENT_DATE_RELATION,
      agreementAddress,
      derived,
      base,
      offset
    );
  }

  /**
  * @notice Removes the given date's relation with another date
  * @param agreementAddress The agreement under which the derived date lives
  * @param derived identifier for the derived date
  */
  function remove(address agreementAddress, bytes32 derived)
  external
  partiesOnly(agreementAddress)
  {
    bytes32 relationId = getRelationId(agreementAddress, derived);
    delete relations[relationId];
    emit LogDeleteAgreementDateRelation(
      EVENT_ID_AGREEMENT_DATE_RELATION,
      relations[relationId].agreementAddress,
      relations[relationId].derived,
      DELETION
    );
  }

  /**
  * @notice Returns the relations mapping key for the given date
  * @param agreementAddress The agreement under which the derived date lives
  * @param derived identifier for the derived date
  */
  function getRelationId(address agreementAddress, bytes32 derived) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(agreementAddress, derived));
  }

  /**
  * @notice Returns whether an inverse relation already exists between the given base and derived dates
  * @param agreementAddress The agreement under which the dates live
  * @param base identifier for the base date
  * @param derived identifier for the derived date
  */
  function circularRelationExists(address agreementAddress, bytes32 derived, bytes32 base) internal view returns (bool) {
    if (derived == base) {
      // Date is derived from itself
      return true;
    }
    // Check if the base is derived from another date
    DateRelation memory baseRelation = relations[getRelationId(agreementAddress, base)];
    if (!baseRelation.exists) {
      // Nope; no possibility for circular relation
      return false;
    }
    if (baseRelation.base == derived) {
      // Date is derived from itself
      return true;
    }
    // Keep looking down the chain
    if (circularRelationExists(agreementAddress, derived, baseRelation.base)) {
      return true;
    }
    return false;
  }

  // Migrations - we need to implement these functions if DOUG is to attempt to upgrade this way at any time in the future
  function migrateFrom(address) public returns (bool success) {
    success = true;
  }

  function migrateTo(address) public returns (bool success) {
    // Who knows?
    success = true;
  }
}
