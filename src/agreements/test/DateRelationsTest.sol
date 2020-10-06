pragma solidity ^0.5;

import "../DateRelations.sol";
import "./Mocks.sol";

contract DateRelationsTest {
  string constant SUCCESS = "success";

  string constant relateSignature = "relate(address,bytes32,bytes32,string)";
  string constant removeSignature = "remove(address,bytes32)";
  string constant functionSigForwardCall = "forwardCall(address,bytes)";

  // Pretend date identifiers
  bytes32 foo = "foo";
  bytes32 bar = "bar";
  bytes32 baz = "baz";
  bytes32 qux = "qux";
  bytes32 quux = "quux";
  
  string offset = "P1Y";

  function testDateRelations() external returns (string memory) {
    MockParty someRando = new MockParty();
    address[] memory parties = new address[](1);
    parties[0] = address(this);
    MockAgreement agreement = new MockAgreement(parties);
    DateRelations rels = new DateRelations();
    bool success;

    // Call relate
    (success,) = address(rels).call(
      abi.encodeWithSignature(
        relateSignature,
        address(agreement),
        bar,
        foo,
        offset
      )
    );
    if (!success) return "Should allow adding a relation";

    // Can't base date off itself
    (success,) = address(rels).call(
      abi.encodeWithSignature(
        relateSignature,
        address(agreement),
        foo,
        foo,
        offset
      )
    );
    if (success) return "Should revert when trying to base a date off itself";

    // Relating again with a different base+offset is fine
    (success,) = address(rels).call(
      abi.encodeWithSignature(
        relateSignature,
        address(agreement),
        bar,
        baz,
        offset
      )
    );
    if (!success) return "Should allow re-relating a date with another base and offset";

    // Can't introduce circular relation (depth 1)
    rels.relate(address(agreement), bar, foo, offset);

    (success,) = address(rels).call(
      abi.encodeWithSignature(
        relateSignature,
        address(agreement),
        foo,
        bar,
        offset
      )
    );
    if (success) return "Should revert when trying to introduce a circular relation (depth 1)";

    // Can't introduce circular relation (depth 3)
    rels.relate(address(agreement), baz, bar, offset);
    rels.relate(address(agreement), qux, baz, offset);
    (success,) = address(rels).call(
      abi.encodeWithSignature(
        relateSignature,
        address(agreement),
        foo,
        qux,
        offset
      )
    );
    if (success) return "Should revert when trying to introduce a circular relation (depth 3)";

    // Can't relate dates for an agreement you aren't party to
    (success,) = address(someRando).call(
      abi.encodeWithSignature(
        functionSigForwardCall,
        address(rels),
        abi.encodeWithSignature(
          relateSignature,
          address(agreement),
          quux,
          qux,
          offset
        )
      )
    );
    if (success) return "Should revert when trying to relate dates on an agreement without party auth";

    // Call remove
    rels.remove(address(agreement), bar);

    // Calling remove again is fine
    (success,) = address(rels).call(
      abi.encodeWithSignature(
        removeSignature,
        address(agreement),
        bar
      )
    );
    if (!success) return "Should allow removing a non existing relation";

    // Can't remove relation for an agreement you aren't party to
    (success,) = address(someRando).call(
      abi.encodeWithSignature(
        functionSigForwardCall,
        address(rels),
        abi.encodeWithSignature(
          removeSignature,
          address(agreement),
          baz
        )
      )
    );
    if (success) return "Should revert when trying to remove date relation on an agreement without party auth";

    return SUCCESS;
  }
}
