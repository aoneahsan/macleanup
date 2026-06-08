/// <reference types="vite/client" />

declare module '*.svg' {
  const url: string;
  export default url;
}

declare module '*.svg?url' {
  const url: string;
  export default url;
}

// Provide `process` global for vite.config.ts (referenced by tsconfig.node.json).
// This is needed because @types/node is not installed and vite.config.ts uses
// process.env.NODE_ENV. The real `process` is injected by Node.js/Vite at build time.
declare const process: {
  env: { NODE_ENV?: string; [key: string]: string | undefined };
  [key: string]: unknown;
};
