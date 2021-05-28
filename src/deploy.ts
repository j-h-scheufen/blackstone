import { Client } from '@hyperledger/burrow';
import { TotalCounterCheck } from './active-agreements/TotalCounterCheck.abi';
import { ActiveAgreementRegistryDb } from './agreements/ActiveAgreementRegistryDb.abi';
import { AgreementDates } from './agreements/AgreementDates.abi';
import { AgreementsAPI } from './agreements/AgreementsAPI.abi';
import { AgreementSignatureCheck } from './agreements/AgreementSignatureCheck.abi';
import { ArchetypeRegistryDb } from './agreements/ArchetypeRegistryDb.abi';
import { Completables } from './agreements/Completables.abi';
import { DefaultActiveAgreement } from './agreements/DefaultActiveAgreement.abi';
import { DefaultActiveAgreementRegistry } from './agreements/DefaultActiveAgreementRegistry.abi';
import { DefaultArchetype } from './agreements/DefaultArchetype.abi';
import { DefaultArchetypeRegistry } from './agreements/DefaultArchetypeRegistry.abi';
import { RenewalEvaluator } from './agreements/RenewalEvaluator.abi';
import { RenewalInitializer } from './agreements/RenewalInitializer.abi';
import { RenewalWindowManager } from './agreements/RenewalWindowManager.abi';
import { BpmModelLib } from './bpm-model/BpmModelLib.abi';
import { DefaultProcessDefinition } from './bpm-model/DefaultProcessDefinition.abi';
import { DefaultProcessModel } from './bpm-model/DefaultProcessModel.abi';
import { DefaultProcessModelRepository } from './bpm-model/DefaultProcessModelRepository.abi';
import { ProcessModelRepositoryDb } from './bpm-model/ProcessModelRepositoryDb.abi';
import { DeployDeadline, DeployWait } from './bpm-oracles/deploy';
import { ApplicationRegistry } from './bpm-runtime/ApplicationRegistry.abi';
import { ApplicationRegistryDb } from './bpm-runtime/ApplicationRegistryDb.abi';
import { BpmRuntimeLib } from './bpm-runtime/BpmRuntimeLib.abi';
import { BpmServiceDb } from './bpm-runtime/BpmServiceDb.abi';
import { DefaultApplicationRegistry } from './bpm-runtime/DefaultApplicationRegistry.abi';
import { DefaultBpmService } from './bpm-runtime/DefaultBpmService.abi';
import { DefaultProcessInstance } from './bpm-runtime/DefaultProcessInstance.abi';
import { DefaultEcosystem } from './commons-auth/DefaultEcosystem.abi';
import { DefaultEcosystemRegistry } from './commons-auth/DefaultEcosystemRegistry.abi';
import { DefaultOrganization } from './commons-auth/DefaultOrganization.abi';
import { DefaultParticipantsManager } from './commons-auth/DefaultParticipantsManager.abi';
import { DefaultUserAccount } from './commons-auth/DefaultUserAccount.abi';
import { EcosystemRegistryDb } from './commons-auth/EcosystemRegistryDb.abi';
import { ParticipantsManagerDb } from './commons-auth/ParticipantsManagerDb.abi';
import { ErrorsLib } from './commons-base/ErrorsLib.abi';
import { DataStorageUtils } from './commons-collections/DataStorageUtils.abi';
import { MappingsLib } from './commons-collections/MappingsLib.abi';
import { DefaultArtifactsRegistry } from './commons-management/DefaultArtifactsRegistry.abi';
import { DefaultDoug } from './commons-management/DefaultDoug.abi';
import { DOUG } from './commons-management/DOUG.abi';
import { DougProxy } from './commons-management/DougProxy.abi';
import { OwnedDelegateUnstructuredProxy } from './commons-management/OwnedDelegateUnstructuredProxy.abi';
import { UpgradeOwned } from './commons-management/UpgradeOwned.abi';
import { DeployNumbers } from './commons-math/deploy';
import { ERC165Utils } from './commons-standards/ERC165Utils.abi';
import { IsoCountries100 } from './commons-standards/IsoCountries100.abi';
import { IsoCurrencies100 } from './commons-standards/IsoCurrencies100.abi';
import { ArrayUtilsLib } from './commons-utils/ArrayUtilsLib.abi';
import { DataTypesAccess } from './commons-utils/DataTypesAccess.abi';
import { Strings } from './commons-utils/Strings.abi';
import { TypeUtilsLib } from './commons-utils/TypeUtilsLib.abi';
import { Contracts, Libraries } from './lib/constants';
import { setInNameRegistry } from './lib/utils';

