import {spawnSync} from 'node:child_process';
import {readFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const packageJson = JSON.parse(
  readFileSync(resolve(packageRoot, 'package.json'), 'utf8'),
);
const packageSpec = `${packageJson.name}@${packageJson.version}`;
const registry = 'https://registry.npmjs.org';
const env = {
  ...process.env,
  npm_config_registry: registry,
};

const npmView = spawnSync(
  'npm',
  ['view', packageSpec, 'version', '--registry', registry, '--json'],
  {
    cwd: packageRoot,
    encoding: 'utf8',
    env,
  },
);

if (npmView.status === 0) {
  console.log(`${packageSpec} is already published on npm`);
  process.exit(0);
}

const npmViewOutput = `${npmView.stdout ?? ''}\n${npmView.stderr ?? ''}`;
if (!npmViewOutput.includes('E404')) {
  console.error(npmViewOutput.trim());
  process.exit(npmView.status ?? 1);
}

console.log(`${packageSpec} is not published on npm; publishing with npm CLI`);
const publish = spawnSync(
  'pnpm',
  [
    'dlx',
    'npm@11.5.1',
    'publish',
    '--no-git-checks',
    '--access',
    packageJson.publishConfig?.access ?? 'public',
    '--tag',
    'latest',
    '--provenance',
    '--registry',
    registry,
  ],
  {
    cwd: packageRoot,
    env,
    stdio: 'inherit',
  },
);

process.exit(publish.status ?? 1);
