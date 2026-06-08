// Minimal process type shim for vite.config.ts (no @types/node installed).
// Only process.env.NODE_ENV is used in vite.config.ts.
declare const process: {
  env: { NODE_ENV?: string; [key: string]: string | undefined };
};