function assert(left: string, right: string) {
  if (left != right) {
    throw new Error(`Expected to match: ${left} != ${right}`);
  }
}

export async function DeployDOUG(client: Client, errorsLib: Promise<string>, eRC165Utils: Promise<string>) {
  const errorsLibAddress = await errorsLib;
  const eRC165UtilsAddress = await eRC165Utils;

  const defaultArtifactsRegistryAddress = await DefaultArtifactsRegistry.deploy(client, errorsLibAddress);
  const artifactsRegistryAddress = await OwnedDelegateUnstructuredProxy.deploy(
    client,
    errorsLibAddress,
    defaultArtifactsRegistryAddress,
  );
  const defaultArtifactsRegistry = DefaultArtifactsRegistry.contract(client, artifactsRegistryAddress);
  await defaultArtifactsRegistry.functions.initialize();

  const defaultDougAddress = await DefaultDoug.deploy(client, errorsLibAddress, eRC165UtilsAddress);
  const dougProxyAddress = await DougProxy.deploy(client, errorsLibAddress, defaultDougAddress);
  const defaultDoug = DefaultDoug.contract(client, dougProxyAddress);

  await defaultArtifactsRegistry.functions.transferSystemOwnership(dougProxyAddress);
  await defaultDoug.functions.setArtifactsRegistry(artifactsRegistryAddress);

  const getArtifactsRegistryFromProxy = await defaultDoug.functions.getArtifactsRegistry().then((data) => data[0]);
  assert(artifactsRegistryAddress, getArtifactsRegistryFromProxy);

  return DOUG.contract(client, dougProxyAddress);
}

export async function DeployEcosystemRegistry(
  client: Client,
  doug: DOUG.Contract,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>,
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;

  const ecosystemRegistryAddress = await DefaultEcosystemRegistry.deploy(client, errorsLibAddress);
  const ecosystemRegistry = DefaultEcosystemRegistry.contract(client, ecosystemRegistryAddress);
  const ecosystemRegistryDbAddress = await EcosystemRegistryDb.deploy(client, errorsLibAddress, mappingsLibAddress);
  const ecosystemRegistryDb = EcosystemRegistryDb.contract(client, ecosystemRegistryDbAddress);

  await ecosystemRegistryDb.functions.transferSystemOwnership(ecosystemRegistryAddress);
  await ecosystemRegistry.functions.acceptDatabase(ecosystemRegistryDb.address);
  const upgradeEcosystemOwnership = UpgradeOwned.contract(client, ecosystemRegistry.address);
  await upgradeEcosystemOwnership.functions.transferUpgradeOwnership(doug.address);
  await doug.functions.deploy(Contracts.EcosystemRegistry, ecosystemRegistry.address);
  return ecosystemRegistry;
}

export async function DeployParticipantsManager(
  client: Client,
  doug: DOUG.Contract,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>,
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;

  const participantsManagerAddress = await DefaultParticipantsManager.deploy(client, errorsLibAddress);
  const participantsManager = DefaultParticipantsManager.contract(client, participantsManagerAddress);
  const participantsManagerDbAddress = await ParticipantsManagerDb.deploy(client, errorsLibAddress, mappingsLibAddress);
  const participantsManagerDb = ParticipantsManagerDb.contract(client, participantsManagerDbAddress);

  await participantsManagerDb.functions.transferSystemOwnership(participantsManager.address);
  await participantsManager.functions.acceptDatabase(participantsManagerDb.address);
  const upgradeParticipantsOwnership = UpgradeOwned.contract(client, participantsManager.address);
  await upgradeParticipantsOwnership.functions.transferUpgradeOwnership(doug.address);
  await doug.functions.deploy(Contracts.ParticipantsManager, participantsManager.address);
  return participantsManager;
}

