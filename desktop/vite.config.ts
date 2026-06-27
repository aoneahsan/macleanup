import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Tauri serves the frontend; keep this lean. Port 5173 is the Tauri devUrl.
export default defineConfig({
  plugins: [react()],
  clearScreen: false,
  logLevel: 'info',
  server: {
    port: 5173,
    strictPort: true,
  },
  build: {
    target: 'safari14',
    // Smaller output for a desktop webview bundle.
    minify: 'esbuild',
    sourcemap: false,
  },
});
