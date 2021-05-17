import { Client } from '@hyperledger/burrow';
import { ActiveAgreementRegistry } from '../agreements/ActiveAgreementRegistry.abi';
import { AgreementDates } from '../agreements/AgreementDates.abi';
import { ArchetypeRegistry } from '../agreements/ArchetypeRegistry.abi';
import { Completables } from '../agreements/Completables.abi';
import { ProcessModelRepository } from '../bpm-model/ProcessModelRepository.abi';
import { ApplicationRegistry } from '../bpm-runtime/ApplicationRegistry.abi';
import { BpmService } from '../bpm-runtime/BpmService.abi';
import { EcosystemRegistry } from '../commons-auth/EcosystemRegistry.abi';
import { ParticipantsManager } from '../commons-auth/ParticipantsManager.abi';
import { DOUG } from '../commons-management/DOUG.abi';
import { Contracts } from './constants';
import { getFromNameRegistry } from './utils';

async function lookup(doug: DOUG.Contract, contract: string) {
  const result = await doug.functions.lookup(contract);
  return result.contractAddress;
}

export type Manager = {
  EcosystemRegistry: EcosystemRegistry.Contract['functions'];
  ParticipantsManager: ParticipantsManager.Contract['functions'];
  ArchetypeRegistry: ArchetypeRegistry.Contract['functions'];
  ActiveAgreementRegistry: ActiveAgreementRegistry.Contract['functions'];
  ProcessModelRepository: ProcessModelRepository.Contract['functions'];
  ApplicationRegistry: ApplicationRegistry.Contract['functions'];
  BpmService: BpmService.Contract;
  Completables: Completables.Contract;
  AgreementDates: AgreementDates.Contract;
};

export async function NewManager(client: Client): Promise<Manager> {
  const addr = await getFromNameRegistry(client, 'DOUG');
  if (!addr) {
    throw new Error('could not find doug');
  }
  const doug = DOUG.contract(client, addr);

  const ecosystemRegistry = lookup(doug, Contracts.EcosystemRegistry);
  const participantsManager = lookup(doug, Contracts.ParticipantsManager);
  const archetypeRegistry = lookup(doug, Contracts.ArchetypeRegistry);
  const activeAgreementRegistry = lookup(doug, Contracts.ActiveAgreementRegistry);
  const processModelRepository = lookup(doug, Contracts.ProcessModelRepository);
  const applicationRegistry = lookup(doug, Contracts.ApplicationRegistry);
  const bpmService = lookup(doug, Contracts.BpmService);
  const completables = lookup(doug, Contracts.Completables);
  const agreementDates = lookup(doug, Contracts.AgreementDates);

  return {
    EcosystemRegistry: EcosystemRegistry.contract(client, await ecosystemRegistry).functions,
    ParticipantsManager: ParticipantsManager.contract(client, await participantsManager).functions,
    ArchetypeRegistry: ArchetypeRegistry.contract(client, await archetypeRegistry).functions,
    ActiveAgreementRegistry: ActiveAgreementRegistry.contract(client, await activeAgreementRegistry).functions,
    ProcessModelRepository: ProcessModelRepository.contract(client, await processModelRepository).functions,
    ApplicationRegistry: ApplicationRegistry.contract(client, await applicationRegistry).functions,
    BpmService: BpmService.contract(client, await bpmService),
    Completables: Completables.contract(client, await completables),
    AgreementDates: AgreementDates.contract(client, await agreementDates),
  };
}
