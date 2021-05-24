import { Client, TxExecution } from '@hyperledger/burrow';
import { getLogger, Logger } from 'log4js';
import { ActiveAgreement } from '../agreements/ActiveAgreement.abi';
import { ActiveAgreementRegistry } from '../agreements/ActiveAgreementRegistry.abi';
import { Archetype } from '../agreements/Archetype.abi';
import { RenewalWindowManager } from '../agreements/RenewalWindowManager.abi';
import { ProcessDefinition } from '../bpm-model/ProcessDefinition.abi';
import { ProcessModel } from '../bpm-model/ProcessModel.abi';
import { BpmService } from '../bpm-runtime/BpmService.abi';
import { ProcessInstance } from '../bpm-runtime/ProcessInstance.abi';
import { Ecosystem_v1_0_1 as Ecosystem } from '../commons-auth/Ecosystem_v1_0_1.abi';
import { Organization } from '../commons-auth/Organization.abi';
import { Direction, ErrorCode } from './constants';
import { Manager, NewManager } from './manager';
import { Agreement as agreement, Archetype as archetype, DataType, Parameter } from './types';
import {
  bytesFromString,
  bytesToString,
  callOnBehalfOf,
  decodeHex,
  getFromNameRegistry,
  setInNameRegistry,
} from './utils';
import { BurrowWatcher, VentListener } from './vent';

export async function RegisterEcosystem(
  client: Client,
  manager: Manager,
  account: string,
  name: string,
): Promise<string> {
  const address = await manager.EcosystemRegistry.createEcosystem(name).then((data) => data[0]);
  await Ecosystem.contract(client, address).functions.addExternalAddress(account);
  await setInNameRegistry(client, name, address);
  return address;
}

export class Contracts {
  client: Client;
  manager: Manager;
  account: string;
  ecosystem: string;
  log: Logger;

  constructor(client: Client, manager: Manager, ecosystem: string) {
    this.client = client;
    this.account = client.account;
    this.manager = manager;
    this.ecosystem = ecosystem;
    this.log = getLogger('contracts');
  }

  async getFromNameRegistry(name: string): Promise<string | void> {
    this.log.debug(`REQUEST: Get from name registry: ${name}`);
    return getFromNameRegistry(this.client, name);
  }

  async setToNameRegistry(name: string, value: string): Promise<void> {
    this.log.debug(`REQUEST: Set to name registry: ${JSON.stringify({ name, value })}`);
    return setInNameRegistry(this.client, name, value);
  }

  async createAgreement(agreement: agreement): Promise<string> {
    const { archetype, creator, owner, privateParametersFileReference, parties, collectionId, governingAgreements } =
      agreement;
    const isPrivate = agreement.isPrivate || false;
    this.log.debug(`REQUEST: Create agreement with following data: ${JSON.stringify(agreement)}`);
    return this.manager.ActiveAgreementRegistry.createAgreement(
      archetype,
      creator,
      owner,
      privateParametersFileReference,
      isPrivate,
      parties,
      decodeHex(collectionId),
      governingAgreements,
    ).then((data) => {
      this.log.info(`SUCCESS: Created agreement by ${creator} at address ${data.activeAgreement}`);
      return data.activeAgreement;
    });
  }

  async setLegalState(agreementAddress: string, legalState: number): Promise<void> {
    this.log.debug(`REQUEST: Set legal state of agreement ${agreementAddress} to ${legalState}`);
    const agreement = ActiveAgreement.contract(this.client, agreementAddress).functions;
    const permissionId = await agreement.ROLE_ID_LEGAL_STATE_CONTROLLER().then((data) => data[0]);
    const hasPermission = (await agreement.hasPermission(permissionId, this.account))[0];
    if (!hasPermission) {
      await agreement.grantPermission(permissionId, this.account);
    }
    await agreement.setLegalState(legalState);
    await agreement.revokePermission(permissionId, this.account);
  }

  async initializeObjectAdministrator(agreementAddress: string): Promise<void> {
    this.log.debug(`REQUEST: Initializing agreement admin role for agreement: ${agreementAddress}`);
    const agreement = ActiveAgreement.contract(this.client, agreementAddress).functions;
    await agreement.initializeObjectAdministrator(this.account);
    this.log.info(`SUCCESS: Initialized agreement admin role for agreement ${agreementAddress}`);
  }

  async setMaxNumberOfAttachments(agreementAddress: string, maxNumberOfAttachments: number): Promise<void> {
    this.log.debug(
      `REQUEST: Set max number of events to ${maxNumberOfAttachments} for agreement at ${agreementAddress}`,
    );
    const agreement = ActiveAgreement.contract(this.client, agreementAddress).functions;
    await agreement.setMaxNumberOfEvents(maxNumberOfAttachments);
  }

  async setAddressScopeForAgreementParameters(
    agreementAddress: string,
    parameters: Array<{ name: string; value: string; scope: string }>,
  ) {
    this.log.debug(`REQUEST: Add scopes to agreement ${agreementAddress} parameters: ${JSON.stringify(parameters)}`);
    const agreement = ActiveAgreement.contract(this.client, agreementAddress).functions;

    const promises = parameters.map(async ({ name, value, scope }) => {
      return agreement.setAddressScope(
        value,
        bytesFromString(name),
        decodeHex(scope),
        bytesFromString(''),
        bytesFromString(''),
        '0x0',
      );
    });
    await Promise.all(promises);
    this.log.info(`SUCCESS: Added scopes to agreement ${agreementAddress} parameters`);
  }

  async updateAgreementFileReference(fileKey: string, agreementAddress: string, hoardGrant: string): Promise<void> {
    this.log.debug(
      `REQUEST: Update reference for  ${fileKey} for agreement at ${agreementAddress} with new reference ${hoardGrant}`,
    );
    const agreement = ActiveAgreement.contract(this.client, agreementAddress).functions;
    switch (fileKey) {
      case 'EventLog':
        await agreement.setEventLogReference(hoardGrant);
        break;
      case 'SignatureLog':
        await agreement.setSignatureLogReference(hoardGrant);
        break;
      case 'PrivateParameters':
        await agreement.setPrivateParametersReference(hoardGrant);
        break;
    }
  }

  async defineRenewalTerms(
    agreementAddress: string,
    franchisees: string[],
    threshold: number,
    renewalOpenOffset: string,
    renewalCloseOffset: string,
    extensionOffset: string,
  ): Promise<void> {
    this.log.debug(`REQUEST: Defining agreement renewal obligation  for agreement at ${agreementAddress} with data 
            ${JSON.stringify({
              franchisees,
              threshold,
              renewalOpenOffset,
              renewalCloseOffset,
              extensionOffset,
            })}`);
    const agreement = ActiveAgreement.contract(this.client, agreementAddress).functions;
    await agreement.defineRenewalTerms(franchisees, threshold, renewalOpenOffset, renewalCloseOffset, extensionOffset);
  }

