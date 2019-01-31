pragma solidity ^0.4.25;

import "commons-base/BaseErrors.sol";
import "commons-utils/ArrayUtilsAPI.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";
import "commons-management/AbstractDbUpgradeable.sol";

import "bpm-model/ProcessModel.sol";
import "bpm-model/BpmModel.sol";
import "bpm-model/DefaultProcessModel.sol";
import "bpm-model/ProcessModelRepository.sol";
import "bpm-model/ProcessModelRepositoryDb.sol";

/**
 * @title DefaultProcessModelRepository
 * @dev Default implementation of the ProcessModelRepository interface
 */
contract DefaultProcessModelRepository is Versioned(1,1,0), ProcessModelRepository, AbstractDbUpgradeable {
	
	/**
	 * @dev Modifier to only allow calls to this ProcessModelRepository from a registered ProcessModel
	 */
	modifier onlyRegisteredModels() {
		if (!ProcessModelRepositoryDb(database).modelIsRegistered(msg.sender)) return;
		_;
	}
	
	/**
	 * @dev Factory function to instantiate a ProcessModel. The model is automatically added to this repository.
	 * @param _id the model ID
	 * @param _name the model name
	 * @param _version the model version
	 * @param _author the model author
	 * @param _isPrivate indicates if the model is private
	 * @param _modelFileReference the reference to the external model file from which this ProcessModel originated
	 */
	function createProcessModel(bytes32 _id, string _name, uint8[3] _version, address _author, bool _isPrivate, string _modelFileReference) external returns (uint error, address modelAddress) {
		ProcessModel pm = new DefaultProcessModel(_id, _name, _version, _author, _isPrivate, _modelFileReference);
		error = addModel(pm);
		if (error != BaseErrors.NO_ERROR()) //TODO this should revert the model creation if it could not be added
			return (error, 0x0);
		modelAddress = address(pm);
	}

	/**
	 * @dev Adds the given ProcessModel to this repository.
	 * @param _model the ProcessModel to add
	 * @return BaseErrors.RESOURCE_ALREADY_EXISTS() if a model with the same ID and version already exists
	 * @return BaseErrors.NO_ERROR() when added successfully
	 */
	function addModel(ProcessModel _model) public returns (uint error) {
		error = ProcessModelRepositoryDb(database).addModel(_model.getId(), _model.getVersion(), _model);
		if ( error != BaseErrors.NO_ERROR()) return;
		emit LogProcessModelCreation(
			EVENT_ID_PROCESS_MODELS,
			address(_model),
			_model.getId(),
			_model.getName(),
			_model.major(),
			_model.minor(),
			_model.patch(),
			_model.getAuthor(),
			_model.isPrivate(),
			ProcessModelRepositoryDb(database).getActiveModel(_model.getId()) == address(_model),
			_model.getModelFileReference()
		);
		// if there is no active model for this ID namespace, yet, then this one becomes the active one by default
		if (!ProcessModelRepositoryDb(database).modelIsActive(_model.getId())) {
			ProcessModelRepositoryDb(database).registerActiveModel(_model.getId(), _model);
		}
	}

	/**
	 * @dev Activates the given ProcessModel and deactivates any previously activated model version of the same ID
	 * @param _model the ProcessModel to activate.
	 * REVERTS if:
	 * - the given ProcessModel ID and version are not registered in this ProcessModelRepository
	 * - there is a registered model with the same ID and version, but the address differs from the given ProcessModel
	 * - 
	 */
	function activateModel(ProcessModel _model) external returns (uint error) {
		// check if there is an address registered for the model ID and version
		address addr = ProcessModelRepositoryDb(database).getModel(_model.getId(), _model.getVersion());
		ErrorsLib.revertIf(addr == 0x0,
			ErrorsLib.RESOURCE_NOT_FOUND(), "DefaultProcessModelRepository.activateModel", "No registered model found that matches the model ID and version");
		ErrorsLib.revertIf(addr != address(_model),
			ErrorsLib.INVALID_INPUT(), "DefaultProcessModelRepository.activateModel", "Another ProcessModel address is already registered with the same model ID and version");
		// re-use the addr field to lookup a previously activated model with the same ID
		addr = ProcessModelRepositoryDb(database).getActiveModel(_model.getId());
		ProcessModelRepositoryDb(database).registerActiveModel(_model.getId(), _model);
		emit LogProcessModelActivation(EVENT_ID_PROCESS_MODELS, address(_model), true);
		if (addr != 0x0 && addr != address(_model)) {
			// previously activated model detected that should be updated
			emit LogProcessModelActivation(EVENT_ID_PROCESS_MODELS, address(addr), false);
		}
		return BaseErrors.NO_ERROR();
	}

	/**
	 * @dev Returns the address of the activated model with the given ID
	 * @param _id the model ID
	 * @return the model address, if it exists and has an active version
	 */
	function getModel(bytes32 _id) external view returns (address) {
		return ProcessModelRepositoryDb(database).getActiveModel(_id);
	}

	/**
	 * @dev Returns the address of the model with the given ID and version
	 * @param _id the model ID
	 * @param _version the model version
	 * @return the model address, if found
	 */	
	function getModelByVersion(bytes32 _id, uint8[3] _version) external view returns (uint error, address modelAddress) {
		modelAddress = ProcessModelRepositoryDb(database).getModel(_id, _version);
		error = (modelAddress == 0x0) ? BaseErrors.RESOURCE_NOT_FOUND() : BaseErrors.NO_ERROR();
	}
	
	/**
	 * @dev Returns the number of models in this repository.
	 * @return size - the number of models
	 */
	function getNumberOfModels() external view returns (uint size) {
		return ProcessModelRepositoryDb(database).getNumberOfModels();
	}

	/**
	 * @dev Returns the address of the ProcessModel at the given index position, if it exists
	 * @param _idx the index position
	 * @return the model address
	 */
	function getModelAtIndex(uint _idx) external view returns (address) {
		return ProcessModelRepositoryDb(database).getModelAtIndex(_idx);
	}

	/**
	 * @dev Returns information about the ProcessModel at the given address
	 * @param _model the ProcessModel address
	 * @return id - the model ID
	 * @return name - the model name
	 * @return versionMajor - the model's major version
	 * @return versionMinor - the model's minor version
	 * @return versionPatch - the model's patch version
	 * @return author - the model's author
	 * @return isPrivate - indicates if model is private
	 * @return active - whether the model is active
	 * @return modelFileReference - the external reference of the model file
	 */
	function getModelData(address _model) external view returns (bytes32 id, string name, uint versionMajor, uint versionMinor, uint versionPatch, address author, bool isPrivate, bool active, string modelFileReference) {
		ProcessModel m = DefaultProcessModel(_model);
		id = m.getId();
		name = m.getName();
		versionMajor = m.major();
		versionMinor = m.minor();
		versionPatch = m.patch();
		author = m.getAuthor();
		isPrivate = m.isPrivate();
		active = ProcessModelRepositoryDb(database).getActiveModel(m.getId()) == _model;
		modelFileReference = m.getModelFileReference();
	}

	/**
	 * @dev Returns the process definition address when the model ID and process definition ID are provided
	 * @param _modelId - the ProcessModel ID
	 * @return _processId - the ProcessDefinition ID
	 * @return address - the ProcessDefinition address
	 */
	function getProcessDefinition (bytes32 _modelId, bytes32 _processId) external view returns (address) {
		address modelAddress = ProcessModelRepositoryDb(database).getActiveModel(_modelId);
		if (modelAddress != 0x0) {
			return ProcessModel(modelAddress).getProcessDefinition(_processId);
		} else {
			return 0x0;
		}
	}

	/**
	 * @dev Returns the number of process definitions in the specified model
	 * @param _model a ProcessModel address
	 * @return size - the number of process definitions
	 */
	function getNumberOfProcessDefinitions(address _model) external view returns (uint size) {
		return ProcessModel(_model).getNumberOfProcessDefinitions();
	}

	/**
	 * @dev Returns the address of the ProcessDefinition at the specified index position of the given model
	 * @param _model a ProcessModel address
	 * @param _idx the index position
	 * @return the ProcessDefinition address, if it exists
	 */
	function getProcessDefinitionAtIndex(address _model, uint _idx) external view returns (address) {
		return ProcessModel(_model).getProcessDefinitionAtIndex(_idx);
	}

	/**
	 * @dev Returns data about the specified ProcessDefinition in the specified ProcessModel
	 * @param _model a ProcessModel address
	 * @param _processDefinition a ProcessDefinition address
	 * @return id - the ProcessDefinition ID
	 * @return interfaceId - the ProcessDefinition's first interface ID
	 * @return modelId the id of the model to which this process definition belongs
	 */
	function getProcessDefinitionData(address _model, address _processDefinition) external view returns (bytes32 id, bytes32 interfaceId, bytes32 modelId) {
		return ProcessModel(_model).getProcessDefinitionData(_processDefinition);
	}

	/**
	 * @dev Returns the number of Activity Definitions in the specified Process Definition
	 * The first param "address" is the model address. It's not named explicitly to avoid compiler warnings due to it not being used.
	 * @param _processDefinition a Process Definition address
	 * @return uint - the number of Activity Definitions
	 */
	function getNumberOfActivities (address, address _processDefinition) external view returns (uint size) {
		return ProcessDefinition(_processDefinition).getNumberOfActivities();
	}

	/**
	 * @dev Returns the ID of the ActivityDefinition at the specified index position of the given Process Definition
	 * The first param "address" is the model address. It's not named explicitly to avoid compiler warnings due to it not being used.
	 * @param _processDefinition a Process Definition address
	 * @param _index the index position
	 * @return bytes32 the ActivityDefinition ID, if it exists
	 */
	function getActivityAtIndex(address, address _processDefinition, uint _index) external view returns (bytes32) {
		return ProcessDefinition(_processDefinition).getActivityAtIndex(_index);
	}

	/**
	 * @dev Returns information about the activity definition with the given ID.
	 * The first param "address" is the model address. It's not named explicitly to avoid compiler warnings due to it not being used.
	 * @param _processDefinition a Process Definition address
	 * @param _id the bytes32 id of the activity definition
	 * @return activityType the BpmModel.ActivityType as uint8
	 * @return taskType the BpmModel.TaskType as uint8
	 * @return taskBehavior the BpmModel.TaskBehavior as uint8
	 * @return assignee the ID of the activity's assignee (for interactive activities)
	 * @return multiInstance whether the activity is a multi-instance
	 * @return application the activity's application
	 * @return subProcessModelId the ID of a process model (for subprocess activities)
	 * @return subProcessDefinitionId the ID of a process definition (for subprocess activities)
	 */
	function getActivityData(address, address _processDefinition, bytes32 _id) external view returns (uint8 activityType, uint8 taskType, uint8 taskBehavior, bytes32 assignee, bool multiInstance, bytes32 application, bytes32 subProcessModelId, bytes32 subProcessDefinitionId) {
		return ProcessDefinition(_processDefinition).getActivityData(_id);
	}

}