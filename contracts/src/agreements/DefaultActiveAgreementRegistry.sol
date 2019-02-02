pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";
import "commons-base/BaseErrors.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";
import "commons-events/AbstractEventListener.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/ContractLocatorEnabled.sol";
import "commons-auth/ParticipantsManager.sol";
import "commons-utils/ArrayUtilsAPI.sol";
import "bpm-runtime/BpmRuntime.sol";
import "bpm-runtime/BpmService.sol";
import "bpm-runtime/ProcessInstance.sol";

import "agreements/Agreements.sol";
import "agreements/ActiveAgreement.sol";
import "agreements/DefaultActiveAgreement.sol";
import "agreements/ActiveAgreementRegistry.sol";
import "agreements/ActiveAgreementRegistryDb.sol";
import "agreements/Archetype.sol";
import "agreements/ArchetypeRegistry.sol";

/**
 * @title DefaultActiveAgreementRegistry Interface
 * @dev A contract interface to create and manage Active Agreements.
 */
contract DefaultActiveAgreementRegistry is Versioned(1,0,0), AbstractEventListener, AbstractDbUpgradeable, ContractLocatorEnabled, ActiveAgreementRegistry {

	using ArrayUtilsAPI for address[];

	// Temporary mapping to detect duplicates in address[] _governingAgreements
	mapping(address => uint) duplicateMap;

	//TODO these string should not be hardcoded. Inject via constructor after AN-307 fixed
	string constant serviceIdArchetypeRegistry = "ArchetypeRegistry";
	string constant serviceIdBpmService = "BpmService";

	ArchetypeRegistry archetypeRegistry;
	BpmService bpmService;

	/**
	 * verifies that the msg.sender is an agreement known to this registry
	 */
	modifier pre_OnlyByRegisteredAgreements() {
		if (ActiveAgreementRegistryDb(database).agreementIsRegistered(msg.sender))
			_;
	}

	/**
	 * @dev Creates an Active Agreement with the given parameters
	 * @param _archetype archetype
	 * @param _name name
	 * @param _creator address
	 * @param _privateParametersFileReference the file reference of the private parametes of this agreement
	 * @param _isPrivate agreement is private
	 * @param _parties parties array
	 * @param _collectionId id of agreement collection (optional)
	 * @param _governingAgreements array of agreement addresses which govern this agreement (optional)
	 * @return activeAgreement - the new ActiveAgreement's address, if successfully created, 0x0 otherwise
	 * Reverts if:
	 * 	Agreement name or archetype address is empty
	 * 	Duplicate governing agreements are passed
	 * 	Agreement address is already registered
	 * 	Given collectionId does not exist
	 */
	function createAgreement(
		address _archetype,
		string _name, 
		address _creator, 
		string _privateParametersFileReference,
		bool _isPrivate, 
		address[] _parties, 
		bytes32 _collectionId, 
		address[] _governingAgreements) 
		external returns (address activeAgreement)
	{
		validateAgreementRequirements(_archetype, _name, _governingAgreements);
		activeAgreement = new DefaultActiveAgreement(_archetype, _name, _creator, _privateParametersFileReference, _isPrivate, _parties, _governingAgreements);
		register(activeAgreement, _name);
		if (_collectionId != "") {
			addAgreementToCollection(_collectionId, activeAgreement);
		}
	}

	/**
	 * @dev Validates agreement creation requirements
	 */
	function validateAgreementRequirements(address _archetype, string _name, address[] _governingAgreements)	internal {
		ErrorsLib.revertIf(bytes(_name).length == 0 || _archetype == 0x0,
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultActiveAgreementRegistry.createAgreement", "Agreement name and Archetype address are required");
		validateGoverningAgreements(_archetype, _governingAgreements);
		ErrorsLib.revertIf(!Archetype(_archetype).isActive(),
			ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultActiveAgreementRegistry.createAgreement", "Archetype must be active");
	}

	/**
	 * @dev Validates governing agreements
	 */
	function validateGoverningAgreements(address _archetype, address[] _governingAgreements) internal {
		address derivedGoverningArchetype;
		verifyNoDuplicates(_governingAgreements);
		
		// predefined governing archetypes of this agreement's archetype
		address[] memory governingArchetypes = Archetype(_archetype).getGoverningArchetypes();
		
		// _governingAgreements length must match governingArchetypes length
		if (governingArchetypes.length != _governingAgreements.length) {
			revert(ErrorsLib.format(ErrorsLib.INVALID_INPUT(), 
				"DefaultActiveAgreement.verifyGoverningAgreements", 
				"Number of provided governing agreements do not match the number of predefined governing archetypes"));
		}

		// each of _governingAgreement's archetypes should be in governingArchetypes array
		for (uint i = 0; i < _governingAgreements.length; i++) {
			derivedGoverningArchetype = ActiveAgreement(_governingAgreements[i]).getArchetype();
			if (!governingArchetypes.contains(derivedGoverningArchetype)) {
				revert(ErrorsLib.format(ErrorsLib.INVALID_INPUT(), 
					"DefaultActiveAgreement.verifyGoverningAgreements", 
					"Provided governing agreement's archetype does not match any predefined governing archetype"));
			}
		}
 	}

	/**
	 * @dev Detects if governing agreements array has duplicates and reverts accordingly
	 * TODO - Consider moving this util function to MappingsLib and creating a AddressUintMap data structure for checking dupes
	 * @param _agreements the address[] array of governing agreements
	 */
	function verifyNoDuplicates(address[] _agreements) internal {
		if (_agreements.length > 0) {
			for (uint i = 0; i < _agreements.length; i++) {
				if (duplicateMap[_agreements[i]] != 0) {
					duplicateMap[_agreements[i]]++;
				} else {
					duplicateMap[_agreements[i]] = 1;
				}
				if (duplicateMap[_agreements[i]] > 1) {
					clearDuplicateMap(_agreements);
					revert(ErrorsLib.format(ErrorsLib.INVALID_INPUT(), 
						"DefaultActiveAgreementRegistry.verifyNoDuplicates", 
						"Governing agreements has duplicates"));
				}
			}
			clearDuplicateMap(_agreements);
		}
	}

	/**
	 * @dev Clears the temporary mapping that is used to check for duplicate governing agreements
	 * @param _agreements the address[] array of governing agreements
	 */
	function clearDuplicateMap (address[] _agreements) internal {
		for (uint i = 0; i < _agreements.length; i++) {
			delete duplicateMap[_agreements[i]];
		}
	}

	/**
	 * @dev Registers the provided ActiveAgreement and adds event listeners
	 * @param _activeAgreement the Active Agreement
	 * @param _name the agreement name
	 * @return a return code indicating success or failure
	 */
	function register(address _activeAgreement, string _name) internal {
		uint error = ActiveAgreementRegistryDb(database).registerActiveAgreement(_activeAgreement, _name);
		ErrorsLib.revertIf(error != BaseErrors.NO_ERROR(),
			ErrorsLib.RESOURCE_ALREADY_EXISTS(), "DefaultActiveAgreementRegistry.register", "Active Agreement already exists");
		ActiveAgreement agreement = ActiveAgreement(_activeAgreement);
		agreement.addEventListener(agreement.EVENT_ID_STATE_CHANGED());
	}

	/**
	 * @dev Sets the max number of events for this agreement
	 */
	function setMaxNumberOfEvents(address _agreement, uint32 _maxNumberOfEvents) external {
		ActiveAgreement(_agreement).setMaxNumberOfEvents(_maxNumberOfEvents);
	}

	/**
	 * @dev Adds an agreement to given collection
	 * REVERTS if:
	 * - a collection with the given ID is not found
	 * - the agreement's archetype is part of the collection's package
	 * @param _collectionId the bytes32 collection id
	 * @param _agreement agreement address
	 */
	function addAgreementToCollection(bytes32 _collectionId, address _agreement) public {
		bytes32 packageId;
		address archetype = ActiveAgreement(_agreement).getArchetype();
		( , , , packageId) = ActiveAgreementRegistryDb(database).getCollectionData(_collectionId);
		ErrorsLib.revertIf(packageId == "",
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultActiveAgreementRegistry.addAgreementToCollection", "No packageId found for given collection");
		ErrorsLib.revertIf(!archetypeRegistry.packageHasArchetype(packageId, archetype),
			ErrorsLib.INVALID_INPUT(), "DefaultActiveAgreementRegistry.addAgreementToCollection", "Agreement archetype not found in given collection's package");
		uint error = ActiveAgreementRegistryDb(database).addAgreementToCollection(_collectionId, _agreement);
		ErrorsLib.revertIf(error != BaseErrors.NO_ERROR(),
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultActiveAgreementRegistry.addAgreementToCollection", "Collection not found");
		emit LogAgreementToCollectionUpdate(
			EVENT_ID_AGREEMENT_COLLECTION_MAP, 
			_collectionId,
			_agreement,
			ActiveAgreement(_agreement).getName(),
			ActiveAgreement(_agreement).getArchetype()
		);
	}

	/**
	 * @dev Creates and starts a ProcessInstance to handle the workflows as defined by the given agreement's archetype.
	 * Depending on the configuration in the archetype, the returned address can be either a formation process or an execution process.
	 * An execution process will only be started if *no* formation process is defined for the archetype. Otherwise,
	 * the execution process will automatically start after the formation process (see #processStateChanged(ProcessInstance))
	 * REVERTS if:
	 * - the provided ActiveAgreement is a 0x0 address
	 * - a formation process should be started, but the legal state of the agreement is not FORMULATED
	 * - a formation process should be started, but there is already an ongoing formation ProcessInstance registered for this agreement
	 * - an execution process should be started, but the legal state of the agreement is not EXECUTED
	 * - an execution process should be started, but there is already an ongoing execution ProcessInstance registered for this agreement
	 * @param _agreement an ActiveAgreement
	 * @return error - BaseErrors.NO_ERROR() if a ProcessInstance was started successfully, or a different error code if there were problems in the process
	 * @return the address of a ProcessInstance, if successful
	 */
	function startProcessLifecycle(ActiveAgreement _agreement)
		external
		returns (uint error, address)
	{
		ErrorsLib.revertIf(address(_agreement) == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultActiveAgreementRegistry.startProcessLifecycle", "The provided ActiveAgreement must exist");

		// FORMATION PROCESS
		if (Archetype(_agreement.getArchetype()).getFormationProcessDefinition() != address(0)) {
			ErrorsLib.revertIf(_agreement.getLegalState() != uint8(Agreements.LegalState.FORMULATED),
				ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultActiveAgreementRegistry.startProcessLifecycle", "The ActiveAgreement must be in state FORMULATED to start the formation process");
			ErrorsLib.revertIf(ActiveAgreementRegistryDb(database).getAgreementFormationProcess(address(_agreement)) != address(0),
				ErrorsLib.OVERWRITE_NOT_ALLOWED(), "DefaultActiveAgreementRegistry.startProcessLifecycle", "The provided agreement already has an ongoing formation ProcessInstance");
			
			ProcessInstance pi = createFormationProcess(_agreement);
			// keep track of the process for the agreement, regardless of whether the start (below) actually succeeds, because the PI is created
			ActiveAgreementRegistryDb(database).setAgreementFormationProcess(address(_agreement), address(pi));
			error = bpmService.startProcessInstance(pi);
			return(error, address(pi));
		}
		// EXECUTION PROCESS
		else if (Archetype(_agreement.getArchetype()).getExecutionProcessDefinition() != address(0)) {
			ErrorsLib.revertIf(_agreement.getLegalState() != uint8(Agreements.LegalState.EXECUTED),
				ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultActiveAgreementRegistry.startProcessLifecycle", "The ActiveAgreement must be in state EXECUTED to start the execution process");
			ErrorsLib.revertIf(ActiveAgreementRegistryDb(database).getAgreementExecutionProcess(address(_agreement)) != address(0),
				ErrorsLib.OVERWRITE_NOT_ALLOWED(), "DefaultActiveAgreementRegistry.startProcessLifecycle", "The provided agreement already has an ongoing execution ProcessInstance");

			pi = createExecutionProcess(_agreement);
			ActiveAgreementRegistryDb(database).setAgreementExecutionProcess(address(_agreement), address(pi));
			error = bpmService.startProcessInstance(pi);
			return(error, address(pi));
		}
	}

	/**
	 * @dev Creates a ProcessInstance to handle the given agreement's formation process
	 * REVERTS if:
	 * - no Processdefinition can be found via the agreement's archetype
	 * @param _agreement an ActiveAgreement
	 * @return a ProcessInstance
	 */
	function createFormationProcess(ActiveAgreement _agreement) internal returns (ProcessInstance processInstance) {
		address pd = Archetype(_agreement.getArchetype()).getFormationProcessDefinition();
		ErrorsLib.revertIf(pd == 0x0,
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultActiveAgreementRegistry.createFormationProcess", "No ProcessDefinition found on the agreement's archetype");
		processInstance = bpmService.createDefaultProcessInstance(pd, msg.sender, bytes32(""));
		processInstance.addProcessStateChangeListener(this);
		processInstance.setDataValueAsAddress(DATA_ID_AGREEMENT, address(_agreement));
		transferAddressScopes(processInstance);
		emit LogAgreementFormationProcessUpdate(_agreement.EVENT_ID_AGREEMENTS(), address(_agreement), address(processInstance));
	}

	/**
	 * @dev Creates a ProcessInstance to handle the given agreement's execution process
	 * REVERTS if:
	 * - no Processdefinition can be found via the agreement's archetype
	 * @param _agreement an ActiveAgreement
	 * @return a ProcessInstance
	 */
	function createExecutionProcess(ActiveAgreement _agreement) internal returns (ProcessInstance processInstance) {
		address pd = Archetype(_agreement.getArchetype()).getExecutionProcessDefinition();
		ErrorsLib.revertIf(pd == 0x0,
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultActiveAgreementRegistry.createExecutionProcess", "No ProcessDefinition found on the agreement's archetype");
		processInstance = bpmService.createDefaultProcessInstance(pd, msg.sender, bytes32(""));
		processInstance.addProcessStateChangeListener(this);
		processInstance.setDataValueAsAddress(DATA_ID_AGREEMENT, address(_agreement));
		transferAddressScopes(processInstance);
		emit LogAgreementExecutionProcessUpdate(_agreement.EVENT_ID_AGREEMENTS(), address(_agreement), address(processInstance));
	}

	/**
	 * @dev Sets address scopes on the given ProcessInstance based on the scopes defined in the ActiveAgreement referenced in the ProcessInstance.
     * Address scopes relying on a ConditionalData configuration are translated, so they work from the POV of the ProcessInstance.
     * This function ensures that any scopes (roles) set for user/organization addresses on the agreement are available and adhered to in the process
	 * in the context of activities.
	 * Each scope on the agreement is examined whether its data field context is connected to a model participant (swimlane)
	 * in the ProcessDefinition/ProcessModel that guides the ProcessInstance. If a match is found, the activity definitions in the
	 * ProcessInstance that are connected (assigned) to the participant are used as contexts to set up address scopes on the ProcessInstance.
	 * This function performs a crucial translation of role restrictions specified on the agreement to make sure the same qualifications
	 * are available when performing user tasks using organizational scopes (departments).
	 * Example (address + context = scope):
	 * Address scope on the agreement using a data field context: 0x94EcB18404251B0C8E88B0D8fbde7145c72AEC22 + "Buyer" = "LogisticsDepartment"
	 * Address scope on the ProcessInstance using an activity context: 0x94EcB18404251B0C8E88B0D8fbde7145c72AEC22 + "ApproveOrder" = "LogisticsDepartment"
	 * REVERTS if:
	 * - the ProcessInstance is not in state CREATED
	 * - the provided ProcessInstance does not have an ActiveAgreement set under DATA_ID_AGREEMENT
	 * @param _processInstance the ProcessInstance being configured
	 */
	function transferAddressScopes(ProcessInstance _processInstance)
		public
	{
		ErrorsLib.revertIf(_processInstance.getState() != uint8(BpmRuntime.ProcessInstanceState.CREATED),
			ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultActiveAgreementRegistry.transferAddressScopes", "Cannot set role qualifiers on a ProcessInstance that has already started");
		ActiveAgreement agreement = ActiveAgreement(_processInstance.getDataValueAsAddress(DATA_ID_AGREEMENT));
		ErrorsLib.revertIf(address(agreement) == address(0),
			ErrorsLib.INVALID_PARAMETER_STATE(), "DefaultActiveAgreementRegistry.transferAddressScopes", "The provided ProcessInstance does not have an ActiveAgreement set");
		bytes32[] memory keys = agreement.getAddressScopeKeys();
		if (keys.length > 0) {
			ProcessModel model = ProcessDefinition(_processInstance.getProcessDefinition()).getModel();
			for (uint i=0; i<keys.length; i++) {
				transferAddressScope(keys[i], agreement, _processInstance, model);
			}
		}
	}

	/**
	 * @dev Transfers a single address scope with the given key from the ActiveAgreement to the ProcessInstance using the provided ProcessModel.
	 * This function is an extension of the transferAddressScopes(ProcessInstance) function to avoid running into stack issues due ot the amount of local variables.
	 * @param _scopeKey a bytes32 scope key
	 * @param _agreement an ActiveAgreement as the source of existing address scopes
	 * @param _processInstance a ProcessInstance as the target to which to transfer the address scopes
	 * @param _model a ProcessModel to lookup additional information about participants connected to the agreement scopes
	 */
	function transferAddressScope(bytes32 _scopeKey, ActiveAgreement _agreement, ProcessInstance _processInstance, ProcessModel _model)
		internal
	{
		(address scopeAddress, bytes32 scopeContext, bytes32 fixedScope, bytes32 dataPath, bytes32 dataStorageId, address dataStorage) = _agreement.getAddressScopeDetailsForKey(_scopeKey);
		// check on the model if the context was used as a dataPath on the agreement to define a participant
		bytes32 participant = _model.getConditionalParticipant(scopeContext, DATA_ID_AGREEMENT, address(_agreement));
		if (participant != "") {
			// retrieve all activities connected to that participant
			bytes32[] memory activityIds = ProcessDefinition(_processInstance.getProcessDefinition()).getActivitiesForParticipant(participant);
			if (activityIds.length > 0) {
				// conditional address scopes using dataStorageId are relative to the agreement and need to be replaced with the absolute address to remain valid in the PI
				if (dataStorageId != "" || dataStorage == address(0)) {
					dataStorage = DataStorageUtils.resolveDataStorageAddress(dataStorageId, dataStorage, _agreement);
					delete dataStorageId;
				}
				for (uint j=0; j<activityIds.length; j++) {
					// This is where the scope context of the agreement (using field IDs) is replaced with a context of activity IDs
					_processInstance.setAddressScope(scopeAddress, activityIds[j], fixedScope, dataPath, dataStorageId, dataStorage);
				}
			}
		}
	}

	/**
	 * @dev Returns the BpmService address
	 * @return address the BpmService
	 */
	function getBpmService() external returns (address) {
		return address(bpmService);
	}

	/**
	 * @dev Returns the ArchetypeRegistry address
	 * @return address the ArchetypeRegistry
	 */
	function getArchetypeRegistry() external returns (address) {
		return address(archetypeRegistry);
	}

    /**
     * @dev Overrides ContractLocatorEnabled.setContractLocator(address)
     */
    function setContractLocator(address _locator) public {
        super.setContractLocator(_locator);
        archetypeRegistry = ArchetypeRegistry(ContractLocator(_locator).getContract(serviceIdArchetypeRegistry));
        bpmService = BpmService(ContractLocator(_locator).getContract(serviceIdBpmService));
        ErrorsLib.revertIf(address(archetypeRegistry) == 0x0,
			ErrorsLib.DEPENDENCY_NOT_FOUND(), "DefaultActiveAgreementRegistry.setContractLocator", "ArchetypeRegistry not found");
        ErrorsLib.revertIf(address(bpmService) == 0x0,
			ErrorsLib.DEPENDENCY_NOT_FOUND(), "DefaultActiveAgreementRegistry.setContractLocator", "BpmService not found");
        ContractLocator(_locator).addContractChangeListener(serviceIdArchetypeRegistry);
        ContractLocator(_locator).addContractChangeListener(serviceIdBpmService);
    }

    /**
     * @dev Implements ContractLocatorEnabled.setContractLocator(address)
     */
    function contractChanged(string _name, address, address _newAddress) external pre_onlyByLocator {
        if (keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(serviceIdArchetypeRegistry))){
            archetypeRegistry = ArchetypeRegistry(_newAddress);
        }
        else if (keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(serviceIdBpmService))){
            bpmService = BpmService(_newAddress);
        }
    }

    /**
     * @dev Gets number of activeAgreements
     * @return size size
     */
    function getActiveAgreementsSize() external view returns (uint size) {
        return ActiveAgreementRegistryDb(database).getNumberOfActiveAgreements();
    }

    /**
     * @dev Gets the ActiveAgreement address at given index
     * @param _index the index position
     * @return the Active Agreement address
     */
	function getActiveAgreementAtIndex(uint _index) external view returns (address activeAgreement) {
    	return ActiveAgreementRegistryDb(database).getActiveAgreementAtIndex(_index);
    }

    /**
     * @dev Gets parties size for given Active Agreement
     * @param _activeAgreement Active Agreement
     * @return the number of parties
     */
	function getPartiesByActiveAgreementSize(address _activeAgreement) external view returns (uint size) {
    	return ActiveAgreement(_activeAgreement).getNumberOfParties();
    }

    /**
     * @dev Gets getPartyByActiveAgreementAtIndex
     * @param _activeAgreement Active Agreement
     * @param _index index
     * @return the party address or 0x0 if the index is out of bounds
     */
	function getPartyByActiveAgreementAtIndex(address _activeAgreement, uint _index) public view returns (address party) {
		return ActiveAgreement(_activeAgreement).getPartyAtIndex(_index);
    }

    /**
     * @dev Returns data about the ActiveAgreement at the specified address
	 * @param _activeAgreement Active Agreement
	 * @return archetype - the agreement's archetype adress
	 * @return name - the name of the agreement
	 * @return creator - the creator of the agreement
	 * @return privateParametersFileReference - the file reference to the private agreement parameters (only used when agreement is private)
	 * @return eventLogFileReference - the file reference to the agreement's event log
	 * @return maxNumberOfEvents - the maximum number of events allowed to be stored for this agreement
	 * @return isPrivate - whether there are private agreement parameters, i.e. stored off-chain
	 * @return legalState - the agreement's Agreement.LegalState as uint8
	 * @return formationProcessInstance - the address of the process instance representing the formation of this agreement
	 * @return executionProcessInstance - the address of the process instance representing the execution of this agreement
	 */
	function getActiveAgreementData(address _activeAgreement) external view returns (
		address archetype,
		string name,
		address creator,
		string privateParametersFileReference,
		string eventLogFileReference,
		uint maxNumberOfEvents,
		bool isPrivate,
		uint8 legalState,
		address formationProcessInstance,
		address executionProcessInstance
	) {
		name = ActiveAgreementRegistryDb(database).getActiveAgreementName(_activeAgreement);

		if (bytes(name).length != 0) {
			archetype = ActiveAgreement(_activeAgreement).getArchetype();
			creator = ActiveAgreement(_activeAgreement).getCreator();
			privateParametersFileReference = ActiveAgreement(_activeAgreement).getPrivateParametersReference();
			eventLogFileReference = ActiveAgreement(_activeAgreement).getEventLogReference();
			maxNumberOfEvents = ActiveAgreement(_activeAgreement).getMaxNumberOfEvents();			
			isPrivate = ActiveAgreement(_activeAgreement).isPrivate();
			legalState = ActiveAgreement(_activeAgreement).getLegalState();
			//TODO currently the references to process instances are being tracked in the registry, so they can be added
			// here for external data collection. Once the "Update..." events move into the individual agreements,
			// the agreement can track its own processes. Note: Questions arise over ownership of the processes for aborting;
			// the registry could transfer ownership to the agreement when starting the process instances, for example.
			formationProcessInstance = ActiveAgreementRegistryDb(database).getAgreementFormationProcess(_activeAgreement);
			executionProcessInstance = ActiveAgreementRegistryDb(database).getAgreementExecutionProcess(_activeAgreement);
		}
	}

  /**
	 * @dev Returns the number of agreement parameter values.
	 * @return the number of parameters
	 */
	function getNumberOfAgreementParameters(address _address) external view returns (uint size) {
			size = ActiveAgreement(_address).getNumberOfData();
	}

  /**
	 * @dev Returns the ID of the agreement parameter value at the given index.
	 * @param _pos the index
	 * @return the parameter ID
	 */
	function getAgreementParameterAtIndex(address _address, uint _pos) external view returns (bytes32 dataId) {
			uint error;
			(error, dataId) = ActiveAgreement(_address).getDataIdAtIndex(_pos);
	}

  /**
	 * @dev Returns information about the process data entry for the specified process and data ID
	 * @param _address the active agreement
	 * @param _dataId the parameter ID
	 * @return (process,id,uintValue,bytes32Value,addressValue,boolValue)
	 */
	function getAgreementParameterDetails(address _address, bytes32 _dataId) external view returns (
			address process,
			bytes32 id,
			uint uintValue,
			int intValue,
			bytes32 bytes32Value,
			address addressValue,
			bool boolValue) {

			process = _address;
			id = _dataId;
			uintValue = ActiveAgreement(_address).getDataValueAsUint(_dataId);
			intValue = ActiveAgreement(_address).getDataValueAsInt(_dataId);
			bytes32Value = ActiveAgreement(_address).getDataValueAsBytes32(_dataId);
			addressValue = ActiveAgreement(_address).getDataValueAsAddress(_dataId);
			boolValue = ActiveAgreement(_address).getDataValueAsBool(_dataId);
	}

    /**
     * @dev Returns data about the given party's signature on the specified agreement.
	 * @param _activeAgreement the ActiveAgreement
	 * @param _party the signing party
	 * @return signedBy the actual signature authorized by the party
	 * @return signatureTimestamp the timestamp when the party has signed, or 0 if not signed yet
	 */
	function getPartyByActiveAgreementData(address _activeAgreement, address _party) external view returns (address signedBy, uint signatureTimestamp) {
		(signedBy, signatureTimestamp) = ActiveAgreement(_activeAgreement).getSignatureDetails(_party);
	}

	/**
	 * @dev Creates a new agreement collection
	 * @param _name name
	 * @param _author address of author
	 * @return error BaseErrors.NO_ERROR(), BaseErrors.NULL_PARAM_NOT_ALLOWED(), BaseErrors.RESOURCE_ALREADY_EXISTS()
	 * @return id bytes32 id of package
	 */
	function createAgreementCollection(string _name, address _author, uint8 _collectionType, bytes32 _packageId) external returns (uint error, bytes32 id) {
		if (_author == 0x0 || _packageId == "") return (BaseErrors.NULL_PARAM_NOT_ALLOWED(), "");
		id = keccak256(abi.encodePacked(abi.encodePacked(_name, _author, block.timestamp)));
		error = ActiveAgreementRegistryDb(database).createCollection(id, _name, _author, _collectionType, _packageId);
		if (error == BaseErrors.NO_ERROR()) {
			emit LogAgreementCollectionCreation(
				EVENT_ID_AGREEMENT_COLLECTIONS,
				id,
				_name,
				_author,
				_collectionType,
				_packageId
			);
		}
	}

	/**
	 * @dev Gets number of agreement collections
	 * @return size size
	 */
	function getNumberOfAgreementCollections() external view returns (uint size) {
		return ActiveAgreementRegistryDb(database).getNumberOfCollections();
	}

	/**
	 * @dev Gets collection id at index
	 * @param _index uint index
	 * @return id bytes32 id
	 */
	function getAgreementCollectionAtIndex(uint _index) external view returns (bytes32 id) {
		return ActiveAgreementRegistryDb(database).getCollectionAtIndex(_index);
	}

	/**
	 * @dev Gets collection data by id
	 * @param _id bytes32 collection id
	 * @return name string
	 * @return author address
	 * @return collectionType type of collection
	 * @return packageId id of the archetype package
	 */
	function getAgreementCollectionData(bytes32 _id) external view returns (string name, address author, uint8 collectionType, bytes32 packageId) {
		(name, author, collectionType, packageId) = ActiveAgreementRegistryDb(database).getCollectionData(_id);
	}

	/**
	 * @dev Gets number of agreements in given collection
	 * @param _id id of the collection
	 * @return size agreement count
	 */
	function getNumberOfAgreementsInCollection(bytes32 _id) external view returns (uint size) {
		return ActiveAgreementRegistryDb(database).getNumberOfAgreementsInCollection(_id);
	}

	/**
	 * @dev Gets agreement address at index in colelction
	 * @param _id id of the collection
	 * @param _index uint index
	 * @return agreement address of archetype
	 */
	function getAgreementAtIndexInCollection(bytes32 _id, uint _index) external view returns (address agreement) {
		return ActiveAgreementRegistryDb(database).getAgreementAtIndexInCollection(_id, _index);
	}

	/**
	 * @dev Get agreement data by collection id and agreement address
	 * Currently unused parameters were unnamed to avoid compiler warnings:
	 * param _id id of the collection
	 * @param _agreement address of agreement
	 * @return agreementName name of agreement
	 * @return archetype address of archetype
	 */
	function getAgreementDataInCollection(bytes32 /*_id*/, address _agreement) external view returns (string agreementName, address archetype) {
		agreementName = DefaultActiveAgreement(_agreement).getName();
		archetype = DefaultActiveAgreement(_agreement).getArchetype();
	}

	/**
	 * @dev Returns the number governing agreements for given agreement
	 * @return the number of governing agreements
	 */
	function getNumberOfGoverningAgreements(address _agreement) external view returns (uint size) {
		return ActiveAgreement(_agreement).getNumberOfGoverningAgreements();
	}

	/**
	 * @dev Retrieves the address for the governing agreement at the specified index
	 * @param _agreement the address of the agreement
	 * @param _index the index position
	 * @return the address for the governing agreement
	 */
	function getGoverningAgreementAtIndex(address _agreement, uint _index) external view returns (address governingAgreement) {
		return ActiveAgreement(_agreement).getGoverningAgreementAtIndex(_index);
	}

	/**
	 * @dev Returns information about the governing agreement with the specified address
	 * @param _agreement the agreement address
	 * @param _governingAgreement the governing agreement address
	 * @return the name of the governing agreement
	 */
	function getGoverningAgreementData(address _agreement, address _governingAgreement) external view returns (string name) {
		return ActiveAgreement(_agreement).getGoverningAgreementData(_governingAgreement);
	}

	/**
	 * @dev Overwrites AbstractEventListener function to receive state updates from ActiveAgreements that are registered in this registry.
	 * Currently supports AGREEMENT_STATE_CHANGED
	 */
	function eventFired(bytes32 _event, address /*_source*/) external pre_OnlyByRegisteredAgreements {
		if (_event == ActiveAgreement(msg.sender).EVENT_ID_STATE_CHANGED()) {
			// CANCELED and DEFAULT trigger aborting any running processes for this agreement
			if (ActiveAgreement(msg.sender).getLegalState() == uint8(Agreements.LegalState.CANCELED) ||
				ActiveAgreement(msg.sender).getLegalState() == uint8(Agreements.LegalState.DEFAULT)) {
					if (ActiveAgreementRegistryDb(database).getAgreementFormationProcess(msg.sender) != 0x0) {
						ProcessInstance(ActiveAgreementRegistryDb(database).getAgreementFormationProcess(msg.sender)).abort();
					}
					if (ActiveAgreementRegistryDb(database).getAgreementExecutionProcess(msg.sender) != 0x0) {
						ProcessInstance(ActiveAgreementRegistryDb(database).getAgreementExecutionProcess(msg.sender)).abort();
					}
			}
		}
	}

	/**
	 * Implements the listener function which updates agreements linked to the given process instance
	 * @param _processInstance the process instance whose state has changed
	 */
	function processStateChanged(ProcessInstance _processInstance) external {
		if (_processInstance.getState() == uint8(BpmRuntime.ProcessInstanceState.COMPLETED)) {
			address agreementAddress = _processInstance.getDataValueAsAddress(DATA_ID_AGREEMENT);
			// check if this is an agreement managed in this registry
			if (!ActiveAgreementRegistryDb(database).agreementIsRegistered(agreementAddress)) {
				return;
			}
			ActiveAgreement agreement = ActiveAgreement(agreementAddress);

			// FORMATION PROCESS
			// the agreement must be in legal state EXECUTED to trigger the execution process
			if (_processInstance.getProcessDefinition() == Archetype(agreement.getArchetype()).getFormationProcessDefinition() &&
				agreement.getLegalState() == uint8(Agreements.LegalState.EXECUTED)) {
				// if the archetype has an execution process defined, start it
				if (Archetype(agreement.getArchetype()).getExecutionProcessDefinition() != address(0)) {
					ProcessInstance newPi = createExecutionProcess(agreement);
					// keep track of the execution process for the agreement
					// NOTE: we're currently not checking if there is already a tracked execution process, because no execution path can currently lead to that situation
					ActiveAgreementRegistryDb(database).setAgreementExecutionProcess(address(agreement), address(newPi));
					bpmService.startProcessInstance(newPi); // Note: Disregarding the error code here. If there was an error in the execution process, it should either REVERT or leave the PI in INTERRUPTED state
				}
			}
			// EXECUTION PROCESS
			// the agreement must NOT be in legal states DEFAULT or CANCELED in order to be regarded as FULFILLED
			else if (_processInstance.getProcessDefinition() == Archetype(agreement.getArchetype()).getExecutionProcessDefinition() &&
					 agreement.getLegalState() != uint8(Agreements.LegalState.DEFAULT) &&
					 agreement.getLegalState() != uint8(Agreements.LegalState.CANCELED)) {
				agreement.setFulfilled();
			}
		}
	}

	/**
	 * @dev Updates the file reference for the event log of the specified agreement
	 * @param _activeAgreement Address of active agreement
	 * @param _eventLogFileReference the file reference of the event log of this agreement
	 */
	 function setEventLogReference(address _activeAgreement, string _eventLogFileReference) external {
		ActiveAgreement(_activeAgreement).setEventLogReference(_eventLogFileReference);
	 }

	/**
	 * @dev Overwrites the Upgradeable.upgrade(address) function to remove this contract as a contract change listener.
	 */
    function upgrade(address _successor) public returns (bool success) {
        success = super.upgrade(_successor);
        if (success && address(locator) != address(0)) {
            locator.removeContractChangeListener(serviceIdArchetypeRegistry);
            locator.removeContractChangeListener(serviceIdBpmService);
        }
    }

}