export async function RegisterEcosystemAndParticipantClasses(
  client: Client,
  doug: DOUG.Contract,
  participantsManager: Promise<DefaultParticipantsManager.Contract>,
  ecosystemRegistry: Promise<DefaultEcosystemRegistry.Contract>,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>,
  arrayUtilsLib: Promise<string>,
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;
  const arrayUtilsLibAddress = await arrayUtilsLib;

  const participants = await participantsManager;
  const ecosystem = await ecosystemRegistry;

  const defaultOrganizationAddress = await DefaultOrganization.deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress,
    arrayUtilsLibAddress,
  );
  const objectClassOrganization = await participants.functions.OBJECT_CLASS_ORGANIZATION().then((data) => data[0]);
  await doug.functions.register(objectClassOrganization, defaultOrganizationAddress);
  const defaultUserAccountAddress = await DefaultUserAccount.deploy(client, errorsLibAddress, mappingsLibAddress);
  const objectClassUserAccount = await participants.functions.OBJECT_CLASS_USER_ACCOUNT().then((data) => data[0]);
  await doug.functions.register(objectClassUserAccount, defaultUserAccountAddress);
  const defaultEcosystemAddress = await DefaultEcosystem.deploy(client, errorsLibAddress, mappingsLibAddress);
  const objectClassEcosystem = await ecosystem.functions.OBJECT_CLASS_ECOSYSTEM().then((data) => data[0]);
  await doug.functions.register(objectClassEcosystem, defaultEcosystemAddress);
}

export async function DeployProcessModelRepository(
  client: Client,
  doug: DOUG.Contract,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>,
  arrayUtilsLib: Promise<string>,
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;
  const arrayUtilsLibAddress = await arrayUtilsLib;

  const processModelRepositoryAddress = await DefaultProcessModelRepository.deploy(client, errorsLibAddress);
  const processModelRepository = DefaultProcessModelRepository.contract(client, processModelRepositoryAddress);
  const processModelRepositoryDbAddress = await ProcessModelRepositoryDb.deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress,
    arrayUtilsLibAddress,
  );
  const processModelRepositoryDb = ProcessModelRepositoryDb.contract(client, processModelRepositoryDbAddress);

  await processModelRepositoryDb.functions.transferSystemOwnership(processModelRepository.address);
  await processModelRepository.functions.acceptDatabase(processModelRepositoryDb.address);
  const upgradeProcessModelOwnership = UpgradeOwned.contract(client, processModelRepository.address);
  await upgradeProcessModelOwnership.functions.transferUpgradeOwnership(doug.address);
  await doug.functions.deploy(Contracts.ProcessModelRepository, processModelRepository.address);
  return processModelRepository;
}

export async function DeployApplicationRegistry(client: Client, doug: DOUG.Contract, errorsLib: Promise<string>) {
  const errorsLibAddress = await errorsLib;

  const applicationRegistryAddress = await DefaultApplicationRegistry.deploy(client, errorsLibAddress);
  const applicationRegistry = DefaultApplicationRegistry.contract(client, applicationRegistryAddress);
  const applicationRegistryDbAddress = await ApplicationRegistryDb.deploy(client, errorsLibAddress);
  const applicationRegistryDb = ApplicationRegistryDb.contract(client, applicationRegistryDbAddress);

  await applicationRegistryDb.functions.transferSystemOwnership(applicationRegistry.address);
  await applicationRegistry.functions.acceptDatabase(applicationRegistryDb.address);
  const upgradeApplicationRegistryOwnership = UpgradeOwned.contract(client, applicationRegistry.address);
  await upgradeApplicationRegistryOwnership.functions.transferUpgradeOwnership(doug.address);
  await doug.functions.deploy(Contracts.ApplicationRegistry, applicationRegistry.address);
  return applicationRegistry;
}

