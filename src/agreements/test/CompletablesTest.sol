// SPDX-License-Identifier: Parity-6.0.0
pragma solidity >=0.5;

import "../Completables.sol";
import "./Mocks.sol";

// lol solidity - just give me the constants
contract CompletablesTest is CompletableOptions {
  string constant SUCCESS = "success";

  string constant initSignature = "init(bytes32,string,string,address,address[],uint256,bool,string)";
  string constant attestSignature = "attestAsParty(bytes32,int256,address)";

  function testCompletables() external returns (string memory) {
    address us = address(this);
    MockParty them = new MockParty();
    address[] memory parties = new address[](2);
    parties[0] = us;
    parties[1] = address(them);
    MockAgreement agreement = new MockAgreement(parties);
    Completables comp = new Completables();
    address[] memory franchisees = new address[](2);
    franchisees[0] = address(this);
    franchisees[1] = address(them);

    uint threshold = 2;
    bytes32 intervalId = "foo";
    uint options = COMPLETE_ON_RATIFICATION;

    comp.init(intervalId, "crochet", "quaver", address(agreement), franchisees, threshold, options, "nada");
    comp.begin(intervalId, 1);
    comp.attestAsParty(intervalId, 2, us);

    bool success;
    // Duplicate completable not allowedhttps://github.com/hyperledger/burrow/pull/1463
    (success,) = address(comp).call(abi.encodeWithSignature(initSignature,
      intervalId,
      address(agreement),
      franchisees,
      threshold,
      options,
      "nada"));

    if (success) {
      return "Should revert when trying to init a Completable with same intervalId as existing open interval";
    }


    // Let's attest
    them.forwardCall(address(comp), abi.encodeWithSignature(attestSignature, intervalId, 3, address(them)));

    int ratificationTimestamp = comp.ratifiedAt(intervalId);
    if (ratificationTimestamp != 3) {
      return "Ratification timestamp should equal that of last attestation";
    }

    comp.activate();

    return SUCCESS;
  }

}
