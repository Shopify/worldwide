import typescript from '@rollup/plugin-typescript';
import yaml from '@rollup/plugin-yaml';
import alias from '@rollup/plugin-alias';

export default {
  input: 'src/index.ts',
  output: {
    dir: 'dist',
    format: 'cjs',
    sourcemap: true,
  },
  plugins: [
    typescript(),
    alias({
      entries: [
        {find: '@', replacement: './src'},
        {find: '@data', replacement: '../../db/data'},
      ],
    }),
    yaml(),
  ],
};