  async createAgreementCollection(author: string, collectionType: number, packageId: string): Promise<Buffer> {
    this.log.debug(
      `REQUEST: Create agreement collection by ${author} with type ${collectionType} ` +
        `and packageId ${packageId} created by user at ${author}`,
    );
    return this.manager.ActiveAgreementRegistry.createAgreementCollection(
      author,
      collectionType,
      decodeHex(packageId),
    ).then((data) => {
      if (data.error !== 1) {
        throw new Error(`Error code adding agreement collection by ${author}: ${data.error}`);
      }
      this.log.info(`SUCCESS: Created new agreement collection by ${author} with id ${data.id}`);
      return data.id;
    });
  }

  async addAgreementToCollection(collectionId: string, agreement: string): Promise<void> {
    this.log.debug(`REQUEST: Add agreement at ${agreement} to collection ${collectionId}`);
    return this.manager.ActiveAgreementRegistry.addAgreementToCollection(decodeHex(collectionId), agreement);
  }

  signAgreement(actingUserAddress: string, agreementAddress: string, partyAddress?: string): Promise<void> {
    this.log.debug(`REQUEST: Sign agreement ${agreementAddress} by user ${actingUserAddress}`);
    const agreement = ActiveAgreement.contract(this.client, agreementAddress).functions;
    const caller = callOnBehalfOf(actingUserAddress);
    return partyAddress ? agreement.signAsParty(partyAddress, caller) : agreement.sign(caller);
  }

  /**
   * Attest to a completable
   *
   * @param actingUserAddress user who is a franchisee or belongs to a franchisee party
   * @param intervalId the identity of the completable in the space of intervals
   * @param timestamp the timestamp at which to record/schedule the attestation
   * @param partyAddress the party as which the acting user would like to attest
   */
  async attestCompletable(
    actingUserAddress: string,
    intervalId: Buffer,
    timestamp: number,
    partyAddress?: string,
  ): Promise<boolean> {
    this.log.debug('REQUEST: Attest to completable %s by user %s', intervalId.toString('hex'), actingUserAddress);
    const completables = this.manager.Completables.functions;
    const caller = callOnBehalfOf(actingUserAddress);
    const { isRatified } = await (partyAddress
      ? completables.attestAsParty(intervalId, timestamp, partyAddress, caller)
      : completables.attest(intervalId, timestamp, caller));
    return isRatified;
  }

  async castRenewalVote(actingUserAddress: string, agreementAddress: string, renew: boolean): Promise<void> {
    this.log.debug(
      `REQUEST: Cast agreement renewal vote by user ${actingUserAddress} for agreement ${agreementAddress}`,
    );
    return ActiveAgreement.contract(this.client, agreementAddress).functions.castRenewalVote(
      renew,
      callOnBehalfOf(actingUserAddress),
    );
  }

  async isAgreementSignedBy(agreementAddress: string, userAddress: string): Promise<boolean> {
    this.log.debug(`REQUEST: Checking if agreement at ${agreementAddress} has been signed by user at ${userAddress}`);
    const [isSignedBy] = await ActiveAgreement.contract(this.client, agreementAddress).functions.isSignedBy(
      userAddress,
      callOnBehalfOf(userAddress),
    );
    return isSignedBy;
  }

  async cancelAgreement(actingUserAddress: string, agreementAddress: string, partyAddress?: string): Promise<void> {
    this.log.debug('REQUEST: Cancel agreement %s by user %s', agreementAddress, actingUserAddress);
    const caller = callOnBehalfOf(actingUserAddress);
    const agreement = ActiveAgreement.contract(this.client, agreementAddress).functions;
    return partyAddress ? agreement.cancelAsParty(partyAddress, caller) : agreement.cancel(caller);
  }

  async redactAgreement(actingUserAddress: string, agreementAddress: string): Promise<number> {
    this.log.debug('REQUEST: Redact agreement %s by user %s', agreementAddress, actingUserAddress);
    const [legalState] = await ActiveAgreement.contract(this.client, agreementAddress).functions.redact(
      callOnBehalfOf(actingUserAddress),
    );
    return legalState;
  }

  async getActiveAgreementData(
    agreementAddress: string,
  ): Promise<ReturnType<ActiveAgreementRegistry.Contract['functions']['getActiveAgreementData']>> {
    this.log.debug(`REQUEST: Get data for agreement at address ${agreementAddress}`);
    return this.manager.ActiveAgreementRegistry.getActiveAgreementData(agreementAddress);
  }

  getActiveAgreement(address: string) {
    return ActiveAgreement.contract(this.client, address).functions;
  }

  getRenewalWindowManager(address: string) {
    return RenewalWindowManager.contract(this.client, address).functions;
  }

  async startProcessFromAgreement(agreementAddress: string): Promise<string> {
    this.log.debug(`REQUEST: Start formation process from agreement at address: ${agreementAddress}`);
    return this.manager.ActiveAgreementRegistry.startProcessLifecycle(agreementAddress).then(async (data) => {
      if (data.error && data.error !== 1) {
        throw new Error(ErrorCode.RUNTIME_ERROR);
      }
      this.log.info(
        `SUCCESS: Formation process for agreement at ${agreementAddress} created and started at address: ${data.processInstance}`,
      );
      return data.processInstance;
    });
  }

  /**
   * @param actingUserAddress user who is a franchisee or belongs to a franchisee party
   * @param agreementAdress the agreement under which the related dates live
   * @param derivedDate the date whose value is derived from the base date
   * @param baseDate the date from which the derive date's value is derived
   * @param offset the interval from the base date to the derived date
   */
  async setDateRelation(
    actingUserAddress: string,
    agreementAdress: string,
    derivedDate: string,
    baseDate: string,
    offset: string,
  ): Promise<void> {
    this.log.debug(
      'REQUEST: Set date %s to %s from date %s on agreement %s by user %s',
      derivedDate,
      offset,
      baseDate,
      agreementAdress,
      actingUserAddress,
    );
    return this.manager.AgreementDates.functions.setRelation(
      agreementAdress,
      bytesFromString(derivedDate),
      bytesFromString(baseDate),
      offset,
      callOnBehalfOf(actingUserAddress),
    );
  }