export async function DeployBpmService(
  client: Client,
  doug: DOUG.Contract,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>,
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;

  const bpmServiceAddress = await DefaultBpmService.deploy(
    client,
    errorsLibAddress,
    Contracts.ProcessModelRepository,
    Contracts.ApplicationRegistry,
  );
  const bpmService = DefaultBpmService.contract(client, bpmServiceAddress);
  const bpmServiceDbAddress = await BpmServiceDb.deploy(client, errorsLibAddress, mappingsLibAddress);
  const bpmServiceDb = BpmServiceDb.contract(client, bpmServiceDbAddress);

  await bpmServiceDb.functions.transferSystemOwnership(bpmService.address);
  await bpmService.functions.acceptDatabase(bpmServiceDb.address);
  const upgradeBpmServiceOwnership = UpgradeOwned.contract(client, bpmService.address);
  await upgradeBpmServiceOwnership.functions.transferUpgradeOwnership(doug.address);
  await doug.functions.deploy(Contracts.BpmService, bpmService.address);
  return bpmService;
}

export async function RegisterProcessModelRepositoryClasses(
  client: Client,
  doug: DOUG.Contract,
  contract: Promise<DefaultProcessModelRepository.Contract>,
  service: Promise<DefaultBpmService.Contract>,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>,
  arrayUtilsLib: Promise<string>,
  bpmModelLib: Promise<string>,
  typeUtilsLib: Promise<string>,
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;
  const bpmModelLibAddress = await bpmModelLib;
  const arrayUtilsLibAddress = await arrayUtilsLib;
  const typeUtilsLibAddress = await typeUtilsLib;

  const processModelRepository = await contract;
  const bpmService = await service;

  const getModelRepositoryFromBpmService = await bpmService.functions
    .getProcessModelRepository()
    .then((data) => data[0]);
  assert(getModelRepositoryFromBpmService, processModelRepository.address);

  const defaultProcessModelImplementationAddress = await DefaultProcessModel.deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress,
  );
  const objectClassProcessModel = await processModelRepository.functions
    .OBJECT_CLASS_PROCESS_MODEL()
    .then((data) => data[0]);
  await doug.functions.register(objectClassProcessModel, defaultProcessModelImplementationAddress);

  const defaultProcessDefinitionImplementationAddress = await DefaultProcessDefinition.deploy(
    client,
    bpmModelLibAddress,
    errorsLibAddress,
    arrayUtilsLibAddress,
    typeUtilsLibAddress,
  );
  const objectClassProcessDefinition = await processModelRepository.functions
    .OBJECT_CLASS_PROCESS_DEFINITION()
    .then((data) => data[0]);
  await doug.functions.register(objectClassProcessDefinition, defaultProcessDefinitionImplementationAddress);
}

export async function RegisterApplicationRepositoryClasses(
  client: Client,
  doug: DOUG.Contract,
  contract: Promise<DefaultApplicationRegistry.Contract>,
  service: Promise<DefaultBpmService.Contract>,
  errorsLib: Promise<string>,
  bpmRuntimeLib: Promise<string>,
  dataStorageUtils: Promise<string>,
) {
  const applicationRegistry = await contract;
  const bpmService = await service;

  const errorsLibAddress = await errorsLib;
  const bpmRuntimeLibAddress = await bpmRuntimeLib;
  const dataStorageUtilsAddress = await dataStorageUtils;

  const getApplicationRegistryFromBpmService = await bpmService.functions
    .getApplicationRegistry()
    .then((data) => data[0]);
  assert(getApplicationRegistryFromBpmService, applicationRegistry.address);

  const defaultProcessInstanceImplementationAddress = await DefaultProcessInstance.deploy(
    client,
    bpmRuntimeLibAddress,
    errorsLibAddress,
    dataStorageUtilsAddress,
  );
  const objectClassProcessInstance = await bpmService.functions.OBJECT_CLASS_PROCESS_INSTANCE().then((data) => data[0]);
  await doug.functions.register(objectClassProcessInstance, defaultProcessInstanceImplementationAddress);
}

