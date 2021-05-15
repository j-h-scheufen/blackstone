import { getBlockRange } from '@hyperledger/burrow/dist/events';
import { LogEvent } from '@hyperledger/burrow/proto/exec_pb';
import { Readable } from 'stream';
import { client } from '../tests/before';

export function readEventLog(address: string, signature: string, logsToRead: number): Promise<LogEvent[]> {
  const logs: LogEvent[] = [];
  let stream: Readable;
  return new Promise((resolve, reject) => {
    const range = getBlockRange(0, 'latest');
    range.getStart().setType(0);
    stream = client.burrow.listen(
      signature,
      address,
      (err, log) => {
        if (err) {
          return reject(err);
        }
        logs.push(log);
        if (logs.length === logsToRead) {
          resolve(logs);
        }
      },
      range,
    );
  });
}