  /**
   * @param actingUserAddress user who is a franchisee or belongs to a franchisee party
   * @param agreementAdress the agreement under which the date lives
   * @param date the identifier of the cycling date
   * @param recurred the number of times the cycle has recurred
   */
  async setDateCycle(
    actingUserAddress: string,
    agreementAddress: string,
    date: string,
    metadata: string,
    recurred: number,
  ): Promise<void> {
    this.log.debug(
      'REQUEST: Set date %s to recur with config %s on agreement %s by user %s',
      date,
      metadata,
      agreementAddress,
      actingUserAddress,
    );
    return this.manager.AgreementDates.functions.setCycle(
      agreementAddress,
      bytesFromString(date),
      metadata,
      recurred,
      callOnBehalfOf(actingUserAddress),
    );
  }

  /**
   * @param actingUserAddress user who is a franchisee or belongs to a franchisee party
   * @param agreementAddress the agreement under which the date lives
   * @param date the identifier of the cycling date
   * @param recurred the number of times the cycle has recurred
   */
  async removeDateCycle(actingUserAddress: string, agreementAddress: string, date: string): Promise<void> {
    this.log.debug(
      'REQUEST: Removing cycling of date %s on agreement %s by user %s',
      date,
      agreementAddress,
      actingUserAddress,
    );
    return this.manager.AgreementDates.functions.removeCycle(
      agreementAddress,
      bytesFromString(date),
      callOnBehalfOf(actingUserAddress),
    );
  }

  /**
   * @param actingUserAddress user who is a franchisee or belongs to a franchisee party
   * @param agreementAdress the agreement under which the date lives
   * @param date the identifier of the cycling date
   * @param recurred the number of times the cycle has recurred
   */
  async incrementDateCycleRecurrences(agreementAdress: string, date: string): Promise<number> {
    this.log.debug('REQUEST: Increment recurrences of cycling date %s on agreement %s', date, agreementAdress);
    const [recurred] = await this.manager.AgreementDates.functions.incrementRecurrences(
      agreementAdress,
      bytesFromString(date),
    );
    return recurred;
  }

  /**
   * @param actingUserAddress user who is a franchisee or belongs to a franchisee party
   * @param agreementAdress the agreement under which the date lives
   * @param date the identifier of the cycling date
   * @param metadata the number of times the cycle has metadata
   */
  async setCycleMetadata(agreementAdress: string, date: string, metadata: string): Promise<void> {
    this.log.debug('REQUEST: Set metadata %s for cycling date %s on agreement %s', metadata, date, agreementAdress);
    await this.manager.AgreementDates.functions.setCycleMetadata(agreementAdress, bytesFromString(date), metadata);
  }

  async createArchetype(archetype: archetype): Promise<string> {
    const { price, active, author, owner, formationProcess, executionProcess, packageId, governingArchetypes } =
      archetype;
    const isPrivate = archetype.isPrivate || false;
    this.log.debug(`REQUEST: Create archetype with: ${JSON.stringify(archetype)}`);
    return this.manager.ArchetypeRegistry.createArchetype(
      price,
      isPrivate,
      active,
      author,
      owner,
      formationProcess,
      executionProcess,
      decodeHex(packageId),
      governingArchetypes,
    ).then((data) => data.archetype);
  }

  async isActiveArchetype(archetypeAddress: string): Promise<boolean> {
    this.log.debug(`REQUEST: Determine if archetype at ${archetypeAddress} is active`);
    return Archetype.contract(this.client, archetypeAddress)
      .functions.isActive()
      .then((data) => {
        this.log.info(
          `SUCCESS: Archetype at ${archetypeAddress} has been found to be ${data[0] ? 'active' : 'inactive'}`,
        );
        return data[0];
      });
  }

  async getArchetypeAuthor(archetypeAddress: string): Promise<string> {
    this.log.debug(`REQUEST: Get archetype author for archetype at ${archetypeAddress}`);
    return Archetype.contract(this.client, archetypeAddress)
      .functions.getAuthor()
      .then((value) => value.author);
  }

  async activateArchetype(archetypeAddress: string, userAccount: string): Promise<void> {
    this.log.debug(`REQUEST: Activate archetype at ${archetypeAddress} by user at ${userAccount}`);
    return Archetype.contract(this.client, archetypeAddress).functions.activate(callOnBehalfOf(userAccount));
  }

  async deactivateArchetype(archetypeAddress: string, userAccount: string): Promise<void> {
    this.log.debug(`REQUEST: Deactivate archetype at ${archetypeAddress} by user at ${userAccount}`);
    await Archetype.contract(this.client, archetypeAddress).functions.deactivate(callOnBehalfOf(userAccount));
    this.log.info(`SUCCESS: Archetype at ${archetypeAddress} deactivated by user at ${userAccount}`);
  }

  async setArchetypeSuccessor(archetypeAddress: string, successorAddress: string, userAccount: string): Promise<void> {
    this.log.debug(
      `REQUEST: Set successor to ${successorAddress} for archetype at ${archetypeAddress} by user at ${userAccount}`,
    );
    return Archetype.contract(this.client, archetypeAddress).functions.setSuccessor(
      successorAddress,
      callOnBehalfOf(userAccount),
    );
  }

  async getArchetypeSuccessor(archetypeAddress: string): Promise<string> {
    this.log.debug(`REQUEST: Get successor for archetype at ${archetypeAddress}`);
    return this.manager.ArchetypeRegistry.getArchetypeSuccessor(archetypeAddress).then((data) => data[0]);
  }

  async addArchetypeParameters(address: string, parameters: Array<Parameter>): Promise<void> {
    const paramTypes: number[] = [];
    const paramNames: Buffer[] = [];
    for (let i = 0; i < parameters.length; i += 1) {
      paramTypes[i] = parameters[i].type;
      paramNames[i] = bytesFromString(parameters[i].name);
    }
    this.log.debug(
      `REQUEST: Add archetype parameters to archetype at address ${address}. ` +
        `Parameter Types: ${JSON.stringify(paramTypes)}, Parameter Names: ${JSON.stringify(
          parameters.map((item) => item.name),
        )}`,
    );
    return this.manager.ArchetypeRegistry.addParameters(address, paramTypes, paramNames).then((data) => {
      if (data.error !== 1) {
        throw new Error(`Error code adding parameter to archetype at ${address}: ${data.error}`);
      } else {
        this.log.info(`SUCCESS: Added parameters ${parameters.map(({ name }) => name)} to archetype at ${address}`);
      }
    });
  }

  async addArchetypeDocument(address: string, fileReference: string): Promise<void> {
    this.log.debug(`REQUEST: Add document to archetype at ${address}`);
    return this.manager.ArchetypeRegistry.addDocument(address, fileReference);
  }

