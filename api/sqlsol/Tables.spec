[
  {
    "TableName": "AGREEMENTS",
    "Filter": "Log1Text = 'AN://agreements'",
    "Columns": {
      "agreementAddress": {
        "name": "agreement_address",
        "type": "address",
        "primary": true
      },
      "archetypeAddress": {
        "name": "archetype_address",
        "type": "address"
      },
      "name": {
        "name": "name",
        "type": "string"
      },
      "creator": {
        "name": "creator",
        "type": "address"
      },
      "isPrivate": {
        "name": "is_private",
        "type": "bool"
      },
      "legalState": {
        "name": "legal_state",
        "type": "uint8"
      },
      "maxEventCount": {
        "name": "max_event_count",
        "type": "uint32"
      },
      "formationProcessInstance": {
        "name": "formation_process_instance",
        "type": "address"
      },
      "executionProcessInstance": {
        "name": "execution_process_instance",
        "type": "address"
      },
      "privateParametersFileReference": {
        "name": "private_parameters_file_reference",
        "type": "string"
      },
      "eventLogFileReference": {
        "name": "event_log_file_reference",
        "type": "string"
      }
    }
  },
  {
    "TableName": "AGREEMENT_COLLECTIONS",
    "Filter": "Log1Text = 'AN://agreement-collections'",
    "Columns": {
      "collectionId": {
        "name": "collection_id",
        "type": "bytes32",
        "primary": true
      },
      "name": {
        "name": "name",
        "type": "string"
      },
      "author": {
        "name": "author",
        "type": "address"
      },
      "collectionType": {
        "name": "collection_type",
        "type": "uint8"
      },
      "packageId": {
        "name": "package_id",
        "type": "bytes32"
      }
    }
  },
  {
    "TableName": "AGREEMENT_TO_PARTY",
    "Filter": "Log1Text = 'AN://agreement-to-party'",
    "Columns": {
      "agreementAddress": {
        "name": "agreement_address",
        "type": "address",
        "primary": true
      },
      "party": {
        "name": "party",
        "type": "address",
        "primary": true
      },
      "signedBy": {
        "name": "signed_by",
        "type": "address"
      },
      "signatureTimestamp": {
        "name": "signature_timestamp",
        "type": "uint"
      }
    }
  },
  {
    "TableName": "AGREEMENT_TO_COLLECTION",
    "Filter": "Log1Text = 'AN://agreement-to-collection'",
    "Columns": {
      "collectionId": {
        "name": "collection_id",
        "type": "bytes32",
        "primary": true
      },
      "agreementAddress": {
        "name": "agreement_address",
        "type": "address",
        "primary": true
      },
      "agreementName": {
        "name": "agreement_name",
        "type": "string"
      },
      "archetypeAddress": {
        "name": "archetype_address",
        "type": "address"
      }
    }
  },
  {
    "TableName": "GOVERNING_AGREEMENTS",
    "Filter": "Log1Text = 'AN://governing-agreements'",
    "Columns": {
      "agreementAddress": {
        "name": "agreement_address",
        "type": "address",
        "primary": true
      },
      "governingAgreementAddress": {
        "name": "governing_agreement_address",
        "type": "address",
        "primary": true
      },
      "governingAgreementName": {
        "name": "governing_agreement_name",
        "type": "string"
      }
    }
  },
  {
    "TableName": "AGREEMENT_ADDRESS_SCOPES",
    "Filter": "Log1Text = 'AN://agreements/scopes'",
    "Columns": {
      "agreementAddress": {
        "name": "agreement_address",
        "type": "address",
        "primary": true
      },
      "scopeAddress": {
        "name": "scope_address",
        "type": "address"
      },
      "scopeContext": {
        "name": "scope_context",
        "type": "bytes32",
        "bytesToString": true
      },
      "fixedScope": {
        "name": "fixed_scope",
        "type": "bytes32"
      },
      "dataPath": {
        "name": "data_path",
        "type": "bytes32",
        "bytesToString": true
      },
      "dataStorageId": {
        "name": "data_storage_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "dataStorage": {
        "name": "data_storage",
        "type": "address"
      }
    }
  },
  {
    "TableName": "ARCHETYPES",
    "Filter": "Log1Text = 'AN://archetypes'",
    "Columns": {
      "archetypeAddress": {
        "name": "archetype_address",
        "type": "address",
        "primary": true
      },
      "name": {
        "name": "name",
        "type": "string"
      },
      "description": {
        "name": "description",
        "type": "string"
      },
      "price": {
        "name": "price",
        "type": "uint32"
      },
      "author": {
        "name": "author",
        "type": "address"
      },
      "active": {
        "name": "active",
        "type": "bool"
      },
      "isPrivate": {
        "name": "is_private",
        "type": "bool"
      },
      "successor": {
        "name": "successor",
        "type": "address"
      },
      "formationProcessDefinition": {
        "name": "formation_process_Definition",
        "type": "address"
      },
      "executionProcessDefinition": {
        "name": "execution_process_Definition",
        "type": "address"
      }
    }
  },
  {
    "TableName": "ARCHETYPE_PACKAGES",
    "Filter": "Log1Text = 'AN://archetype-packages'",
    "Columns": {
      "packageId": {
        "name": "package_id",
        "type": "bytes32",
        "primary": true
      },
      "name": {
        "name": "name",
        "type": "string"
      },
      "description": {
        "name": "description",
        "type": "string"
      },
      "author": {
        "name": "author",
        "type": "address"
      },
      "isPrivate": {
        "name": "is_private",
        "type": "bool"
      },
      "active": {
        "name": "active",
        "type": "bool"
      }
    }
  },
  {
    "TableName": "ARCHETYPE_TO_PACKAGE",
    "Filter": "Log1Text = 'AN://archetype-to-package'",
    "Columns": {
      "packageId": {
        "name": "package_id",
        "type": "bytes32",
        "primary": true
      },
      "archetypeAddress": {
        "name": "archetype_address",
        "type": "address",
        "primary": true
      },
      "archetypeName": {
        "name": "archetype_name",
        "type": "string"
      }
    }
  },
  {
    "TableName": "ARCHETYPE_PARAMETERS",
    "Filter": "Log1Text = 'AN://archetype/parameters'",
    "Columns": {
      "archetypeAddress": {
        "name": "archetype_address",
        "type": "address",
        "primary": true
      },
      "parameterName": {
        "name": "parameter_name",
        "type": "bytes32",
        "primary": true,
        "bytesToString": true
      },
      "parameterType": {
        "name": "parameter_type",
        "type": "uint8"
      },
      "position": {
        "name": "position",
        "type": "uint256"
      }
    }
  },
  {
    "TableName": "ARCHETYPE_DOCUMENTS",
    "Filter": "Log1Text = 'AN://archetype/documents'",
    "Columns": {
      "archetypeAddress": {
        "name": "archetype_address",
        "type": "address",
        "primary": true
      },
      "documentKey": {
        "name": "document_key",
        "type": "string",
        "primary": true
      },
      "documentReference": {
        "name": "document_reference",
        "type": "string"
      }
    }
  },
  {
    "TableName": "ARCHETYPE_JURISDICTIONS",
    "Filter": "Log1Text = 'AN://archetype/jurisdictions'",
    "Columns": {
      "archetypeAddress": {
        "name": "archetype_address",
        "type": "address",
        "primary": true
      },
      "country": {
        "name": "country",
        "type": "bytes2",
        "primary": true,
        "bytesToString": true
      },
      "region": {
        "name": "region",
        "type": "bytes32",
        "primary": true
      }
    }
  },
  {
    "TableName": "GOVERNING_ARCHETYPES",
    "Filter": "Log1Text = 'AN://governing-archetypes'",
    "Columns": {
      "archetypeAddress": {
        "name": "archetype_address",
        "type": "address",
        "primary": true
      },
      "governingArchetypeAddress": {
        "name": "governing_archetype_address",
        "type": "address",
        "primary": true
      },
      "governingArchetypeName": {
        "name": "governing_archetype_name",
        "type": "string"
      }
    }
  },
  {
    "TableName": "ACTIVITY_INSTANCES",
    "Filter": "Log1Text = 'AN://activity-instances'",
    "Columns": {
      "activityInstanceId": {
        "name": "activity_instance_id",
        "type": "bytes32",
        "primary": true
      },
      "activityId": {
        "name": "activity_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "processInstanceAddress": {
        "name": "process_instance_address",
        "type": "address"
      },
      "created": {
        "name": "created",
        "type": "uint"
      },
      "completed": {
        "name": "completed",
        "type": "uint"
      },
      "performer": {
        "name": "performer",
        "type": "address"
      },
      "completedBy": {
        "name": "completed_by",
        "type": "address"
      },
      "state": {
        "name": "state",
        "type": "uint8"
      }
    }
  },
  {
    "TableName": "PROCESS_INSTANCES",
    "Filter": "Log1Text = 'AN://process-instances'",
    "Columns": {
      "processInstanceAddress": {
        "name": "process_instance_address",
        "type": "address",
        "primary": true
      },
      "processDefinitionAddress": {
        "name": "process_definition_address",
        "type": "address"
      },
      "state": {
        "name": "state",
        "type": "uint8"
      },
      "startedBy": {
        "name": "started_by",
        "type": "address"
      }
    }
  },
  {
    "TableName": "ACTIVITY_DEFINITIONS",
    "Filter": "Log1Text = 'AN://activity-definitions'",
    "Columns": {
      "activityId": {
        "name": "activity_id",
        "type": "bytes32",
        "primary": true,
        "bytesToString": true
      },
      "modelAddress": {
        "name": "model_address",
        "type": "address",
        "primary": true
      },
      "processDefinitionAddress": {
        "name": "process_definition_address",
        "type": "address",
        "primary": true
      },
      "activityType": {
        "name": "activity_type",
        "type": "uint8"
      },
      "taskType": {
        "name": "task_type",
        "type": "uint8"
      },
      "taskBehavior": {
        "name": "task_behavior",
        "type": "uint8"
      },
      "participantId": {
        "name": "participant_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "multiInstance": {
        "name": "multi_instance",
        "type": "bool"
      },
      "application": {
        "name": "application",
        "type": "bytes32",
        "bytesToString": true
      },
      "subProcessModelId": {
        "name": "sub_process_model_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "subProcessPefinitionId": {
        "name": "sub_process_definition_id",
        "type": "bytes32",
        "bytesToString": true
      }
    }
  },
  {
    "TableName": "PROCESS_DEFINITIONS",
    "Filter": "Log1Text = 'AN://process-definitions'",
    "Columns": {
      "processDefinitionAddress": {
        "name": "process_definition_address",
        "type": "address",
        "primary": true
      },
      "id": {
        "name": "id",
        "type": "bytes32",
        "bytesToString": true
      },
      "interfaceId": {
        "name": "interface_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "modelId": {
        "name": "model_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "modelAddress": {
        "name": "model_address",
        "type": "address"
      }
    }
  },
  {
    "TableName": "PROCESS_MODELS",
    "Filter": "Log1Text = 'AN://process-models'",
    "Columns": {
      "modelAddress": {
        "name": "model_address",
        "type": "address",
        "primary": true
      },
      "id": {
        "name": "id",
        "type": "bytes32",
        "bytesToString": true
      },
      "name": {
        "name": "name",
        "type": "string"
      },
      "versionMajor": {
        "name": "version_major",
        "type": "uint"
      },
      "versionMinor": {
        "name": "version_minor",
        "type": "uint"
      },
      "versionPatch": {
        "name": "version_patch",
        "type": "uint"
      },
      "author": {
        "name": "author",
        "type": "address"
      },
      "isPrivate": {
        "name": "is_private",
        "type": "bool"
      },
      "active": {
        "name": "active",
        "type": "bool"
      },
      "modelFileReference": {
        "name": "model_file_reference",
        "type": "string"
      }
    }
  },
  {
    "TableName": "PROCESS_MODEL_DATA",
    "Filter": "Log1Text = 'AN://process-model-data'",
    "Columns": {
      "dataId": {
        "name": "data_id",
        "type": "bytes32",
        "bytesToString": true,
        "primary": true
      },
      "dataPath": {
        "name": "data_path",
        "type": "bytes32",
        "bytesToString": true,
        "primary": true
      },
      "modelAddress": {
        "name": "model_address",
        "type": "address",
        "primary": true
      },
      "parameterType": {
        "name": "parameter_type",
        "type": "uint"
      }
    }
  },
  {
    "TableName": "DATA_MAPPINGS",
    "Filter": "Log1Text = 'AN://data-mappings'",
    "Columns": {
      "processDefinitionAddress": {
        "name": "process_definition_address",
        "type": "address",
        "primary": true
      },
      "activityId": {
        "name": "activity_id",
        "type": "bytes32",
        "bytesToString": true,
        "primary": true
      },
      "dataMappingId": {
        "name": "data_mapping_id",
        "type": "bytes32",
        "bytesToString": true,
        "primary": true
      },
      "dataPath": {
        "name": "data_path",
        "type": "bytes32",
        "bytesToString": true
      },
      "dataStorageId": {
        "name": "data_storage_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "dataStorage": {
        "name": "data_storage",
        "type": "address"
      },
      "direction": {
        "name": "direction",
        "type": "uint",
        "primary": true
      }
    }
  },
  {
    "TableName": "APPLICATIONS",
    "Filter": "Log1Text = 'AN://applications'",
    "Columns": {
      "applicationId": {
        "name": "application_id",
        "type": "bytes32",
        "primary": true,
        "bytesToString": true
      },
      "applicationType": {
        "name": "application_type",
        "type": "uint8"
      },
      "location": {
        "name": "location",
        "type": "address"
      },
      "method": {
        "name": "method",
        "type": "bytes4"
      },
      "webForm": {
        "name": "web_form",
        "type": "bytes32",
        "bytesToString": true
      }
    }
  },
  {
    "TableName": "APPLICATION_ACCESS_POINTS",
    "Filter": "Log1Text = 'AN://applications/access-points'",
    "Columns": {
      "applicationId": {
        "name": "application_id",
        "type": "bytes32",
        "primary": true,
        "bytesToString": true
      },
      "accessPointId": {
        "name": "access_point_id",
        "type": "bytes32",
        "primary": true,
        "bytesToString": true
      },
      "dataType": {
        "name": "data_type",
        "type": "uint8"
      },
      "direction": {
        "name": "direction",
        "type": "uint8"
      }
    }
  },
  {
    "TableName": "DATA_STORAGE",
    "Filter": "Log1Text = 'AN://data-storage'",
    "Columns": {
      "storageAddress": {
        "name": "storage_address",
        "type": "address",
        "primary": true
      },
      "dataId": {
        "name": "data_id",
        "type": "bytes32",
        "primary": true,
        "bytesToString": true
      },
      "boolValue": {
        "name": "bool_value",
        "type": "bool"
      },
      "uintValue": {
        "name": "uint_value",
        "type": "uint"
      },
      "intValue": {
        "name": "int_value",
        "type": "int"
      },
      "bytes32Value": {
        "name": "bytes32_value",
        "type": "bytes32",
        "bytesToString": true
      },
      "addressValue": {
        "name": "address_value",
        "type": "address"
      },
      "stringValue": {
        "name": "string_value",
        "type": "string"
      }
    }
  },
  {
    "TableName": "PROCESS_INSTANCE_ADDRESS_SCOPES",
    "Filter": "Log1Text = 'AN://process-instances/scopes'",
    "Columns": {
      "processInstanceAddress": {
        "name": "process_instance_address",
        "type": "address",
        "primary": true
      },
      "scopeAddress": {
        "name": "scope_address",
        "type": "address"
      },
      "scopeContext": {
        "name": "scope_context",
        "type": "bytes32",
        "bytesToString": true
      },
      "fixedScope": {
        "name": "fixed_scope",
        "type": "bytes32"
      },
      "dataPath": {
        "name": "data_path",
        "type": "bytes32",
        "bytesToString": true
      },
      "dataStorageId": {
        "name": "data_storage_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "dataStorage": {
        "name": "data_storage",
        "type": "address"
      }
    }
  },
  {
    "TableName": "COUNTRIES",
    "Filter": "Log1Text = 'AN://standards/countries'",
    "Columns": {
      "name": {
        "name": "name",
        "type": "string",
        "primary": true
      },
      "alpha2": {
        "name": "alpha2",
        "type": "bytes2",
        "bytesToString": true
      },
      "alpha3": {
        "name": "alpha3",
        "type": "bytes3",
        "bytesToString": true
      },
      "m49": {
        "name": "m49",
        "type": "bytes3",
        "bytesToString": true
      }
    }
  },
  {
    "TableName": "REGIONS",
    "Filter": "Log1Text = 'AN://standards/regions'",
    "Columns": {
      "country": {
        "name": "country",
        "type": "bytes2",
        "primary": true,
        "bytesToString": true
      },
      "region": {
        "name": "region",
        "type": "bytes32",
        "primary": true
      },
      "code2": {
        "name": "code2",
        "type": "bytes2",
        "bytesToString": true
      },
      "code3": {
        "name": "code3",
        "type": "bytes3",
        "bytesToString": true
      },
      "name": {
        "name": "name",
        "type": "string"
      }
    }
  },
  {
    "TableName": "CURRENCIES",
    "Filter": "Log1Text = 'AN://standards/currencies'",
    "Columns": {
      "alpha3": {
        "name": "alpha3",
        "type": "bytes3",
        "primary": true,
        "bytesToString": true
      },
      "m49": {
        "name": "m49",
        "type": "bytes3",
        "bytesToString": true
      },
      "name": {
        "name": "name",
        "type": "string"
      }
    }
  },
  {
    "TableName": "PARAMETER_TYPES",
    "Filter": "Log1Text = 'AN://parameter-types'",
    "Columns": {
      "parameterType": {
        "name": "parameter_type",
        "type": "uint",
        "primary": true
      },
      "label": {
        "name": "label",
        "type": "string"
      }
    }
  },
  {
    "TableName": "USER_ACCOUNTS",
    "Filter": "Log1Text = 'AN://user-accounts'",
    "Columns": {
      "userAccountAddress": {
        "name": "user_account_address",
        "type": "address",
        "primary": true
      },
      "owner": {
        "name": "owner",
        "type": "address"
      }
    }
  },
  {
    "TableName": "ORGANIZATION_ACCOUNTS",
    "Filter": "Log1Text = 'AN://organization-accounts'",
    "Columns": {
      "organizationAddress": {
        "name": "organization_address",
        "type": "address",
        "primary": true
      },
      "approverCount": {
        "name": "approver_count",
        "type": "uint"
      },
      "organizationId": {
        "name": "organization_id",
        "type": "bytes32"
      }
    }
  },
  {
    "TableName": "ORGANIZATION_APPROVERS",
    "Filter": "Log1Text = 'AN://organizations/approvers'",
    "Columns": {
      "organizationAddress": {
        "name": "organization_address",
        "type": "address",
        "primary": true
      },
      "approverAddress": {
        "name": "approver_address",
        "type": "address",
        "primary": true
      }
    }
  },
  {
    "TableName": "ORGANIZATION_USERS",
    "Filter": "Log1Text = 'AN://organizations/users'",
    "DeleteFilter": "CRUD_ACTION = 'delete'",
    "Columns": {
      "organizationaddress": {
        "name": "organization_address",
        "type": "address",
        "primary": true
      },
      "userAddress": {
        "name": "user_address",
        "type": "address",
        "primary": true
      }
    }
  },
  {
    "TableName": "ORGANIZATION_DEPARTMENTS",
    "Filter": "Log1Text = 'AN://organizations/departments'",
    "DeleteFilter": "CRUD_ACTION = 'delete'",
    "Columns": {
      "organizationAddress": {
        "name": "organization_address",
        "type": "address",
        "primary": true
      },
      "departmentId": {
        "name": "department_id",
        "type": "bytes32",
        "bytesToString": true,
        "primary": true
      },
      "userCount": {
        "name": "user_count",
        "type": "uint"
      },
      "name": {
        "name": "name",
        "type": "string"
      }
    }
  },
  {
    "TableName": "DEPARTMENT_USERS",
    "Filter": "Log1Text = 'AN://departments/users'",
    "DeleteFilter": "CRUD_ACTION = 'delete'",
    "Columns": {
      "organizationAddress": {
        "name": "organization_address",
        "type": "address",
        "primary": true
      },
      "departmentId": {
        "name": "department_id",
        "type": "bytes32",
        "bytesToString": true,
        "primary": true
      },
      "userAddress": {
        "name": "user_address",
        "type": "address",
        "primary": true
      }
    }
  },
  {
    "TableName": "MEAN_TEMPERATURES",
    "Filter": "Log1Text = 'AN://oracles/wolfram/mean-temp'",
    "Columns": {
      "uuid": {
        "name": "uuid",
        "type": "bytes32",
        "primary": true
      },
      "location": {
        "name": "location",
        "type": "string"
      },
      "mean_temperature_start": {
        "name": "mean_temperature_start",
        "type": "uint"
      },
      "mean_temperature_end": {
        "name": "mean_temperature_end",
        "type": "uint"
      },
      "result_temperature": {
        "name": "result_temperature",
        "type": "string"
      }
    }
  }
]