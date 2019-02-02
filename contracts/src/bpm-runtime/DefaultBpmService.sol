pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";
import "commons-auth/ParticipantsManager.sol";
import "commons-auth/Ecosystem.sol";
import "commons-base/BaseErrors.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/ContractLocatorEnabled.sol";
import "bpm-model/ProcessModelRepository.sol";
import "bpm-model/ProcessDefinition.sol";
import "bpm-model/ProcessModel.sol";

import "bpm-runtime/BpmRuntime.sol";
import "bpm-runtime/BpmRuntimeLib.sol";
import "bpm-runtime/BpmService.sol";
import "bpm-runtime/BpmServiceDb.sol";
import "bpm-runtime/ProcessInstance.sol";
import "bpm-runtime/DefaultProcessInstance.sol";

/**
 * @title DefaultBpmService
 * @dev Default implementation of the BpmService interface.
 */
contract DefaultBpmService is Versioned(1,0,0), AbstractDbUpgradeable, ContractLocatorEnabled, BpmService {

    using BpmRuntimeLib for ProcessInstance;

    //TODO these string should not be hardcoded. Inject via constructor after AN-307 fixed
    string constant serviceIdProcessModelRepository = "ProcessModelRepository";
    string constant serviceIdApplicationRegistry = "ApplicationRegistry";

    ProcessModelRepository modelRepository;
    ApplicationRegistry applicationRegistry;

	/**
	 * @dev Creates a new ProcessInstance based on the specified ProcessDefinition and starts its execution
	 * @param _processDefinition the address of a ProcessDefinition
     * @param _activityInstanceId the ID of a subprocess activity instance that initiated this ProcessInstance (optional)
     * @return any error resulting from ProcessInstance.execute() or BaseErrors.NO_ERROR(), if successful
     * @return the address of a ProcessInstance, if successful
	 */
    function startProcess(address _processDefinition, bytes32 _activityInstanceId)
        public
        returns (uint error, address)
    {
        ProcessInstance pi = createDefaultProcessInstance(_processDefinition, msg.sender, _activityInstanceId);
        error = startProcessInstance(pi);
        return (error, pi);
    }

    /**
	 * @dev Creates a new ProcessInstance based on the specified IDs of a ProcessModel and ProcessDefinition and starts its execution
     * @param _modelId the model that qualifies the process ID, if multiple models are deployed, otherwise optional
     * @param _processDefinitionId the ID of the process definition
     * @param _activityInstanceId the ID of a subprocess activity instance that initiated this ProcessInstance (optional)
     * REVERTS if:
     * - a ProcessDefinition cannot be located in the ProcessModelRepository
     * @return any error resulting from ProcessInstance.execute() or ProcessBaseErrors.NO_ERROR(), if successful
     * @return the address of a ProcessInstance, if successful
     * //TODO this function should be called startProcess(bytes32, bytes32), but our JS libs have a problem with polymorphism: AN-301
     */
    function startProcessFromRepository(bytes32 _modelId, bytes32 _processDefinitionId, bytes32 _activityInstanceId)
        public
        returns (uint error, address)
    {
        address pd = modelRepository.getProcessDefinition(_modelId, _processDefinitionId);
        ErrorsLib.revertIf(pd == 0x0,
            ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultBpmService.startProcessFromRepository", "Unable to find a ProcessDefinition for the given ID");
        return startProcess(pd, _activityInstanceId);
    }

    /**
     * @dev Initializes, registers, and executes a given ProcessInstance
     * @param _pi the ProcessInstance
     * @return BaseErrors.NO_ERROR() if successful or an error code from executing the ProcessInstance
     */
    function startProcessInstance(ProcessInstance _pi)
        public
        returns (uint error)
    {
        _pi.initRuntime();
        BpmServiceDb(database).addProcessInstance(_pi);
        error = _pi.execute(this);
    }

	/**
	 * @dev Creates a new ProcessInstance initiated with the provided parameters. This ProcessInstance can be further customized and then
	 * submitted to the #startProcessInstance(ProcessInstance) function for execution. The ownership of the created ProcessInstance
     * is transfered to the msg.sender, i.e. the caller of this function will be the owner of the ProcessInstance.
     * REVERTS if:
     * - the provided ProcessDefinition is NULL
	 * @param _processDefinition the address of a ProcessDefinition
	 * @param _startedBy the address of an account that regarded as the starting user. If empty, the msg.sender is used.
     * @param _activityInstanceId the ID of a subprocess activity instance that initiated this ProcessInstance (optional)
	 */
    function createDefaultProcessInstance(address _processDefinition, address _startedBy, bytes32 _activityInstanceId)
        public
        returns (ProcessInstance processInstance)
    {
        ErrorsLib.revertIf(_processDefinition == 0x0,
            ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "DefaultBpmService.createDefaultProcessInstance", "ProcessDefinition is NULL");
        processInstance = new DefaultProcessInstance(ProcessDefinition(_processDefinition), (_startedBy == 0x0) ? msg.sender : _startedBy, _activityInstanceId);
        processInstance.transferOwnership(msg.sender);
        ErrorsLib.revertIf(address(processInstance) == 0x0,
                ErrorsLib.INVALID_STATE(), "DefaultBpmService.createDefaultProcessInstance", "Process Instance address empty");
    }

    /**
     * @dev Overrides ContractLocatorEnabled.setContractLocator(address).
     * Performs a lookup of dependencies for a ProcessModelRepository and an ApplicationRegistry.
     * REVERTS if:
     * - if any of the dependencies cannot be satisfied.
     * @param _locator the ContractLocator to use
     */
    function setContractLocator(address _locator)
        public
    {
        super.setContractLocator(_locator);
        modelRepository = ProcessModelRepository(ContractLocator(_locator).getContract(serviceIdProcessModelRepository));
        applicationRegistry = ApplicationRegistry(ContractLocator(_locator).getContract(serviceIdApplicationRegistry));
        ErrorsLib.revertIf(address(modelRepository) == 0x0,
			ErrorsLib.DEPENDENCY_NOT_FOUND(), "DefaultBpmService.setContractLocator", "ModelRepository not found");
        ErrorsLib.revertIf(address(applicationRegistry) == 0x0,
			ErrorsLib.DEPENDENCY_NOT_FOUND(), "DefaultBpmService.setContractLocator", "ApplicationRegistry not found");
        ContractLocator(_locator).addContractChangeListener(serviceIdProcessModelRepository);
        ContractLocator(_locator).addContractChangeListener(serviceIdApplicationRegistry);
    }

    /**
     * @dev Implements ContractChangeListener.contractChanged(string,address) to update this contract's dependencies.
     */
    function contractChanged(string _name, address, address _newAddress)
        external
        pre_onlyByLocator
    {
        if (keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(serviceIdProcessModelRepository))){
            modelRepository = ProcessModelRepository(_newAddress);
        }
        else if (keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(serviceIdApplicationRegistry))){
            applicationRegistry = ApplicationRegistry(_newAddress);
        }
    }

	/**
	 * @dev Returns the number of process instances.
	 * @return the process instance count as size
	 */
    function getNumberOfProcessInstances() external view returns (uint size) {
        return BpmServiceDb(database).getNumberOfProcessInstances();
    }

    /**
	 * @dev Returns the process instance address at the specified index
	 * @param _pos the index
	 * @return the process instance address or BaseErrors.INDEX_OUT_OF_BOUNDS(), 0x0
	 */
    function getProcessInstanceAtIndex(uint _pos) external view returns (address processInstanceAddress) {
        return BpmServiceDb(database).getProcessInstanceAtIndex(_pos);
    }

	/**
	 * @dev Returns information about the process intance with the specified address
	 * @param _address the process instance address
	 * @return processDefinition the address of the ProcessDefinition
	 * @return state the BpmRuntime.ProcessInstanceState as uint8
	 * @return startedBy the address of the account who started the process
	 */
    function getProcessInstanceData(address _address) external view returns (address processDefinition, uint8 state, address startedBy) {
        ProcessInstance pi = ProcessInstance(_address);
        processDefinition = pi.getProcessDefinition();
        state = pi.getState();
        startedBy = pi.getStartedBy();
    }

    /**
     * @dev Returns the number of activity instances.
     * @return the activity instance count as size
     */
    function getNumberOfActivityInstances(address _address) external view returns (uint size) {
        return ProcessInstance(_address).getNumberOfActivityInstances();
    }

    /**
	 * @dev Returns the ActivityInstance ID at the specified index
	 * @param _address the process instance address
	 * @param _pos the activity instance index
	 * @return the ActivityInstance ID
	 */
    function getActivityInstanceAtIndex(address _address, uint _pos) external view returns (bytes32 activityId) {
        activityId = ProcessInstance(_address).getActivityInstanceAtIndex(_pos);
    }

    /**
	 * @dev Returns ActivityInstance data for given the ActivityInstance ID
     * @param _processInstance the process instance address to which the ActivityInstance belongs
	 * @param _id the global ID of the activity instance
	 * @return activityId - the ID of the activity as defined by the process definition
	 * @return created - the creation timestamp
	 * @return completed - the completion timestamp
	 * @return performer - the account who is performing the activity (for interactive activities only)
	 * @return completedBy - the account who completed the activity (for interactive activities only) 
	 * @return state - the uint8 representation of the BpmRuntime.ActivityInstanceState of this activity instance
	 */
    function getActivityInstanceData(address _processInstance, bytes32 _id)
        external view
        returns (
            bytes32 activityId, 
            uint created,
            uint completed,
            address performer,
            address completedBy,
            uint8 state)
    {        
        (activityId, created, completed, performer, completedBy, state) = ProcessInstance(_processInstance).getActivityInstanceData(_id);
    }

    /**
	 * @dev Returns the number of process data entries.
	 * @return the process data size
	 */
    function getNumberOfProcessData(address _address) external view returns (uint size) {
        size = ProcessInstance(_address).getNumberOfData();
    }

    /**
	 * @dev Returns the process data ID at the specified index
	 * @param _pos the index
	 * @return the data ID
	 */
    function getProcessDataAtIndex(address _address, uint _pos) external view returns (bytes32 dataId) {
        uint error;
        (error, dataId) = ProcessInstance(_address).getDataIdAtIndex(_pos);
    }

    /**
	 * @dev Returns information about the process data entry for the specified process and data ID
	 * @param _address the process instance
	 * @param _dataId the data ID
	 * @return (process,id,uintValue,bytes32Value,addressValue,boolValue)
	 */
    function getProcessDataDetails(address _address, bytes32 _dataId)
        external view
        returns (
            uint uintValue,
            int intValue,
            bytes32 bytes32Value,
            address addressValue,
            bool boolValue)
    {
        uintValue = ProcessInstance(_address).getDataValueAsUint(_dataId);
        intValue = ProcessInstance(_address).getDataValueAsInt(_dataId);
        bytes32Value = ProcessInstance(_address).getDataValueAsBytes32(_dataId);
        addressValue = ProcessInstance(_address).getDataValueAsAddress(_dataId);
        boolValue = ProcessInstance(_address).getDataValueAsBool(_dataId);
    }

	/**
	 * @dev Returns the number of address scopes for the given ProcessInstance.
	 * @param _processInstance the address of a ProcessInstance
	 * @return the number of scopes
	 */
	function getNumberOfAddressScopes(address _processInstance) external view returns (uint size) {
        size = ProcessInstance(_processInstance).getAddressScopeKeys().length;
    }

	/**
	 * @dev Returns the address scope key at the given index position of the specified ProcessInstance.
	 * @param _processInstance the address of a ProcessInstance
	 * @param _index the index position
	 * @return the bytes32 scope key
	 */
	function getAddressScopeKeyAtIndex(address _processInstance, uint _index) external view returns (bytes32) {
        return ProcessInstance(_processInstance).getAddressScopeKeys()[_index];
    }

	/**
	 * @dev Returns detailed information about the address scope with the given key in the specified ProcessInstance
	 * @param _processInstance the address of a ProcessInstance
	 * @param _key a scope key
	 * @return keyAddress - the address encoded in the key
	 * @return keyContext - the context encoded in the key
	 * @return fixedScope - a bytes32 representing a fixed scope
	 * @return dataPath - the dataPath of a ConditionalData defining the scope
	 * @return dataStorageId - the dataStorageId of a ConditionalData defining the scope
	 * @return dataStorage - the dataStorgage address of a ConditionalData defining the scope
	 */
	function getAddressScopeDetails(address _processInstance, bytes32 _key)
		external view
		returns (address keyAddress,
				 bytes32 keyContext,
				 bytes32 fixedScope,
				 bytes32 dataPath,
				 bytes32 dataStorageId,
				 address dataStorage)
    {
        return ProcessInstance(_processInstance).getAddressScopeDetailsForKey(_key);
    }

    /**
     * @dev Returns the address of the ProcessInstance of the specified ActivityInstance ID
     * @param _aiId the ID of an ActivityInstance
     * @return the ProcessInstance address or 0x0 if it cannot be found
     */
    function getProcessInstanceForActivity(bytes32 _aiId) external view returns (address) {
        return BpmServiceDb(database).getProcessInstanceForActivity(_aiId);
    }

	/**
	 * @dev Returns a reference to the BpmServiceDb currently used by this BpmService
	 * @return the BpmServiceDb
	 */
    function getBpmServiceDb() external view returns (BpmServiceDb) {
        return BpmServiceDb(database);
    }

    /**
     * @dev Gets the ProcessModelRepository address for this BpmService
     * @return the ProcessModelRepository
     */
    function getProcessModelRepository() external view returns (ProcessModelRepository) {
        return modelRepository;
    }

	/**
	 * @dev Returns a reference to the ApplicationRegistry currently used by this BpmService
	 * @return the ApplicationRegistry
	 */
    function getApplicationRegistry() external view returns (ApplicationRegistry) {
        return applicationRegistry;
    }

	/**
	 * @dev Overwrites the Upgradeable.upgrade(address) function to remove this contract as a contract change listener.
	 */
    function upgrade(address _successor) public returns (bool success) {
        success = super.upgrade(_successor);
        if (success && address(locator) != address(0)) {
            locator.removeContractChangeListener(serviceIdApplicationRegistry);
            locator.removeContractChangeListener(serviceIdProcessModelRepository);
        }
    }

}