  async addArchetypeDocuments(
    archetypeAddress: string,
    documents: Array<{ grant: string; name: string }>,
  ): Promise<void> {
    const names = documents.map((doc) => doc.name).join(', ');
    this.log.debug(`REQUEST: Add archetype documents to archetype at ${archetypeAddress}: ${names}`);
    await Promise.all(documents.map(async ({ grant }) => this.addArchetypeDocument(archetypeAddress, grant)));
  }

  async setArchetypePrice(address: string, price: number): Promise<void> {
    this.log.debug(`REQUEST: Set price to ${price} for archetype at ${address}`);
    const priceInCents = Math.floor(price * 100); // monetary unit conversion to cents which is the recorded unit on chain
    return this.manager.ArchetypeRegistry.setArchetypePrice(address, priceInCents);
  }

  async upgradeOwnerPermission(address: string, owner: string): Promise<void> {
    return Archetype.contract(this.client, address).functions.upgradeOwnerPermission(owner);
  }

  async createArchetypePackage(author: string, isPrivate: boolean, active: boolean): Promise<Buffer> {
    this.log.debug(
      `REQUEST: Create a ${isPrivate ? 'private' : 'public'}, ${
        active ? 'active' : 'inactive'
      } archetype package by user at ${author}`,
    );
    return this.manager.ArchetypeRegistry.createArchetypePackage(author, isPrivate, active).then((data) => {
      if (data.error !== 1) {
        throw new Error(ErrorCode.RUNTIME_ERROR);
      } else {
        return data.id;
      }
    });
  }

  async activateArchetypePackage(packageId: string, userAccount: string): Promise<void> {
    this.log.debug(`REQUEST: Activate archetype package with id ${packageId} by user at ${userAccount}`);
    return this.manager.ArchetypeRegistry.activatePackage(decodeHex(packageId), userAccount);
  }

  async deactivateArchetypePackage(packageId: string, userAccount: string): Promise<void> {
    this.log.debug(`REQUEST: Deactivate archetype package with id ${packageId} by user at ${userAccount}`);
    return this.manager.ArchetypeRegistry.deactivatePackage(decodeHex(packageId), userAccount);
  }

  async addArchetypeToPackage(packageId: string, archetype: string): Promise<void> {
    this.log.debug(`REQUEST: Add archetype at ${archetype} to package ${packageId}`);
    return this.manager.ArchetypeRegistry.addArchetypeToPackage(decodeHex(packageId), archetype);
  }

  async addJurisdictions(
    address: string,
    jurisdictions: Array<{ country: string; regions: Array<string> }>,
  ): Promise<{ error: number }> {
    const countries: Buffer[] = [];
    const regions: Buffer[] = [];
    jurisdictions.forEach((item) => {
      if (item.regions.length > 0) {
        item.regions.forEach((region) => {
          countries.push(bytesFromString(item.country));
          regions.push(bytesFromString(region));
        });
      } else {
        countries.push(bytesFromString(item.country));
        regions.push(bytesFromString(''));
      }
    });

    this.log.debug(
      `REQUEST: Add jurisdictions to archetype at ${address}. ` +
        `Countries: ${JSON.stringify(countries)}, Regions: ${JSON.stringify(regions)}`,
    );

    return this.manager.ArchetypeRegistry.addJurisdictions(address, countries, regions);
  }

  async getArchetypeProcesses(archAddress: string): Promise<{ formation: string; execution: string }> {
    this.log.debug(`REQUEST: Get formation and execution processes for archetype at address ${archAddress}`);
    const data = await this.manager.ArchetypeRegistry.getArchetypeData(archAddress);
    const formation = data.formationProcessDefinition;
    const execution = data.executionProcessDefinition;
    this.log.info(
      `SUCCESS: Retrieved processes for archetype ${archAddress}. Formation: ${formation}, Execution: ${execution}}`,
    );
    return {
      formation: formation,
      execution: execution,
    };
  }

  async createProcessModel(
    modelId: string,
    modelVersion: [number, number, number],
    author: string,
    isPrivate: boolean,
    modelFileReference: string,
  ): Promise<string> {
    this.log.debug(
      `REQUEST: Create process model with following data: ${JSON.stringify({
        modelId,
        modelVersion,
        author,
        isPrivate,
        modelFileReference,
      })}`,
    );
    return this.manager.ProcessModelRepository.createProcessModel(
      bytesFromString(modelId),
      modelVersion,
      author,
      isPrivate,
      modelFileReference,
    ).then((value) => value.modelAddress);
  }

  async addDataDefinitionToModel(
    pmAddress: string,
    dataStoreField: {
      dataStorageId: string;
      dataPath: string;
      parameterType: number;
    },
  ) {
    this.log.debug(`REQUEST: Add data definition ${JSON.stringify(dataStoreField)} to process model ${pmAddress}`);
    await ProcessModel.contract(this.client, pmAddress).functions.addDataDefinition(
      bytesFromString(dataStoreField.dataStorageId),
      bytesFromString(dataStoreField.dataPath),
      dataStoreField.parameterType,
    );
    this.log.info(`SUCCESS: Data definition ${JSON.stringify(dataStoreField)} added to Process Model at ${pmAddress}`);
    return dataStoreField;
  }

  async addProcessInterface(pmAddress: string, interfaceId: string): Promise<void> {
    this.log.debug(`REQUEST: Add process interface ${interfaceId} to process model at ${pmAddress}`);
    return ProcessModel.contract(this.client, pmAddress)
      .functions.addProcessInterface(bytesFromString(interfaceId))
      .then((data) => {
        // interfaceId already registered to model
        if (data.error === 1002) {
          return;
        } else if (data.error !== 1) {
          throw new Error(
            `Error code while adding process interface ${interfaceId} to model at ${pmAddress}: ${data[0]}`,
          );
        }
        this.log.info(`SUCCESS: Interface ${interfaceId} added to Process Model at ${pmAddress}`);
      });
  }

  async addParticipant(
    pmAddress: string,
    participantId: string,
    accountAddress: string,
    dataPath: string,
    dataStorageId: string,
    dataStorageAddress: string,
  ) {
    this.log.debug(
      `REQUEST: Add participant ${participantId} to process model at ${pmAddress} with data: ${JSON.stringify({
        accountAddress,
        dataPath,
        dataStorageId,
        dataStorageAddress,
      })}`,
    );
    await ProcessModel.contract(this.client, pmAddress)
      .functions.addParticipant(
        bytesFromString(participantId),
        accountAddress,
        bytesFromString(dataPath),
        bytesFromString(dataStorageId),
        dataStorageAddress,
      )
      .then((data) => {
        if (data.error !== 1) {
          throw new Error(`Error code while adding participant ${participantId} to model ${pmAddress}: ${data[0]}`);
        }
        this.log.info(`SUCCESS: Participant ${participantId} added to model ${pmAddress}`);
      });
  }

