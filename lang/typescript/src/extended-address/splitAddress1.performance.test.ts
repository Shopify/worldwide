import {execFile} from 'child_process';
import {promises as fs} from 'fs';
import {tmpdir} from 'os';
import path from 'path';
import {pathToFileURL} from 'url';
import {promisify} from 'util';

import {rollup} from 'rollup';

import {mainConfig} from '../../rollup.config';

const runNode = promisify(execFile);
let temporaryDirectory: string;
let bundleUrl: string;

beforeAll(async () => {
  const bundle = await rollup({
    input: mainConfig.input,
    plugins: mainConfig.plugins,
  });
  try {
    const {output} = await bundle.generate({
      file: mainConfig.output[0].file,
      format: 'esm',
    });
    const entry = output.find((item) => item.type === 'chunk' && item.isEntry);
    if (!entry || entry.type !== 'chunk') {
      throw new Error('Public package entry was not generated');
    }
    temporaryDirectory = await fs.mkdtemp(path.join(tmpdir(), 'worldwide-nl-'));
    const bundlePath = path.join(temporaryDirectory, 'index.mjs');
    await fs.writeFile(bundlePath, entry.code);
    bundleUrl = pathToFileURL(bundlePath).href;
  } finally {
    await bundle.close();
  }
}, 30_000);

afterAll(async () => {
  if (temporaryDirectory) {
    await fs.unlink(path.join(temporaryDirectory, 'index.mjs'));
    await fs.rmdir(temporaryDirectory);
  }
});

test.each([
  {name: 'whitespace', prefix: ''},
  {name: 'street name followed by whitespace', prefix: 'Main'},
  {name: 'ordinal prefix followed by whitespace', prefix: '1e'},
])(
  'NL fallback handles $name within a bounded time',
  async ({prefix}) => {
    // A separate process makes the deadline enforceable during synchronous matching.
    // Repeated moderate inputs give a wide margin without a tiny timing threshold.
    const script = `
    import assert from 'node:assert/strict';
    const {splitAddress1} = await import(${JSON.stringify(bundleUrl)});
    const address = ${JSON.stringify(prefix)} + ' '.repeat(8192);
    for (let i = 0; i < 512; i++) {
      assert.deepEqual({...splitAddress1('NL', address, true)}, {streetName: address});
    }
  `;
    await expect(
      runNode(process.execPath, ['--input-type=module', '--eval', script], {
        timeout: 3_000,
        killSignal: 'SIGKILL',
      }),
    ).resolves.toMatchObject({stdout: ''});
  },
  10_000,
);
