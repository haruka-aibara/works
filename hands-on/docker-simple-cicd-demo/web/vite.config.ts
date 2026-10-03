import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // Dockerfile / docker-compose / GitHub Actions が REACT_APP_API_SERVER を渡すので、CRA 時代の接頭辞をそのまま使う
  envPrefix: 'REACT_APP_',
  server: {
    host: true,
    port: 3000,
  },
  build: {
    // Dockerfile が /workspace/build を nginx にコピーする
    outDir: 'build',
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/setupTests.ts',
  },
});