  async createProcessDefinition(modelAddress: string, processDefnId: string): Promise<string> {
    this.log.debug(`REQUEST: Create process definition with Id ${processDefnId} for process model ${modelAddress}`);
    return this.manager.ProcessModelRepository.createProcessDefinition(
      modelAddress,
      bytesFromString(processDefnId),
    ).then((value) => value.newAddress);
  }

  async addProcessInterfaceImplementation(pmAddress: string, pdAddress: string, interfaceId: string): Promise<void> {
    this.log.debug(
      `REQUEST: Add process interface implementation ${interfaceId} to process definition ${pdAddress} for process model ${pmAddress}`,
    );
    await ProcessDefinition.contract(this.client, pdAddress)
      .functions.addProcessInterfaceImplementation(pmAddress, bytesFromString(interfaceId))
      .then((data) => {
        if (data.error === 1001) {
          throw new Error(
            `InterfaceId ${interfaceId} for process at ${pdAddress} is not registered to the model at ${pmAddress}`,
          );
        } else if (data.error !== 1) {
          throw new Error(
            `Error code while adding process interface implementation ${interfaceId} to process at ${pdAddress}: ${data[0]}`,
          );
        }
        this.log.info(`SUCCESS: Interface implementation ${interfaceId} added to Process Definition at ${pdAddress}`);
      });
  }

  async createActivityDefinition(
    processAddress: string,
    activityId: string,
    activityType: number,
    taskType: number,
    behavior: number,
    assignee: string,
    multiInstance: boolean,
    application: string,
    subProcessModelId: string,
    subProcessDefinitionId: string,
  ) {
    this.log.debug(
      `REQUEST: Create activity definition with data: ${JSON.stringify({
        processAddress,
        activityId,
        activityType,
        taskType,
        behavior,
        assignee,
        multiInstance,
        application,
        subProcessModelId,
        subProcessDefinitionId,
      })}`,
    );

    await ProcessDefinition.contract(this.client, processAddress)
      .functions.createActivityDefinition(
        bytesFromString(activityId),
        activityType,
        taskType,
        behavior,
        bytesFromString(assignee),
        multiInstance,
        bytesFromString(application),
        bytesFromString(subProcessModelId),
        bytesFromString(subProcessDefinitionId),
      )
      .then((data) => {
        if (data.error !== 1) {
          throw new Error(ErrorCode.RUNTIME_ERROR);
        }
        this.log.info(`SUCCESS: Activity definition ${activityId} created in process at ${processAddress}`);
      });
  }

  async createIntermediateEvent(
    processAddress: string,
    eventId: string,
    eventType: number,
    eventBehavior: number,
    dataPath: string,
    dataStorageId: string,
    dataStorage: string,
    timestampConstant: number,
    durationConstant: string,
  ) {
    this.log.debug(
      `REQUEST: Create intermediate event with data: ${JSON.stringify({
        processAddress,
        eventId,
        eventType,
        eventBehavior,
        dataPath,
        dataStorageId,
        dataStorage,
        timestampConstant,
        durationConstant,
      })}`,
    );

    try {
      await ProcessDefinition.contract(this.client, processAddress).functions.createIntermediateEvent(
        bytesFromString(eventId),
        eventType,
        eventBehavior,
        bytesFromString(dataPath),
        bytesFromString(dataStorageId),
        dataStorage,
        timestampConstant,
        durationConstant,
      );
    } catch (err) {
      this.log.error(`Failed to create intermediate event: ${err.stack} \n ${err.message}`);
    }
  }

  async setIntermediateEventDatetimeAndOffset(
    processAddress: string,
    eventId: string,
    datetimeDataPath: string,
    datetimeDataStorageId: string,
    datetimeDataStorage: string,
    offsetDataPath: string,
    offsetDataStorageId: string,
    offsetDataStorage: string,
  ) {
    this.log.debug(
      `REQUEST: Set intermediate event datetime and offset with data: ${JSON.stringify({
        processAddress,
        eventId,
        datetimeDataPath,
        datetimeDataStorageId,
        datetimeDataStorage,
        offsetDataPath,
        offsetDataStorageId,
        offsetDataStorage,
      })}`,
    );

    await ProcessDefinition.contract(this.client, processAddress).functions.setIntermediateEventDatetimeAndOffset(
      bytesFromString(eventId),
      bytesFromString(datetimeDataPath),
      bytesFromString(datetimeDataStorageId),
      datetimeDataStorage,
      bytesFromString(offsetDataPath),
      bytesFromString(offsetDataStorageId),
      offsetDataStorage,
    );
  }

  async setIntermediateEventTimerTarget(piAddress: string, eventInstanceId: string, targetTime: number): Promise<void> {
    this.log.debug(
      `REQUEST: Setting intermediate timer target with data: ${JSON.stringify({
        piAddress,
        eventInstanceId,
        targetTime,
      })}`,
    );

    await ProcessInstance.contract(this.client, piAddress).functions.setIntermediateEventTimerTarget(
      decodeHex(eventInstanceId),
      targetTime,
    );
  }

  async getIntermediateEventTimerTarget(piAddress: string, eventInstanceId: string): Promise<{ timerTarget: number }> {
    this.log.debug(
      `REQUEST: Getting intermediate timer target with data: ${JSON.stringify({
        piAddress,
        eventInstanceId,
      })}`,
    );

    const timerTarget = await ProcessInstance.contract(
      this.client,
      piAddress,
    ).functions.getIntermediateEventTimerTarget(decodeHex(eventInstanceId));

    return timerTarget;
  }

  async triggerIntermediateEvent(piAddress: string, eventInstanceId: string): Promise<void> {
    this.log.debug(
      `REQUEST: Triggering completion of Intermediate Event with data: ${JSON.stringify({
        piAddress,
        eventInstanceId,
      })}`,
    );

    const bpmService = this.manager.BpmService.address;

    await ProcessInstance.contract(this.client, piAddress).functions.triggerIntermediateEvent(
      decodeHex(eventInstanceId),
      bpmService,
    );
  }

  async createDataMapping(
    processAddress: string,
    id: string,
    direction: number,
    accessPath: string,
    dataPath: string,
    dataStorageId: string,
    dataStorage: string,
  ) {
    this.log.debug(
      `REQUEST: Create data mapping withthis data: ${JSON.stringify({
        processAddress,
        id,
        direction,
        accessPath,
        dataPath,
        dataStorageId,
        dataStorage,
      })}`,
    );
    await ProcessDefinition.contract(this.client, processAddress).functions.createDataMapping(
      bytesFromString(id),
      direction,
      bytesFromString(accessPath),
      bytesFromString(dataPath),
      bytesFromString(dataStorageId),
      dataStorage,
    );
  }

