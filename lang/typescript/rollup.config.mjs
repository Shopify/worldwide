// rollup.config.js
import typescript from '@rollup/plugin-typescript';

// eslint-disable-next-line import/no-anonymous-default-export
export default {
  input: 'src/index.ts',
  output: {
    dir: 'dist',
    format: 'cjs',
    sourcemap: true,
  },
  plugins: [typescript()],
};
