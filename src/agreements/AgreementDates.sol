import "agreements/AgreementsAPI.sol";
import "commons-base/ErrorsLib.sol";
import "commons-utils/Strings.sol";
import "commons-management/AbstractUpgradeable.sol";
import "commons-management/AbstractVersionedArtifact.sol";

// SPDX-License-Identifier: Parity-6.0.0
pragma solidity >=0.5;

contract AgreementDates is AbstractVersionedArtifact(1, 0, 0), AbstractUpgradeable {
  using Strings for *;

  // This is a placeholder value for the marker field - it could be anything
  int constant DELETION = 0;

  bytes32 constant EVENT_ID_AGREEMENT_DATE_RELATION = "AN://date-relation";
  bytes32 constant EVENT_ID_AGREEMENT_DATE_CYCLE = "AN://date-cycle";

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

  event LogInitAgreementDateCycle(
    bytes32 indexed eventURN,
    address indexed agreementAddress,
    bytes32 indexed date,
    string metadata,
    uint recurred
  );

  event LogDeleteAgreementDateCycle(
    bytes32 indexed eventURN,
    address indexed agreementAddress,
    bytes32 indexed date,
    int __DELETE__
  );

  event LogIncrementAgreementDateCycle(
    bytes32 indexed eventURN,
    address indexed agreementAddress,
    bytes32 indexed date,
    uint recurred
  );

  event LogSetAgreementDateCycleMetadata(
    bytes32 indexed eventURN,
    address indexed agreementAddress,
    bytes32 indexed date,
    string metadata
  );

  struct DateRelation {
    bytes32 relationId;
    address agreementAddress;
    bytes32 derived;
    bytes32 base;
    string offset;
    bool exists;
  }

  struct DateCycle {
    bytes32 cycleId;
    address agreementAddress;
    bytes32 date;
    uint recurred;
    bool exists;
  }

  mapping(bytes32 => DateRelation) relations;
  mapping(bytes32 => DateCycle) cycles;

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

  modifier cycleExists(address agreementAddress, bytes32 date) {
    bytes32 cycleId = getCycleId(agreementAddress, date);
    if (!cycles[cycleId].exists) {
      revert(
        Strings.concat(
          "Date ",
          date.quote(),
          " on agreement ",
          agreementAddress.quote(),
          " is not configured to recur"
        ));
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
  function setRelation(
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
  function removeRelation(address agreementAddress, bytes32 derived)
  external
  partiesOnly(agreementAddress)
  {
    bytes32 relationId = getRelationId(agreementAddress, derived);
    emit LogDeleteAgreementDateRelation(
      EVENT_ID_AGREEMENT_DATE_RELATION,
      relations[relationId].agreementAddress,
      relations[relationId].derived,
      DELETION
    );
    delete relations[relationId];
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

  /**
  * @notice Registers a new DateCycle or overwrites an existing one. The agreement address + date form the primary key for cycles.
  * @param agreementAddress The agreement under which the date lives.
  * @param date identifier for the cycling date.
  * @param metadata the interval between each cycle
  * @param recurred the number of times the date has cycled
  */
  function setCycle(
    address agreementAddress,
    bytes32 date,
    string calldata metadata,
    uint recurred
  )
  external
  partiesOnly(agreementAddress)
  {
    bytes32 cycleId = getCycleId(agreementAddress, date);
    cycles[cycleId].cycleId = cycleId;
    cycles[cycleId].agreementAddress = agreementAddress;
    cycles[cycleId].date = date;
    cycles[cycleId].recurred = recurred;
    cycles[cycleId].exists = true;

    emit LogInitAgreementDateCycle(
      EVENT_ID_AGREEMENT_DATE_CYCLE,
      agreementAddress,
      date,
      metadata,
      recurred
    );
  }

  /**
  * @notice Removes the given date's cycle
  * @param agreementAddress The agreement under which the date lives
  * @param date identifier for the date
  */
  function removeCycle(address agreementAddress, bytes32 date)
  external
  partiesOnly(agreementAddress)
  {
    bytes32 cycleId = getCycleId(agreementAddress, date);
    emit LogDeleteAgreementDateCycle(
      EVENT_ID_AGREEMENT_DATE_CYCLE,
      cycles[cycleId].agreementAddress,
      cycles[cycleId].date,
      DELETION
    );
    delete cycles[cycleId];
  }

  /**
  * @notice Increments the number of times a cycle has recurred
  * @param agreementAddress The agreement under which the date lives
  * @param date identifier for the date
  */
  function incrementRecurrences(address agreementAddress, bytes32 date)
  external
  cycleExists(agreementAddress, date)
  returns (uint)
  {
    bytes32 cycleId = getCycleId(agreementAddress, date);
    cycles[cycleId].recurred += 1;
    emit LogIncrementAgreementDateCycle(
      EVENT_ID_AGREEMENT_DATE_CYCLE,
      agreementAddress,
      date,
      cycles[cycleId].recurred
    );
    return cycles[cycleId].recurred;
  }

  /**
  * @notice Increments the number of times a cycle has recurred
  * @param agreementAddress The agreement under which the date lives
  * @param date identifier for the date
  * @param metadata new metadata for the cycle
  */
  function setCycleMetadata(address agreementAddress, bytes32 date, string calldata metadata)
  external
  cycleExists(agreementAddress, date)
  {
    emit LogSetAgreementDateCycleMetadata(
      EVENT_ID_AGREEMENT_DATE_CYCLE,
      agreementAddress,
      date,
      metadata
    );
  }

  /**
  * @notice Returns the cycles mapping key for the given date
  * @param agreementAddress The agreement under which the date lives
  * @param date identifier for the date
  */
  function getCycleId(address agreementAddress, bytes32 date) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(agreementAddress, date));
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
