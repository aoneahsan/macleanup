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
    reportCompressedSize: true,
    rollupOptions: {
      output: {
        // Split heavy third-party deps out of the entry chunk. NOTE:
        // react/react-dom/scheduler MUST stay together in one chunk —
        // splitting them apart blanks the app with a null-dispatcher error.
        manualChunks(id: string) {
          const s = id.replace(/\\/g, '/');
          if (s.indexOf('/node_modules/') === -1) return undefined;
          if (/\/node_modules\/(react|react-dom|scheduler)\//.test(s)) return 'vendor-react';
          if (/\/node_modules\/@tauri-apps\//.test(s)) return 'vendor-tauri';
          return undefined;
        },
      },
    },
  },
});
