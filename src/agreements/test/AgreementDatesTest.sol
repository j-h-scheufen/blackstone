pragma solidity ^0.5;

import "../AgreementDates.sol";
import "./Mocks.sol";

contract AgreementDatesTest {
  string constant SUCCESS = "success";

  string constant relateSignature = "setRelation(address,bytes32,bytes32,string)";
  string constant unrelateSignature = "removeRelation(address,bytes32)";
  string constant cycleSignature = "setCycle(address,bytes32,string,uint)";
  string constant uncycleSignature = "removeCycle(address,bytes32)";
  string constant cycleMetaSignature = "setCycleMetadata(address,bytes32,string)";
  string constant incrementSignature = "incrementRecurrences(address,bytes32)";
  string constant functionSigForwardCall = "forwardCall(address,bytes)";

  // Pretend date identifiers
  bytes32 foo = "foo";
  bytes32 bar = "bar";
  bytes32 baz = "baz";
  bytes32 qux = "qux";
  bytes32 quux = "quux";
  
  string offset = "P1Y";
  string metadata = "{}";

  function testDateRelations() external returns (string memory) {
    MockParty someRando = new MockParty();
    address[] memory parties = new address[](1);
    parties[0] = address(this);
    MockAgreement agreement = new MockAgreement(parties);
    AgreementDates dates = new AgreementDates();
    bool success;

    // Call relate
    (success,) = address(dates).call(
      abi.encodeWithSignature(
        relateSignature,
        address(agreement),
        bar,
        foo,
        offset
      ));
    if (!success) return "Should allow adding a relation";

    // Can't base date off itself
    (success,) = address(dates).call(
      abi.encodeWithSignature(
        relateSignature,
        address(agreement),
        foo,
        foo,
        offset
      ));
    if (success) return "Should revert when trying to base a date off itself";

    // Relating again with a different base+offset is fine
    (success,) = address(dates).call(
      abi.encodeWithSignature(
        relateSignature,
        address(agreement),
        bar,
        baz,
        offset
      ));
    if (!success) return "Should allow re-relating a date with another base and offset";

    // Can't introduce circular relation (depth 1)
    dates.setRelation(address(agreement), bar, foo, offset);

    (success,) = address(dates).call(
      abi.encodeWithSignature(
        relateSignature,
        address(agreement),
        foo,
        bar,
        offset
      ));
    if (success) return "Should revert when trying to introduce a circular relation (depth 1)";

    // Can't introduce circular relation (depth 3)
    dates.setRelation(address(agreement), baz, bar, offset);
    dates.setRelation(address(agreement), qux, baz, offset);
    (success,) = address(dates).call(
      abi.encodeWithSignature(
        relateSignature,
        address(agreement),
        foo,
        qux,
        offset
      ));
    if (success) return "Should revert when trying to introduce a circular relation (depth 3)";

    // Can't relate dates for an agreement you aren't party to
    (success,) = address(someRando).call(
      abi.encodeWithSignature(
        functionSigForwardCall,
        address(dates),
        abi.encodeWithSignature(
          relateSignature,
          address(agreement),
          quux,
          qux,
          offset
        )));
    if (success) return "Should revert when trying to relate dates on an agreement without party auth";

    // Call removeRelation
    dates.removeRelation(address(agreement), bar);

    // Calling removeRelation again is fine
    (success,) = address(dates).call(
      abi.encodeWithSignature(
        unrelateSignature,
        address(agreement),
        bar
      ));
    if (!success) return "Should allow removing a non existing relation";

    // Can't remove relation for an agreement you aren't party to
    (success,) = address(someRando).call(
      abi.encodeWithSignature(
        functionSigForwardCall,
        address(dates),
        abi.encodeWithSignature(
          unrelateSignature,
          address(agreement),
          baz
        )));
    if (success) return "Should revert when trying to remove date relation on an agreement without party auth";

    return SUCCESS;
  }

  function testDateCycles() external returns (string memory) {
    MockParty someRando = new MockParty();
    address[] memory parties = new address[](1);
    parties[0] = address(this);
    MockAgreement agreement = new MockAgreement(parties);
    AgreementDates dates = new AgreementDates();
    bool success;

    // Call setCycle
    dates.setCycle(address(agreement), foo, metadata, 0);
    dates.setCycle(address(agreement), foo, metadata, 1);

    // Can't add cycle for an agreement you aren't party to
    (success,) = address(someRando).call(
      abi.encodeWithSignature(
        functionSigForwardCall,
        address(dates),
        abi.encodeWithSignature(
          cycleSignature,
          address(agreement),
          foo,
          metadata,
          0
        )));
    if (success) return "Should revert when trying to set date cycle on an agreement without party auth";

    // Call removeCycle
    dates.removeCycle(address(agreement), foo);

    // Calling removeCycle again is fine
    (success,) = address(dates).call(
      abi.encodeWithSignature(
        uncycleSignature,
        address(agreement),
        foo
      ));
    if (!success) return "Should allow removing a non existing cycle";

    // Can't remove cycle for an agreement you aren't party to
    (success,) = address(someRando).call(
      abi.encodeWithSignature(
        functionSigForwardCall,
        address(dates),
        abi.encodeWithSignature(
          uncycleSignature,
          address(agreement),
          foo
        )));
    if (success) return "Should revert when trying to remove date cycle on an agreement without party auth";

    // Can't increment non-existing cycle
    (success,) = address(dates).call(
      abi.encodeWithSignature(
        incrementSignature,
        address(agreement),
        foo
      ));
    if (success) return "Should revert when trying to increment non-existing cycle";

    dates.setCycle(address(agreement), foo, metadata, 0);

    // Call increment
    uint recurred = dates.incrementRecurrences(address(agreement), foo);
    if (recurred != 1) return "Should return number of recurrences";

    // Call setCycleMetadata
    dates.setCycleMetadata(address(agreement), foo, metadata);

    dates.removeCycle(address(agreement), foo);
    // Can't set meta on non-existing cycle
    (success,) = address(dates).call(
      abi.encodeWithSignature(
        cycleMetaSignature,
        address(agreement),
        foo,
        metadata
      ));
    if (success) return "Should revert when trying to set metadata for non-existing cycle";

    return SUCCESS;
  }
}