export async function DeployArchetypeRegistry(
  client: Client,
  doug: DOUG.Contract,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>,
  arrayUtilsLib: Promise<string>,
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;
  const arrayUtilsLibAddress = await arrayUtilsLib;

  const archetypeRegistryAddress = await DefaultArchetypeRegistry.deploy(client, errorsLibAddress);
  const archetypeRegistry = DefaultArchetypeRegistry.contract(client, archetypeRegistryAddress);
  const archetypeRegistryDbAddress = await ArchetypeRegistryDb.deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress,
    arrayUtilsLibAddress,
  );
  const archetypeRegistryDb = ArchetypeRegistryDb.contract(client, archetypeRegistryDbAddress);

  await archetypeRegistryDb.functions.transferSystemOwnership(archetypeRegistry.address);
  await archetypeRegistry.functions.acceptDatabase(archetypeRegistryDb.address);
  const upgradeArchetypeRegistryOwnership = UpgradeOwned.contract(client, archetypeRegistry.address);
  await upgradeArchetypeRegistryOwnership.functions.transferUpgradeOwnership(doug.address);
  await doug.functions.deploy(Contracts.ArchetypeRegistry, archetypeRegistry.address);
  return archetypeRegistry;
}

export async function DeployActiveAgreementRegistry(
  client: Client,
  doug: DOUG.Contract,
  errorsLib: Promise<string>,
  dataStorageUtils: Promise<string>,
  mappingsLib: Promise<string>,
  arrayUtilsLib: Promise<string>,
) {
  const errorsLibAddress = await errorsLib;
  const dataStorageUtilsAddress = await dataStorageUtils;
  const mappingsLibAddress = await mappingsLib;
  const arrayUtilsLibAddress = await arrayUtilsLib;

  const activeAgreementRegistryAddress = await DefaultActiveAgreementRegistry.deploy(
    client,
    errorsLibAddress,
    dataStorageUtilsAddress,
    Contracts.ArchetypeRegistry,
    Contracts.BpmService,
  );
  const activeAgreementRegistry = DefaultActiveAgreementRegistry.contract(client, activeAgreementRegistryAddress);
  const activeAgreementRegistryDbAddress = await ActiveAgreementRegistryDb.deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress,
    arrayUtilsLibAddress,
  );
  const activeAgreementRegistryDb = ActiveAgreementRegistryDb.contract(client, activeAgreementRegistryDbAddress);

  await activeAgreementRegistryDb.functions.transferSystemOwnership(activeAgreementRegistry.address);
  await activeAgreementRegistry.functions.acceptDatabase(activeAgreementRegistryDb.address);
  const upgradeActiveAgreementRegistryOwnership = UpgradeOwned.contract(client, activeAgreementRegistry.address);
  await upgradeActiveAgreementRegistryOwnership.functions.transferUpgradeOwnership(doug.address);
  await doug.functions.deploy(Contracts.ActiveAgreementRegistry, activeAgreementRegistry.address);
  return activeAgreementRegistry;
}

