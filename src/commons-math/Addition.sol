pragma solidity ^0.5.12;

import "bpm-runtime/Application.sol";
import "bpm-runtime/ProcessInstance.sol";

contract Addition is Application {

    /**
     * @dev Reads the IN-data mapping ID "First Number" from the BpmService, and the IN-data mapping ID "Second Number, adds them, and stores it back via an OUT-data mapping.
     * @param _piAddress the address of the ProcessInstance
     * @param _activityInstanceId the ID of an ActivityInstance
     * param _activityId the ID of the activity definition
     * param _txPerformer the address which started the process transaction
     */
    function complete(address _piAddress, bytes32 _activityInstanceId, bytes32, address) public {
        uint firstNum = ProcessInstance(_piAddress).getActivityInDataAsUint(_activityInstanceId, "numberInOne");
        uint secondNum = ProcessInstance(_piAddress).getActivityInDataAsUint(_activityInstanceId, "numberInTwo");
        ProcessInstance(_piAddress).setActivityOutDataAsUint(_activityInstanceId, "numberOut", firstNum+secondNum); // TODO needs SafeMath lib
    }

}
