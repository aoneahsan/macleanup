// User-provided configuration.
//
// These values are NOT secrets — the Firebase *web* apiKey and a Google OAuth
// *client ID* are safe to ship in a client app. NEVER put a private key or a
// Firebase service-account here.
//
// To enable Google sign-in + run-gating, fill these in (or override at build
// time via a local `src/config.local.ts` that re-exports CONFIG — it's
// gitignored). Until configured, the app runs in DEV MODE: no sign-in is
// required and runs are unlimited, so you can use/test the cleanup UI freely.

export interface AppConfig {
  firebase: {
    apiKey: string;
    projectId: string;
    authDomain: string;
  };
  google: {
    /** Google OAuth 2.0 "Desktop app" client ID (PKCE + loopback). */
    clientId: string;
    /** Desktop OAuth clients also issue a client secret; for installed apps
     *  this is not confidential. Leave empty to attempt PKCE-only. */
    clientSecret?: string;
  };
  /** Free cleanup runs allowed before Google sign-in is required. */
  freeRuns: number;
  repo: string;
}

export const CONFIG: AppConfig = {
  firebase: {
    apiKey: 'REPLACE_FIREBASE_WEB_API_KEY',
    projectId: 'REPLACE_FIREBASE_PROJECT_ID',
    authDomain: 'REPLACE_FIREBASE_PROJECT.firebaseapp.com',
  },
  google: {
    clientId: 'REPLACE_GOOGLE_OAUTH_CLIENT_ID',
    clientSecret: '',
  },
  freeRuns: 1,
  repo: 'https://github.com/aoneahsan/macleanup',
};

/** True once real Firebase + Google config has been filled in. */
export function isConfigured(): boolean {
  return (
    !CONFIG.firebase.apiKey.startsWith('REPLACE') &&
    !CONFIG.firebase.projectId.startsWith('REPLACE') &&
    !CONFIG.google.clientId.startsWith('REPLACE')
  );
}