export async function RegisterAgreementClasses(
  client: Client,
  doug: DOUG.Contract,
  agreement: Promise<DefaultActiveAgreementRegistry.Contract>,
  archetype: Promise<DefaultArchetypeRegistry.Contract>,
  service: Promise<DefaultBpmService.Contract>,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>,
  eRC165Utils: Promise<string>,
  arrayUtilsLib: Promise<string>,
  agreementsAPI: Promise<string>,
  dataStorageUtils: Promise<string>,
) {
  const activeAgreementRegistry = await agreement;
  const archetypeRegistry = await archetype;
  const bpmService = await service;

  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;
  const eRC165UtilsAddress = await eRC165Utils;
  const arrayUtilsLibAddress = await arrayUtilsLib;
  const agreementsAPIAddress = await agreementsAPI;
  const dataStorageUtilsAddress = await dataStorageUtils;

  const getBpmServiceFromAgreementRegistry = await activeAgreementRegistry.functions
    .getBpmService()
    .then((data) => data.location);
  assert(getBpmServiceFromAgreementRegistry, bpmService.address);
  const getArchetypeRegistryFromAgreementRegistry = await activeAgreementRegistry.functions
    .getArchetypeRegistry()
    .then((data) => data.location);
  assert(getArchetypeRegistryFromAgreementRegistry, archetypeRegistry.address);

  const defaultArchetypeImplementationAddress = await DefaultArchetype.deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress,
    eRC165UtilsAddress,
    arrayUtilsLibAddress,
  );
  const objectClassArchetype = await archetypeRegistry.functions.OBJECT_CLASS_ARCHETYPE().then((data) => data[0]);
  await doug.functions.register(objectClassArchetype, defaultArchetypeImplementationAddress);
  const defaultActiveAgreementImplementationAddress = await DefaultActiveAgreement.deploy(
    client,
    agreementsAPIAddress,
    errorsLibAddress,
    dataStorageUtilsAddress,
    mappingsLibAddress,
    eRC165UtilsAddress,
    arrayUtilsLibAddress,
  );
  const objectClassActiveAgreement = await activeAgreementRegistry.functions
    .OBJECT_CLASS_AGREEMENT()
    .then((data) => data[0]);
  await doug.functions.register(objectClassActiveAgreement, defaultActiveAgreementImplementationAddress);
}

type StringsThenBool<T> = T extends [...(infer S)[], boolean]
  ? S extends [...string[]]
    ? [...S, boolean]
    : never
  : never;

export async function deployLib(
  cli: Client,
  call: (client: Client, ...arg: (string | boolean)[]) => Promise<string>,
  ...addr: Promise<string>[]
): Promise<string> {
  const addresses = await Promise.all(addr);
  return call(cli, ...addresses);
}

export async function RegisterLib(doug: DOUG.Contract, id: string, lib: Promise<string>) {
  const address = await lib;
  await doug.functions.register(id, address);
}

export async function DeployRenewalWindowManager(
  client: Client,
  doug: DOUG.Contract,
  service: Promise<DefaultBpmService.Contract>,
  registry: Promise<DefaultApplicationRegistry.Contract>,
  errorsLib: Promise<string>,
) {
  const bpmService = await service;
  const errorsLibAddress = await errorsLib;
  const renewalWindowManagerAddress = await RenewalWindowManager.deploy(client, errorsLibAddress, bpmService.address);
  const applicationRegistry = await registry;
  await Promise.all([
    applicationRegistry.functions.addApplication(
      Buffer.from('RenewalWindowManager'),
      0,
      renewalWindowManagerAddress,
      Buffer.from(''),
      Buffer.from(''),
    ),
    doug.functions.deploy('RenewalWindowManager', renewalWindowManagerAddress),
  ]);
}

export async function DeployCompletables(
  client: Client,
  doug: DOUG.Contract,
  agreementsApi: Promise<string>,
  errorsLib: Promise<string>,
  stringsLib: Promise<string>,
) {
  const completables = await deployLib(client, Completables.deploy, agreementsApi, errorsLib, stringsLib);
  await UpgradeOwned.contract(client, completables).functions.transferUpgradeOwnership(doug.address);
  await doug.functions.deploy(Contracts.Completables, completables);
}