  async createGateway(processAddress: string, gatewayId: string, gatewayType: number): Promise<void> {
    this.log.debug(
      `REQUEST: Create gateway with data: ${JSON.stringify({
        processAddress,
        gatewayId,
        gatewayType,
      })}`,
    );
    await ProcessDefinition.contract(this.client, processAddress).functions.createGateway(
      bytesFromString(gatewayId),
      gatewayType,
    );
  }

  async createTransition(
    processAddress: string,
    sourceGraphElement: string,
    targetGraphElement: string,
  ): Promise<void> {
    this.log.debug(
      `REQUEST: Create transition with data: ${JSON.stringify({
        processAddress,
        sourceGraphElement,
        targetGraphElement,
      })}`,
    );
    await ProcessDefinition.contract(this.client, processAddress)
      .functions.createTransition(bytesFromString(sourceGraphElement), bytesFromString(targetGraphElement))
      .then((data) => {
        if (data.error !== 1) {
          throw new Error(
            `Error code creating transition from ${sourceGraphElement} to ${targetGraphElement} in process at ${processAddress}: ${data[0]}`,
          );
        }
        this.log.info(
          `SUCCESS: Transition created from ${sourceGraphElement} to ${targetGraphElement} in process at ${processAddress}`,
        );
      });
  }

  async setDefaultTransition(processAddress: string, gatewayId: string, activityId: string): Promise<void> {
    this.log.debug(
      `REQUEST: Set default transition with data: ${JSON.stringify({
        processAddress,
        gatewayId,
        activityId,
      })}`,
    );
    await ProcessDefinition.contract(this.client, processAddress).functions.setDefaultTransition(
      bytesFromString(gatewayId),
      bytesFromString(activityId),
    );
    this.log.info(
      `SUCCESS: Default transition set from gateway ${gatewayId} to activity ${activityId} in process at ${processAddress}`,
    );
  }

  async createTransitionCondition(
    processAddress: string,
    dataType: DataType,
    gatewayId: string,
    activityId: string,
    dataPath: string,
    dataStorageId: string,
    dataStorage: string,
    operator: number,
    value: string,
  ) {
    this.log.debug(
      `REQUEST: Create transition condition with data: ${JSON.stringify({
        processAddress,
        dataType,
        gatewayId,
        activityId,
        dataPath,
        dataStorageId,
        dataStorage,
        operator,
        value,
      })}`,
    );

    const processDefinition = ProcessDefinition.contract(this.client, processAddress).functions;

    switch (dataType) {
      case DataType.BOOLEAN:
        await processDefinition.createTransitionConditionForBool(
          bytesFromString(gatewayId),
          bytesFromString(activityId),
          bytesFromString(dataPath),
          bytesFromString(dataStorageId),
          dataStorage,
          operator,
          value === 'true',
        );
        break;
      case DataType.STRING:
        await processDefinition.createTransitionConditionForString(
          bytesFromString(gatewayId),
          bytesFromString(activityId),
          bytesFromString(dataPath),
          bytesFromString(dataStorageId),
          dataStorage,
          operator,
          value,
        );
        break;
      case DataType.BYTES32:
        await processDefinition.createTransitionConditionForBytes32(
          bytesFromString(gatewayId),
          bytesFromString(activityId),
          bytesFromString(dataPath),
          bytesFromString(dataStorageId),
          dataStorage,
          operator,
          bytesFromString(value),
        );
        break;
      case DataType.UINT:
        await processDefinition.createTransitionConditionForUint(
          bytesFromString(gatewayId),
          bytesFromString(activityId),
          bytesFromString(dataPath),
          bytesFromString(dataStorageId),
          dataStorage,
          operator,
          parseInt(value, 10),
        );
        break;
      case DataType.INT:
        await processDefinition.createTransitionConditionForInt(
          bytesFromString(gatewayId),
          bytesFromString(activityId),
          bytesFromString(dataPath),
          bytesFromString(dataStorageId),
          dataStorage,
          operator,
          parseInt(value, 10),
        );
        break;
      case DataType.ADDRESS:
        await processDefinition.createTransitionConditionForAddress(
          bytesFromString(gatewayId),
          bytesFromString(activityId),
          bytesFromString(dataPath),
          bytesFromString(dataStorageId),
          dataStorage,
          operator,
          value,
        );
        break;
    }
    this.log.info(
      `SUCCESS: Created transition condition for transition between ${gatewayId} and ${activityId} in process at ${processAddress}`,
    );
  }

  async getModelAddressFromId(modelId: string): Promise<string> {
    this.log.debug(`REQUEST: Get model address for model id ${modelId}`);
    return this.manager.ProcessModelRepository.getModel(bytesFromString(modelId)).then((data) => data[0]);
  }

  async isValidProcess(processAddress: string): Promise<boolean> {
    this.log.debug(`REQUEST: Validate process definition at address: ${processAddress}`);
    return ProcessDefinition.contract(this.client, processAddress)
      .functions.validate()
      .then((data) => {
        if (!data.result) {
          throw new Error(`Invalid process definition at ${processAddress}: ${bytesToString(data.errorMessage)}`);
        } else {
          return true;
        }
      });
  }

  async getStartActivity(processAddress: string): Promise<string> {
    this.log.debug(`REQUEST: Get start activity id for process at address: ${processAddress}`);
    return ProcessDefinition.contract(this.client, processAddress)
      .functions.getStartActivity()
      .then((data) => {
        const activityId = bytesToString(data[0]);
        this.log.info(`SUCCESS: Retrieved start activity id ${activityId} for process at ${processAddress}`);
        return activityId;
      });
  }

  async getProcessInstanceCount(): Promise<number> {
    this.log.debug('REQUEST: Get process instance count');
    return this.manager.BpmService.functions.getNumberOfProcessInstances().then((data) => data.size);
  }

  async getProcessInstanceForActivity(activityInstanceId: string): Promise<string> {
    this.log.debug(`REQUEST: Get process instance for activity ${activityInstanceId}`);
    return this.manager.BpmService.functions
      .getProcessInstanceForActivity(decodeHex(activityInstanceId))
      .then((data) => data[0]);
  }

  getProcessInstance(piAddress: string) {
    return ProcessInstance.contract(this.client, piAddress).functions;
  }

