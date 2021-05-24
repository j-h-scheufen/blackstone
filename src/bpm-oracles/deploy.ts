import { Client } from '@hyperledger/burrow';
import { DefaultApplicationRegistry } from '../bpm-runtime/DefaultApplicationRegistry.abi';
import { DefaultBpmService } from '../bpm-runtime/DefaultBpmService.abi';
import { DOUG } from '../commons-management/DOUG.abi';
import { DeadlineOracle } from './DeadlineOracle.abi';
import { WaitOracle } from './WaitOracle.abi';

export async function DeployDeadline(
  client: Client,
  doug: DOUG.Contract,
  service: Promise<DefaultBpmService.Contract>,
  registry: Promise<DefaultApplicationRegistry.Contract>,
  errorsLib: Promise<string>,
) {
  const bpmService = await service;
  const errorsLibAddress = await errorsLib;
  const oracleAddress = await DeadlineOracle.deploy(client, errorsLibAddress, bpmService.address);

  const applicationRegistry = await registry;
  await Promise.all([
    applicationRegistry.functions.addApplication(
      Buffer.from('Deadline Oracle'),
      0,
      oracleAddress,
      Buffer.from(''),
      Buffer.from(''),
    ),
    doug.functions.deploy('DeadlineOracle', oracleAddress),
  ]);
  await applicationRegistry.functions.addAccessPoint(Buffer.from('Deadline Oracle'), Buffer.from('Deadline'), 8, 0);
}

export async function DeployWait(
  client: Client,
  doug: DOUG.Contract,
  service: Promise<DefaultBpmService.Contract>,
  registry: Promise<DefaultApplicationRegistry.Contract>,
  errorsLib: Promise<string>,
) {
  const bpmService = await service;
  const errorsLibAddress = await errorsLib;
  const oracleAddress = await WaitOracle.deploy(client, errorsLibAddress, bpmService.address);

  const applicationRegistry = await registry;
  await Promise.all([
    applicationRegistry.functions.addApplication(
      Buffer.from('WaitOracle'),
      0,
      oracleAddress,
      Buffer.from(''),
      Buffer.from(''),
    ),
    doug.functions.deploy('WaitOracle', oracleAddress),
  ]);
  await applicationRegistry.functions.addAccessPoint(Buffer.from('WaitOracle'), Buffer.from('Frequency'), 2, 0);
}