export async function DeployAgreementDates(
  client: Client,
  doug: DOUG.Contract,
  agreementsApi: Promise<string>,
  errorsLib: Promise<string>,
  stringsLib: Promise<string>,
) {
  const agreementDates = await deployLib(client, AgreementDates.deploy, agreementsApi, errorsLib, stringsLib);
  await UpgradeOwned.contract(client, agreementDates).functions.transferUpgradeOwnership(doug.address);
  await doug.functions.deploy(Contracts.AgreementDates, agreementDates);
}

export async function DeployRenewalInitializer(
  client: Client,
  doug: DOUG.Contract,
  registry: Promise<DefaultApplicationRegistry.Contract>,
  errorsLib: Promise<string>,
) {
  const errorsLibAddress = await errorsLib;
  const renewalInitializer = await RenewalInitializer.deploy(client, errorsLibAddress);
  const applicationRegistry = await registry;
  await Promise.all([
    applicationRegistry.functions.addApplication(
      Buffer.from('RenewalInitializer'),
      0,
      renewalInitializer,
      Buffer.from(''),
      Buffer.from(''),
    ),
    doug.functions.deploy('RenewalInitializer', renewalInitializer),
  ]);
}

export async function DeployRenewalEvaluator(
  client: Client,
  doug: DOUG.Contract,
  registry: Promise<DefaultApplicationRegistry.Contract>,
) {
  const renewalEvaluator = await RenewalEvaluator.deploy(client);
  const applicationRegistry = await registry;
  await Promise.all([
    applicationRegistry.functions.addApplication(
      Buffer.from('RenewalEvaluator'),
      0,
      renewalEvaluator,
      Buffer.from(''),
      Buffer.from(''),
    ),
    doug.functions.deploy('RenewalEvaluator', renewalEvaluator),
  ]);
}