  async getDataMappingKeys(
    processDefinition: ProcessDefinition.Contract,
    activityId: string,
    direction: Direction,
  ): Promise<string[]> {
    this.log.debug(
      `REQUEST: Get data mapping keys for process definition at ${processDefinition}, activity ${activityId} and direction ${direction}`,
    );
    const countPromise =
      direction === Direction.IN
        ? processDefinition.functions.getInDataMappingKeys
        : processDefinition.functions.getOutDataMappingKeys;

    return countPromise(bytesFromString(activityId)).then((data) => {
      if (data[0] && Array.isArray(data[0])) {
        const keys = data[0].map((key) => bytesToString(key));
        this.log.info(
          `SUCCESS: Retrieved data mapping keys for process definition at ${processDefinition}, activity ${activityId} and direction ${direction}: ${JSON.stringify(
            keys,
          )}`,
        );
        return keys;
      }
      this.log.info(
        `SUCCESS: No data mapping keys found for process definition at ${processDefinition}, activity ${activityId} and direction ${direction}`,
      );
      return [];
    });
  }

  async getDataMappingDetails(
    processDefinition: ProcessDefinition.Contract,
    activityId: string,
    dataMappingIds: Array<string>,
    direction: Direction,
  ) {
    this.log.debug(
      `REQUEST: Get data mapping details for process definition at ${processDefinition}, activity ${activityId}, data mapping ids ${JSON.stringify(
        dataMappingIds,
      )} and direction ${direction}`,
    );
    const dataPromises: Promise<{
      dataMappingId: Buffer;
      accessPath: Buffer;
      dataPath: Buffer;
      dataStorageId: Buffer;
      dataStorage: string;
    }>[] = [];
    dataMappingIds.forEach((dataMappingId) => {
      const getter =
        direction === Direction.IN
          ? processDefinition.functions.getInDataMappingDetails
          : processDefinition.functions.getOutDataMappingDetails;
      dataPromises.push(getter(bytesFromString(activityId), bytesFromString(dataMappingId)));
    });
    return Promise.all(dataPromises);
  }

  async getDataMappingDetailsForActivity(
    pdAddress: string,
    activityId: string,
    dataMappingIds: Array<string>,
    direction: Direction,
  ) {
    this.log.debug(
      `REQUEST: Get ${
        direction ? 'out-' : 'in-'
      }data mapping details for activity ${activityId} in process definition at ${pdAddress}`,
    );

    const processDefinition = ProcessDefinition.contract(this.client, pdAddress);
    // NOTE: activityId are hex converted inside getDataMappingKeys and not here
    const keys = dataMappingIds || (await this.getDataMappingKeys(processDefinition, activityId, direction));
    // NOTE: activityId and dataMappingIds are hex converted inside getDataMappingDetails and not here
    const details = await this.getDataMappingDetails(processDefinition, activityId, keys, direction);
    return details;
  }

  async getActivityInstanceData(
    piAddress: string,
    activityInstanceId: string,
  ): Promise<ReturnType<BpmService.Contract['functions']['getActivityInstanceData']>> {
    this.log.debug(
      `REQUEST: Get activity instance data for activity id ${activityInstanceId} in process instance at address ${piAddress}`,
    );
    const data = await this.manager.BpmService.functions.getActivityInstanceData(
      piAddress,
      decodeHex(activityInstanceId),
    );
    return {
      activityId: data.activityId,
      created: data.created,
      completed: data.completed,
      performer: data.performer,
      completedBy: data.completedBy,
      state: data.state,
    };
  }

  async getActivityInstanceIDAtIndex(piAddress: string, index: number): Promise<string> {
    return ProcessInstance.contract(this.client, piAddress)
      .functions.getActivityInstanceAtIndex(index)
      .then((data) => data[0])
      .then((data) => bytesToString(data));
  }

  async addExternalAddressToEcosystem(externalAddress: string, ecosystemAddress: string): Promise<void> {
    this.log.debug(`REQUEST: Add external address ${externalAddress} to Ecosystem at ${ecosystemAddress}`);
    await Ecosystem.contract(this.client, ecosystemAddress).functions.addExternalAddress(externalAddress);
    this.log.info(`SUCCESS: Added external address ${externalAddress} to ecosystem at ${ecosystemAddress}`);
  }

  async createUserInEcosystem({ username }: { username: string }, ecosystemAddress: string): Promise<string> {
    // FIXME[Silas]: I mean... this is a pretty weird dance, what we are expecting is not really much of a username is it?
    if (!username) {
      throw new Error('Username passed is empty');
    }
    if (!/^[0-9a-fA-F]+$/.test(username)) {
      throw new Error(`createUserInEcosystem expects username to be hex-encoded, but got '${username}'`);
    }
    this.log.debug(`REQUEST: Create a new user with ID: ${username} in ecosystem at ${ecosystemAddress}`);
    const id = decodeHex(username);
    return this.manager.ParticipantsManager.createUserAccount(id, '0x0', ecosystemAddress).then((data) => {
      this.log.info(`SUCCESS: Created new user ${username} at address ${data.userAccount}`);
      return data.userAccount;
    });
  }

  async createUser(user: { username: string }): Promise<string> {
    return this.createUserInEcosystem(user, this.ecosystem);
  }

  async getUserByIdAndEcosystem(id: string, ecosystemAddress: string): Promise<string> {
    this.log.trace(`REQUEST: Get user by id: ${id} in ecosystem at ${ecosystemAddress}`);
    return Ecosystem.contract(this.client, ecosystemAddress)
      .functions.getUserAccount(decodeHex(id))
      .then((data) => {
        this.log.trace(
          `SUCCESS: Retrieved user address ${data._account} by id ${id} and ecosystem ${ecosystemAddress}`,
        );
        return data._account;
      });
  }

  async getUserByUsername(username: string): Promise<string> {
    return this.getUserByIdAndEcosystem(username, this.ecosystem);
  }

  async getUserByUserId(userid: string): Promise<string> {
    return this.getUserByIdAndEcosystem(userid, this.ecosystem);
  }

  async addUserToEcosystem(username: string, address: string): Promise<void> {
    this.log.debug(`REQUEST: Add user ${username} with address ${address} to ecosystem at ${this.ecosystem}`);
    await Ecosystem.contract(this.client, this.ecosystem).functions.addUserAccount(decodeHex(username), address);
    this.log.info(
      `SUCCESS: Successfully added user ${username} with address ${address} to ecosystem at ${this.ecosystem}`,
    );
  }

  async migrateUserAccountInEcosystem(userAddress: string, migrateFromId: string, migrateToId: string): Promise<void> {
    this.log.debug(`REQUEST: Migrate user account ${userAddress} from id ${migrateFromId} to id ${migrateToId}`);
    return Ecosystem.contract(this.client, this.ecosystem).functions.migrateUserAccount(
      userAddress,
      decodeHex(migrateFromId),
      decodeHex(migrateToId),
    );
  }

