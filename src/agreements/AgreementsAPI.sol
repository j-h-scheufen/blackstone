pragma solidity ^0.5;

import "commons-standards/ERC165Utils.sol";
import "commons-auth/Governance.sol";
import "commons-auth/Organization.sol";

import "agreements/ActiveAgreement.sol";

/**
 * @title AgreementsAPI
 * @dev Library with functions around agreements
 */
library AgreementsAPI {

  /**
   * @dev Checks whether the given agreement is fully executed.
   * @param _agreementAddress an ActiveAgreement address
   * @return true if all parties have signed, false otherwise
   */
  function isFullyExecuted(address _agreementAddress) public view returns (bool) {
    ActiveAgreement agreement = ActiveAgreement(_agreementAddress);
    uint timestamp;
    for (uint i = 0; i < agreement.getNumberOfParties(); i++) {
      (, timestamp) = agreement.getSignatureDetails(agreement.getPartyAtIndex(i));
      if (timestamp == 0) {
        return false;
      }
    }
    return true;
  }

  /**
   * @dev Evaluates the msg.sender and tx.origin against the given agreement to determine if there is an authorized party/actor relationship.
   * @param _agreementAddress an ActiveAgreement address
   * @return actor - the address of either msg.sender or tx.origin depending on which one was authorized; 0x0 if authorization failed
   * @return party - the agreement party associated with the identified actor. This is typically the same as the actor, but can also contain
   * an Organization address if an Organization was registered as a party. 0x0 if authorization failed
   */
  function authorizePartyActor(address _agreementAddress) public returns (address actor, address party) {

    ActiveAgreement agreement = ActiveAgreement(_agreementAddress);
    address current;
    uint i;
    uint size = agreement.getNumberOfParties();

    // try establish a direct party actor (i.e. the address of party is sender/origin)
    for (i = 0; i < size; i++) {
      current = agreement.getPartyAtIndex(i);
      if (current == msg.sender || current == tx.origin) {
        actor = current;
        party = current;
        // for a direct match, the actor is the party
        return (actor, party);
      }
    }

    // Now check to see if sender/origin is authorised to act via their membership of an organisation
    for (i = 0; i < size; i++) {
      current = agreement.getPartyAtIndex(i);
      // Is the current party an organisation?
      if (ERC165Utils.implementsInterface(current, Governance.ERC165_ID_Organization())) {
        // Now we knwo that 'current' is a party, and that party is an organisation. The agreement may further specify
        // that the current party belongs to an organisation AND a scope on that organisation

        // Note: this 'scope' currently only ever means 'department' (team).

        // Note: this is just a very indirected way of accessing a map of scopes on the agreement
        bytes32 scope = agreement.resolveAddressScope(current, agreement.DATA_FIELD_AGREEMENT_PARTIES(), agreement);

        // Now we know that an actor for this party needs to hold 'scope' (possibly empty) on the organisation in order
        // to act

        // See if sender holds scope on org
        if (Organization(current).authorizeUser(msg.sender, scope)) {
          actor = msg.sender;
          party = current;
          return (actor, party);
        }
        // See if origin holds cope on org
        else if (Organization(current).authorizeUser(tx.origin, scope)) {
          actor = tx.origin;
          party = current;
          return (actor, party);
        }
      }
    }
  }

}