export async function Deploy(client: Client) {
  const errorsLib = ErrorsLib.deploy(client);
  const typeUtilsLib = TypeUtilsLib.deploy(client);
  const arrayUtilsLib = ArrayUtilsLib.deploy(client);
  const mappingsLib = deployLib(client, MappingsLib.deploy, arrayUtilsLib, typeUtilsLib);
  const stringsLib = Strings.deploy(client);
  const dataStorageUtils = deployLib(client, DataStorageUtils.deploy, errorsLib, typeUtilsLib);
  const eRC165Utils = ERC165Utils.deploy(client);
  const bpmModelLib = deployLib(client, BpmModelLib.deploy, errorsLib, dataStorageUtils);
  const bpmRuntimeLib = deployLib(client, BpmRuntimeLib.deploy, errorsLib, dataStorageUtils, eRC165Utils, typeUtilsLib);
  const agreementsAPI = deployLib(client, AgreementsAPI.deploy, eRC165Utils);
  const dataTypesAccess = DataTypesAccess.deploy(client);

  const doug = await DeployDOUG(client, errorsLib, eRC165Utils);
  const ecosystemRegistry = DeployEcosystemRegistry(client, doug, errorsLib, mappingsLib);
  const participantsManager = DeployParticipantsManager(client, doug, errorsLib, mappingsLib);
  const processModelRepository = DeployProcessModelRepository(client, doug, errorsLib, mappingsLib, arrayUtilsLib);
  const applicationRegistry = DeployApplicationRegistry(client, doug, errorsLib);
  const bpmService = DeployBpmService(client, doug, errorsLib, mappingsLib);
  const archetypeRegistry = DeployArchetypeRegistry(client, doug, errorsLib, mappingsLib, arrayUtilsLib);
  const activeAgreementRegistry = DeployActiveAgreementRegistry(
    client,
    doug,
    errorsLib,
    dataStorageUtils,
    mappingsLib,
    arrayUtilsLib,
  );
  await Promise.all([
    setInNameRegistry(client, Contracts.DOUG, doug.address),
    RegisterEcosystemAndParticipantClasses(
      client,
      doug,
      participantsManager,
      ecosystemRegistry,
      errorsLib,
      mappingsLib,
      arrayUtilsLib,
    ),
    RegisterProcessModelRepositoryClasses(
      client,
      doug,
      processModelRepository,
      bpmService,
      errorsLib,
      mappingsLib,
      arrayUtilsLib,
      bpmModelLib,
      typeUtilsLib,
    ),
    RegisterApplicationRepositoryClasses(
      client,
      doug,
      applicationRegistry,
      bpmService,
      errorsLib,
      bpmRuntimeLib,
      dataStorageUtils,
    ),
    RegisterAgreementClasses(
      client,
      doug,
      activeAgreementRegistry,
      archetypeRegistry,
      bpmService,
      errorsLib,
      mappingsLib,
      eRC165Utils,
      arrayUtilsLib,
      agreementsAPI,
      dataStorageUtils,
    ),
    deployLib(client, IsoCountries100.deploy, errorsLib),
    deployLib(client, IsoCurrencies100.deploy, errorsLib),
  ]);

  // Applications
  // ApplicationTypes Enum: {0=EVENT, 1=SERVICE, 2=WEB}

  const appRegistry = ApplicationRegistry.contract(client, (await applicationRegistry).address);
  const agreementSignatureCheckAddress = await AgreementSignatureCheck.deploy(client);
  const totalCounterCheckAddress = await TotalCounterCheck.deploy(client);

  await Promise.all([
    appRegistry.functions.addApplication(
      Buffer.from('AgreementSignatureCheck'),
      2,
      agreementSignatureCheckAddress,
      Buffer.from(''),
      Buffer.from('SigningWebFormWithSignatureCheck'),
    ),
    appRegistry.functions.addAccessPoint(Buffer.from('AgreementSignatureCheck'), Buffer.from('agreement'), 59, 0),
    appRegistry.functions.addApplication(
      Buffer.from('TotalCounterCheck'),
      1,
      totalCounterCheckAddress,
      Buffer.from(''),
      Buffer.from(''),
    ),
    appRegistry.functions.addAccessPoint(Buffer.from('TotalCounterCheck'), Buffer.from('numberIn'), 8, 0),
    appRegistry.functions.addAccessPoint(Buffer.from('TotalCounterCheck'), Buffer.from('totalIn'), 8, 0),
    appRegistry.functions.addAccessPoint(Buffer.from('TotalCounterCheck'), Buffer.from('numberOut'), 8, 1),
    appRegistry.functions.addAccessPoint(Buffer.from('TotalCounterCheck'), Buffer.from('completedOut'), 1, 1),
  ]);

  await Promise.all([
    DeployRenewalWindowManager(client, doug, bpmService, applicationRegistry, errorsLib),
    DeployRenewalInitializer(client, doug, applicationRegistry, errorsLib),
    DeployRenewalEvaluator(client, doug, applicationRegistry),
    DeployDeadline(client, doug, bpmService, applicationRegistry, errorsLib),
    DeployWait(client, doug, bpmService, applicationRegistry, errorsLib),
    DeployNumbers(client, applicationRegistry),
    DeployCompletables(client, doug, agreementsAPI, errorsLib, stringsLib),
    DeployAgreementDates(client, doug, agreementsAPI, errorsLib, stringsLib),
  ]);

  await Promise.all([
    RegisterLib(doug, Libraries.ErrorsLib, errorsLib),
    RegisterLib(doug, Libraries.TypeUtilsLib, typeUtilsLib),
    RegisterLib(doug, Libraries.ArrayUtilsLib, arrayUtilsLib),
    RegisterLib(doug, Libraries.MappingsLib, mappingsLib),
    RegisterLib(doug, Libraries.DataStorageUtils, dataStorageUtils),
    RegisterLib(doug, Libraries.ERC165Utils, eRC165Utils),
    RegisterLib(doug, Libraries.BpmModelLib, bpmModelLib),
    RegisterLib(doug, Libraries.BpmRuntimeLib, bpmRuntimeLib),
    RegisterLib(doug, Libraries.AgreementsAPI, agreementsAPI),
    RegisterLib(doug, Libraries.Strings, stringsLib),
  ]);
}