  async createOrganization(org: { approvers: string[] }): Promise<string> {
    this.log.debug(`REQUEST: Create organization with: ${JSON.stringify(org)}`);
    return this.manager.ParticipantsManager.createOrganization(org.approvers ? org.approvers : []).then((data) => {
      if (data[0] !== 1) {
        throw new Error(`Error code creating new organization: ${data[0]}`);
      }
      this.log.info(`SUCCESS: Created new organization at address ${data[1]}, with approvers ${org.approvers}`);
      return data[1];
    });
  }

  async addUserToOrganization(
    userAddress: string,
    organizationAddress: string,
    actingUserAddress: string,
  ): Promise<void> {
    this.log.debug('REQUEST: Add user %s to organization %s', userAddress, organizationAddress);
    const { successful } = await Organization.contract(this.client, organizationAddress).functions.addUser(
      userAddress,
      callOnBehalfOf(actingUserAddress),
    );
    if (!successful) {
      throw new Error(`Failed to add user ${userAddress} to organization ${organizationAddress}!}`);
    } else {
      this.log.info(`SUCCESS: User ${userAddress} successfully added to organization ${organizationAddress}`);
    }
  }

  async removeUserFromOrganization(
    userAddress: string,
    organizationAddress: string,
    actingUserAddress: string,
  ): Promise<void> {
    this.log.debug('REQUEST: Remove user %s from organization %s', userAddress, organizationAddress);
    const { successful } = await Organization.contract(this.client, organizationAddress).functions.removeUser(
      userAddress,
      callOnBehalfOf(actingUserAddress),
    );
    if (!successful) {
      throw new Error(`Failed to remove user ${userAddress} from organization ${organizationAddress}!`);
    } else {
      this.log.info(`SUCCESS: User ${userAddress} successfully added to organization ${organizationAddress}`);
    }
  }

  async addApproverToOrganization(
    approverAddress: string,
    organizationAddress: string,
    actingUserAddress: string,
  ): Promise<void> {
    this.log.debug(`REQUEST: Add approver ${approverAddress} to organization ${organizationAddress}`);
    await Organization.contract(this.client, organizationAddress).functions.addApprover(
      approverAddress,
      callOnBehalfOf(actingUserAddress),
    );
    this.log.info(`SUCCESS: Approver ${approverAddress} successfully added to organization ${organizationAddress}`);
  }

  async removeApproverFromOrganization(
    approverAddress: string,
    organizationAddress: string,
    actingUserAddress: string,
  ) {
    this.log.debug(`REQUEST: Remove approver ${approverAddress} from organization ${organizationAddress}`);
    await Organization.contract(this.client, organizationAddress).functions.removeApprover(
      approverAddress,
      callOnBehalfOf(actingUserAddress),
    );
  }

  async createDepartment(organizationAddress: string, id: string, actingUserAddress: string): Promise<void> {
    this.log.debug(`REQUEST: Create department ${id} in organization ${organizationAddress}`);
    const [successful] = await Organization.contract(this.client, organizationAddress).functions.addDepartment(
      decodeHex(id),
      callOnBehalfOf(actingUserAddress),
    );
    if (!successful) {
      throw new Error(`Failed to create department ID ${id} in organization ${organizationAddress}!`);
    } else {
      this.log.info(`SUCCESS: Department ID ${id} successfully created in organization ${organizationAddress}`);
    }
  }

  async removeDepartment(organizationAddress: string, id: string, actingUserAddress: string): Promise<void> {
    this.log.debug(`REQUEST: Remove department ${id} from organization ${organizationAddress}`);
    const { successful } = await Organization.contract(this.client, organizationAddress).functions.removeDepartment(
      decodeHex(id),
      callOnBehalfOf(actingUserAddress),
    );
    if (!successful) {
      throw new Error(`Failed to remove department ID ${id} from organization ${organizationAddress}!`);
    } else {
      this.log.info(`SUCCESS: Department ID ${id} successfully removed from organization ${organizationAddress}`);
    }
  }

  async addDepartmentUser(
    organizationAddress: string,
    depId: string,
    userAddress: string,
    actingUserAddress: string,
  ): Promise<void> {
    this.log.debug(`REQUEST: Add user ${userAddress} to department ${depId} in organization ${organizationAddress}`);
    const { successful } = await Organization.contract(this.client, organizationAddress).functions.addUserToDepartment(
      userAddress,
      decodeHex(depId),
      callOnBehalfOf(actingUserAddress),
    );
    if (!successful) {
      throw new Error(
        `Failed to add user ${userAddress} to department ID ${depId} in organization ${organizationAddress}!`,
      );
    } else {
      this.log.info(
        `SUCCESS: User ${userAddress} successfully added to department ${depId} in organization ${organizationAddress}`,
      );
    }
  }

  async removeDepartmentUser(
    organizationAddress: string,
    depId: string,
    userAddress: string,
    actingUserAddress: string,
  ): Promise<void> {
    this.log.debug(
      `REQUEST: Remove user ${userAddress} from department ${depId} in organization ${organizationAddress}`,
    );
    const [successful] = await Organization.contract(
      this.client,
      organizationAddress,
    ).functions.removeUserFromDepartment(userAddress, decodeHex(depId), callOnBehalfOf(actingUserAddress));
    if (!successful) {
      throw new Error(
        `Failed to remove user ${userAddress} from department ID ${depId} in organization ${organizationAddress}!`,
      );
    } else {
      this.log.info(
        `SUCCESS: User ${userAddress} successfully removed from department ${depId} in organization ${organizationAddress}`,
      );
    }
  }
}

export async function NewContracts(url: string, account: string, ecosystemName: string): Promise<Contracts> {
  const client = new Client(url, account);
  const manager = await NewManager(client);

  let ecosystemAddress = await getFromNameRegistry(client, ecosystemName);
  if (!ecosystemAddress) {
    ecosystemAddress = await RegisterEcosystem(client, manager, account, ecosystemName);
  }

  return new Contracts(client, manager, ecosystemAddress);
}

export class SyncContracts extends Contracts {
  vent: VentListener;
  watch: BurrowWatcher;

  constructor(contracts: Contracts, vent: VentListener) {
    super(contracts.client, contracts.manager, contracts.ecosystem);

    this.vent = vent;
    this.watch = this.vent.NewWatcher();

    this.client.interceptor = async (data) => {
      this.watch.update(data);
      return data;
    };
  }

  async do<T>(func: (contracts: this) => Promise<T>): Promise<T> {
    const result = await func(this);
    await this.sync();
    return result;
  }

  async sync(): Promise<TxExecution> {
    return this.watch.wait();
  }
}

export async function NewSync(contracts: Contracts, vent: VentListener): Promise<SyncContracts> {
  await vent.listen();
  return new SyncContracts(contracts, vent);
}
