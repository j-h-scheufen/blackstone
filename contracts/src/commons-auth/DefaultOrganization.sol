pragma solidity ^0.4.25;

import "commons-base/ErrorsLib.sol";
import "commons-utils/ArrayUtilsAPI.sol";
import "commons-standards/AbstractERC165.sol";
import "commons-management/AbstractDelegateTarget.sol";

import "commons-auth/Governance.sol";
import "commons-auth/Organization.sol";
import "commons-auth/UserAccount.sol";

/**
 * @title DefaultOrganization
 * @dev the default implementation of the Organization interface.
 */
contract DefaultOrganization is Organization, AbstractDelegateTarget, AbstractERC165 {
	
	using MappingsLib for Mappings.AddressBoolMap;
	using ArrayUtilsAPI for address[];

	Governance.Organization self;

	// The approvers list is intended to be used as a "board" or admin permission list to make changes to this organization
	address[] approvers;
	Mappings.AddressBoolMap users;
	string public defaultDepartmentName = "Default";

	/**
	 * @dev Modifier to guard functions only accessible by one of the approvers.
	 * REVERTS if:
	 * - msg.sender is not a registered approver
	 */
	modifier pre_onlyByApprovers() {
		ErrorsLib.revertIf(!approvers.contains(msg.sender),
			ErrorsLib.UNAUTHORIZED(), "DefaultOrganization.pre_onlyByApprovers", "msg.sender ist not a recognized approver of this organization");
		_;
	}

	/**
	 * @dev Initializes this DefaultOrganization with the provided list of initial approvers. This function replaces the
	 * contract constructor, so it can be used as the delegate target for an ObjectProxy.
	 * If the approvers list is empty, the msg.sender is registered as an approver for this Organization.
	 * Also, a default department is automatically created which cannot be removed as it serves as the catch-all
	 * for authorizations that cannot otherwise be matched with existing departments.
	 * REVERTS if:
	 * - the contract had already been initialized before
	 * @param _initialApprovers an array of addresses that should be registered as approvers for this Organization
	 * @param _defaultDepartmentName an optional custom name/label for the default department of this organization.
	 */
	function initialize(address[] _initialApprovers, string _defaultDepartmentName)
		external
		pre_post_initialize
	{
		// if no _initialApprovers were passed, register msg.sender as an approver
		if (_initialApprovers.length == 0) {
			approvers.push(msg.sender);
		}
		else {
			approvers = _initialApprovers;
		}
		// creating the default department
		if (bytes(_defaultDepartmentName).length > 0) {
			defaultDepartmentName = _defaultDepartmentName;
		}
		addDepartment(DEFAULT_DEPARTMENT_ID, defaultDepartmentName);
		addInterfaceSupport(ERC165_ID_Organization);
		emit LogOrganizationCreation(
			EVENT_ID_ORGANIZATION_ACCOUNTS,
			address(this),
			approvers.length,
			getOrganizationKey()
		);
        for (uint i=0; i<approvers.length; i++) {
            emit LogOrganizationApproverUpdate(
                EVENT_ID_ORGANIZATION_APPROVERS,
                address(this),
                approvers[i]
            );
        }
	}

	/**
	 * @dev Adds the department with the specified ID and name to this Organization.
	 * @param _id the department ID (must be unique)
	 * @param _name the name/label for the department
	 * @return true if the department was added successfully, false otherwise (e.g. if the ID already exists)
	 */
	function addDepartment(bytes32 _id, string _name) public returns (bool) {
		if (self.departments[_id].exists) {
			return false;
		}
		self.departments[_id].keyIdx = self.departmentKeys.push(_id)-1;
		self.departments[_id].id = _id;
		self.departments[_id].name = _name;
		self.departments[_id].exists = true;
		emit LogOrganizationDepartmentUpdate(
			EVENT_ID_ORGANIZATION_DEPARTMENTS,
			address(this),
			_id,
			self.departments[_id].users.keys.length,
			self.departments[_id].name
		);
		return true;
	}

	/**
	 * @dev Removes the department with the specified ID, if it exists and is not the DEFAULT_DEPARTMENT_ID.
	 * @param _depId a department ID
	 * @return true if a department with that ID existed and was successfully removed, false otherwise
	 */
	function removeDepartment(bytes32 _depId) external returns (bool) {
		if (self.departments[_depId].exists && _depId != DEFAULT_DEPARTMENT_ID) {
			uint256 depKeyIdx = self.departments[_depId].keyIdx;
			bytes32 swapKey = Mappings.deleteInKeys(self.departmentKeys, depKeyIdx);
			if (swapKey != "") {
				self.departments[swapKey].keyIdx = self.departments[_depId].keyIdx;
			}
			delete self.departments[_depId];
            emit LogOrganizationDepartmentRemoval(
                EVENT_ID_ORGANIZATION_DEPARTMENTS, 
                bytes32("delete"), 
                address(this), 
                _depId
            );
			return true;
		}
		return false;
	}

	function getNumberOfDepartments() external view returns (uint size) {
		return self.departmentKeys.length;
	}

	function getDepartmentAtIndex(uint _index) external view returns (bytes32 id) {
		return self.departmentKeys[_index];
	}

	function getDepartmentData(bytes32 _id) external view returns (uint userCount, string name) {
		userCount = self.departments[_id].users.keys.length;
		name = self.departments[_id].name;
	}

	function getDepartmentName(bytes32 _id) external view returns (string name) {
		name = self.departments[_id].name;
	}

	function departmentExists(bytes32 _id) external view returns (bool) {
		return self.departments[_id].exists;
	}

	/**
	 * @dev Returns the number of registered approvers.
	 * @return the number of approvers
	 */
	function getNumberOfApprovers() external view returns (uint) {
		return approvers.length;
	}
	
	/**
	 * @dev Returns the approver's address at the given index position.
	 * @param _pos the index position
	 * @return the address or 0x0 if the position does not exist
	 */
	function getApproverAtIndex(uint _pos) external view returns (address) {
		if (_pos < approvers.length) {
			return approvers[_pos];
		}
		return 0x0;
	}

	/**
	 * @dev returns the number of users associated with this organization
	 * @return the number of users
	 */
	function getNumberOfUsers() external view returns (uint) {
		return users.keys.length;
	}

	/**
	 * @dev Returns the user's address at the given index position.
	 * @param _pos the index position
	 * @return the address or 0x0 if the position does not exist
	 */
	function getUserAtIndex(uint _pos) external view returns (address) {
		if (_pos < users.keys.length) {
			(, address userAccount) = users.keyAtIndex(_pos);
			return userAccount;
		}
		return 0x0;
	}

	function getNumberOfDepartmentUsers(bytes32 _depId) external view returns (uint size) {
		size = self.departments[_depId].users.keys.length;
	}

	function getDepartmentUserAtIndex(bytes32 _depId, uint _index) external view returns (address userAccount) {
		if (_index < self.departments[_depId].users.keys.length) {
		 	userAccount = self.departments[_depId].users.keys[_index];
		} else {
			userAccount = 0x0;
		}
	}

	/**
	 * @dev Adds the specified user to this Organization. This function guarantees that the user is part of this organization, if it returns true.
	 * @param _userAccount the user to add
	 * @return true if the user is successfully added to the organization, false otherwise (e.g. if the user account address was empty)
	 */
    function addUser(address _userAccount) public returns (bool) {
		if (_userAccount == address(0))
			return false;
		if(!users.exists(_userAccount)) {
			users.insert(_userAccount, true);
            emit LogOrganizationUserUpdate(
                EVENT_ID_ORGANIZATION_USERS,
                address(this),
				_userAccount
            );
		}
		return true;
	}

	/**
	 * @dev Removes the user from this Organization and all departments they were in.
	 * @param _userAccount the account to remove
	 * @return bool true if user is removed successfully
	 */
	function removeUser(address _userAccount) external returns (bool) {
		for (uint i = 0; i < self.departmentKeys.length; i++) {
			bytes32 depId = self.departmentKeys[i];
			removeUserFromDepartment(_userAccount, depId);
		}
		if (users.exists(_userAccount)) {
			users.remove(_userAccount);
            emit LogOrganizationUserRemoval(
                EVENT_ID_ORGANIZATION_USERS,
                bytes32("delete"),
                address(this),
				_userAccount
            );
			return true;
		}
		return false;
	}

	/**
	 * @dev Adds the specified user to the organization if they aren't already registered, then adds the user to the department if they aren't already in it.
	 * An empty department ID will result in the user being added to the default department.
	 * This function guarantees that the user is both a member of the organization as well as the specified department, if it returns true.
	 * @param _userAccount the user to add
	 * @param _department department id to which the user should be added
	 * @return true if successfully added, false otherwise (e.g. if the department does not exist or if the user account address is empty)
	 */
	function addUserToDepartment(address _userAccount, bytes32 _department) external returns (bool) {
		bytes32 targetDepartment = (_department == "") ? DEFAULT_DEPARTMENT_ID : _department;
		if (!self.departments[targetDepartment].exists || _userAccount == address(0)) {
			return false;
		}
		addUser(_userAccount);
		if (!self.departments[targetDepartment].users.exists(_userAccount)) {
			self.departments[targetDepartment].users.insert(_userAccount, true);
			emit LogDepartmentUserUpdate(
                EVENT_ID_DEPARTMENT_USERS,
                address(this),
				targetDepartment,
				_userAccount
            );
		}
		return true;
	}

	/**
	 * @dev Removes the user from the department in this organization
	 * @param _userAccount the user to remove
	 * @param _depId the department to remove the user from
	 * @return bool indicating success or failure
	 */
	function removeUserFromDepartment(address _userAccount, bytes32 _depId) public returns (bool) {
		if (self.departments[_depId].users.exists(_userAccount)) {
			self.departments[_depId].users.remove(_userAccount);
            emit LogDepartmentUserRemoval(
				EVENT_ID_DEPARTMENT_USERS,
				bytes32("delete"),
				address(this),
				_depId,
				_userAccount);
			return true;
		}
		return false;
	}

	/**
	 * @dev Returns whether the given user account is authorized within this Organization.
	 * The optional department/role identifier can be used to provide an additional authorization scope
	 * against which to authorize the user. The following special cases exist:
	 * 1. If the provided department matches the keccak256 hash of the address of this organization, the user
	 * is regarded as authorized, if belonging to this organization (without having to be associated with a
	 * 2. If the department is empty or if it is an unknown (non-existent) department, the user will be evaluated
	 * against the DEFAULT department.
	 * particular department).
	 * @param _userAccount the user account
	 * @param _department an optional department/role context
	 * @return true if authorized, false otherwise
	 */
	function authorizeUser(address _userAccount, bytes32 _department) external view returns (bool) {
		if (_department == getOrganizationKey()) {
			return users.exists(_userAccount);
		}
		else if (_department == "" || !self.departments[_department].exists) {
			return self.departments[DEFAULT_DEPARTMENT_ID].users.exists(_userAccount);
		}
		else {
			return self.departments[_department].users.exists(_userAccount);
		}			
	}

  function getOrganizationKey() public view returns (bytes32) {
    return keccak256(abi.encodePacked(address(this)));
  }

  function getOrganizationDetails() external view returns (uint numberOfApprovers, bytes32 organizationKey) {
    organizationKey = getOrganizationKey();
    numberOfApprovers = approvers.length;
  }
}
