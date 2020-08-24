import "agreements/AgreementsAPI.sol";
import "commons-base/ErrorsLib.sol";
import "commons-utils/Strings.sol";

pragma solidity ^0.5;

contract CompletableOptions {
    // Completable options
    uint public constant DEFAULT = 0;
    /**
    * Set: Automatically call complete on the Completable when ratified
    * Not set: Wait for Complete to be called externally
    */
    uint public constant COMPLETE_ON_RATIFICATION = 1;
    /**
    * Set: persist the Completable as forever completed preserving relations involving it and reserving its intervalId in perpetuity
    * Not set: delete the Completable on completion releasing its intervalId for reuse and remove relations in which the Completable is involved
    */
    uint public constant PERSIST_ON_COMPLETION = 1 << 1;

    function enabled(uint options, uint option) public pure returns (bool) {
        return options & option > 0;
    }
}

contract Completables is CompletableOptions {
    using Strings for *;

    // This is a placeholder value for the marker field - it could be anything
    int constant DELETION = 0;

    bytes32 constant EVENT_ID_AGREEMENT_COMPLETABLE = "AN://agreement-completable";

    event LogAgreementCompletableInit(
        bytes32 indexed eventURN,
        bytes32 indexed intervalId,
        address agreementAddress,
        address controller,
        uint threshold,
        string payload
    );

    event LogAgreementCompletableInitFranchisee(
        bytes32 indexed eventURN,
        bytes32 indexed intervalId,
        address franchisee
    );

    event LogAgreementCompletableBegin(
        bytes32 indexed eventURN,
        bytes32 indexed intervalId,
        address agreementAddress,
        int timestamp
    );

    event LogAgreementCompletableRatify(
        bytes32 indexed eventURN,
        bytes32 indexed intervalId,
        address agreementAddress,
        address franchisee,
        bool ratified,
        int timestamp
    );

    event LogAgreementCompletableComplete(
        bytes32 indexed eventURN,
        bytes32 indexed intervalId,
        address agreementAddress,
        bool ratified,
        int timestamp
    );

    event LogRelateIntervals(
        bytes32 indexed eventURN,
        bytes32 left,
        uint16 relation,
        bytes32 right
    );

    // TODO: with some Vent changes we should be able to delete clean up all relations over intervals that neither exist
    //   would need two deletion projections: one with intervalId => left, one with intervalId => right and change the
    //   deletion logic to support deleting multiple rows probably through some opt-in flag
    //   see: https://github.com/hyperledger/burrow/issues/1403
    event LogDeleteInterval(
        bytes32 indexed eventURN,
        bytes32 indexed intervalId,
        int __DELETE__
    );

    struct Franchisee {
        address franchiseeAddress;
        bool ratified;
    }

    struct Completable {
        // External identifier that must be globally unique
        bytes32 intervalId;
        // Index in the intervals storage variable to provide iterability
        uint index;
        // Note: currently all Completables are scoped to an agreement but this is intended to be relaxed to allow
        // completables to describe relations between agreements
        address agreementAddress;
        // Addresses Those who may vote in the implicit ballot of a Completable
        Franchisee[] franchisees;
        // Number of elements in franchisees list
        uint threshold;
        address controller;
        uint options;
        // Timestamps
        int begun;
        int completed;
        int ratified;
        bool exists;
    }

    // intervalId => franchisees
    mapping(bytes32 => Completable) completables;
    bytes32[] intervals;

    modifier intervalExists(bytes32 intervalId) {
        if (!completables[intervalId].exists) {
            revert("Completable ".concat(intervalId.quote(), " does not exist"));
        }
        _;
    }

    modifier onlyController(bytes32 intervalId) {
        // Allow self calls for COMPLETE_ON_RATIFICATION
        if (msg.sender != address(this) && completables[intervalId].controller != msg.sender) {
            revert(Strings.concat("caller is not Completable controller: ", msg.sender.toHex(),
                " (msg.sender) != ", completables[intervalId].controller.toHex(), " (controller) ",
                " for Completable ", intervalId.quote()));
        }
        _;
    }

    modifier intervalOpen(bytes32 intervalId, int instant) {
        if (instant == 0) {
            instant = int(block.timestamp);
        }
        if (completables[intervalId].begun == 0) {
            revert("Completable ".concat(intervalId.quote(), " is has not yet begun"));
        }
        if (instant < completables[intervalId].begun) {
            revert("Completable ".concat(intervalId.quote(), " begins later (at ",
                completables[intervalId].begun.toString(), ") than instant ", instant.toString()));
        }
        if (completables[intervalId].completed != 0 && completables[intervalId].completed < instant) {
            revert("Completable ".concat(intervalId.quote(), " is completed (as ",
                completables[intervalId].completed.toString(), " before instant ", instant.toString()));
        }
        _;
    }

    /**
    * @notice Configures and registers a new Completable. This reserves the `intervalId` and allows it to participate
    *         in relations. The caller (msg.sender) of init becomes the 'controller' of this Completable and is
    *         the only identity permitted to call `begin`, `complete`, and `relate`
    * @param franchisees contains the addresses of all agreement parties that are able to ratify ('vote on') this
    *        Completable. If a franchisee appears multiple times then their vote counts that many times (contributes
    *        that many times to the threshold).
    * @param threshold sets the number of ratifications (votes from franchisees counted as above) required for the
             Completable to be 'ratified'. The alternative is that the Completable 'defaults'
    * @param options sets various options for how Completables operate, see constants above
    * @param payload is an opaque datum that is meaningful to the Completable controller
    */
    function init(bytes32 intervalId,
        address agreementAddress,
        address[] calldata franchisees,
        uint threshold,
        uint options,
        string calldata payload)
    external
    {
        if (completables[intervalId].exists) {
            revert(Strings.concat("Completable ", intervalId.quote(), " already exists"));
        }
        if (threshold > franchisees.length) {
            revert(Strings.concat("Cannot create a completable with ratification threshold (", threshold.toString(),
                ") greater than number of franchisees (", franchisees.length.toString(), ")"));
        }
        completables[intervalId].intervalId = intervalId;
        completables[intervalId].agreementAddress = agreementAddress;
        completables[intervalId].threshold = threshold;
        completables[intervalId].options = options;
        completables[intervalId].controller = msg.sender;
        completables[intervalId].exists = true;

        emit LogAgreementCompletableInit(EVENT_ID_AGREEMENT_COMPLETABLE,
            intervalId,
            agreementAddress,
            msg.sender,
            threshold,
            payload);

        for (uint i = 0; i < franchisees.length; i++) {
            completables[intervalId].franchisees.push(Franchisee(franchisees[i], false));

            emit LogAgreementCompletableInitFranchisee(EVENT_ID_AGREEMENT_COMPLETABLE,
                intervalId,
                franchisees[i]);
        }
    }

    function relate(bytes32 left, uint16 relation, bytes32 right)
    external
    intervalExists(left)
    onlyController(left)
    intervalExists(right)
    onlyController(right)
    {
        emit LogRelateIntervals(EVENT_ID_AGREEMENT_COMPLETABLE, left, relation, right);
    }

    function begin(bytes32 intervalId, int timestamp)
    external
    intervalExists(intervalId)
    onlyController(intervalId)
    {
        if (completables[intervalId].completed != 0) {
            revert("begin(): cannot begin completable that has already completed");
        }
        if (completables[intervalId].begun != 0) {
            // We could revert here but it's nicer if we can provide idempotence - TODO: review WRT lair
            return;
        }
        if (timestamp == 0) {
            timestamp = int(block.timestamp);
        }
        completables[intervalId].begun = timestamp;
        emit LogAgreementCompletableBegin(EVENT_ID_AGREEMENT_COMPLETABLE,
            intervalId,
            completables[intervalId].agreementAddress,
            timestamp);
    }

    /**
     * @notice ratify this completable, deriving the franchisee from the caller via the agreement associated with the completable
     * @return whether the Completable is ratified after this invocation
     */
    function ratify(bytes32 intervalId, int timestamp)
    external
    intervalExists(intervalId)
    intervalOpen(intervalId, timestamp)
    returns (bool)
    {
        address actor;
        address franchisee;
        (actor, franchisee) = AgreementsAPI.authorizePartyActor(completables[intervalId].agreementAddress);
        ErrorsLib.revertIf(actor == address(0),
            ErrorsLib.UNAUTHORIZED(), "Completables.ratify()",
            Strings.concat("The caller is not authorized to ratify ", intervalId.quote()));

        if (timestamp == 0) {
            timestamp = int(block.timestamp);
        }
        if (ratifyAndCount(intervalId, franchisee) >= completables[intervalId].threshold) {
            completables[intervalId].ratified = timestamp;
        }
        // Avoid stack too deep issues with local variables
        Completable memory completable = completables[intervalId];

        bool isRatified = completable.ratified != 0;
        emit LogAgreementCompletableRatify(EVENT_ID_AGREEMENT_COMPLETABLE,
            intervalId,
            completable.agreementAddress,
            franchisee,
            isRatified,
            timestamp);

        if (isRatified && enabled(completable.options, COMPLETE_ON_RATIFICATION)) {
            this.complete(intervalId, timestamp);
        }

        return isRatified;
    }

    function ratify(bytes32 intervalId) external returns (bool){
        return this.ratify(intervalId, 0);
    }

    function complete(bytes32 intervalId, int timestamp)
    external
    intervalExists(intervalId)
    onlyController(intervalId)
    returns (bool isRatified) {
        if (completables[intervalId].begun == 0) {
            revert("complete(): cannot complete completable that has not begun");
        }
        isRatified = completables[intervalId].ratified != 0;
        if (completables[intervalId].completed != 0) {
            return isRatified;
        }
        if (timestamp == 0) {
            timestamp = int(block.timestamp);
        }
        completables[intervalId].completed = timestamp;
        emit LogAgreementCompletableComplete(EVENT_ID_AGREEMENT_COMPLETABLE,
            intervalId,
            completables[intervalId].agreementAddress,
            isRatified,
            timestamp
        );

        if (!enabled(completables[intervalId].options, PERSIST_ON_COMPLETION)) {
            // TODO: Vent needs https://github.com/hyperledger/burrow/issues/1403 so this can clean up unused relations
            emit LogDeleteInterval(EVENT_ID_AGREEMENT_COMPLETABLE,
                intervalId,
                DELETION);
            delete completables[intervalId];
        }
    }

    /**
    * @return the timestamp when this Completable was ratified, or 0 if it has not yet been ratified, or -1 if it is
    *   complete and will never be ratified (it defaulted)
    */
    function ratifiedAt(bytes32 intervalId)
    external
    intervalExists(intervalId)
    view
    returns (int ratified){
        ratified = completables[intervalId].ratified;
        if (ratified == 0 && completables[intervalId].completed != 0) {
            // Will never be ratified
            ratified = - 1;
        }
    }

    function ratifyAndCount(bytes32 intervalId, address franchisee) internal returns (uint ratifications) {
        bool found;
        for (uint256 i; i < completables[intervalId].franchisees.length; i++) {
            // Note the same franchisee may appear multiple times, we could normalise this into a single franchisee but we don't
            if (completables[intervalId].franchisees[i].franchiseeAddress == franchisee) {
                completables[intervalId].franchisees[i].ratified = true;
                found = true;
            }
            if (completables[intervalId].franchisees[i].ratified) {
                ratifications++;
            }
        }
        if (!found) {
            revert(franchisee.toHex().concat(" is not a franchisee of interval ", intervalId.quote()));
        }
        return ratifications;
    }
}
