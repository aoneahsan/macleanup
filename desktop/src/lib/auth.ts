// Google sign-in for a desktop app: PKCE + system-browser + loopback redirect
// (Google forbids OAuth inside embedded webviews), then exchange the Google
// id_token for a Firebase session via the Identity Toolkit REST API. No heavy
// SDK — just fetch + the Rust loopback helper.
import { open } from '@tauri-apps/plugin-shell';
import { CONFIG, isConfigured } from '../config';
import { oauthListen, onOauthRedirect } from './cli';

export interface User {
  uid: string;
  email: string;
  displayName: string;
  photoUrl: string;
  idToken: string;
  refreshToken: string;
}

const STORE_KEY = 'macleanup.user';

export function loadUser(): User | null {
  try {
    const raw = localStorage.getItem(STORE_KEY);
    return raw ? (JSON.parse(raw) as User) : null;
  } catch {
    return null;
  }
}

export function saveUser(u: User | null): void {
  if (u) localStorage.setItem(STORE_KEY, JSON.stringify(u));
  else localStorage.removeItem(STORE_KEY);
}

export function signOut(): void {
  saveUser(null);
}

// ── PKCE helpers (Web Crypto) ──────────────────────────────────────────────
function base64url(bytes: Uint8Array): string {
  let s = '';
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
function randomString(len = 64): string {
  const a = new Uint8Array(len);
  crypto.getRandomValues(a);
  return base64url(a);
}
async function sha256(input: string): Promise<Uint8Array> {
  const data = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest('SHA-256', data);
  return new Uint8Array(digest);
}

/**
 * Full Google → Firebase sign-in. Opens the system browser, captures the
 * loopback redirect, exchanges the code for a Google id_token, then signs in
 * to Firebase. Returns the authenticated user.
 */
export async function signInWithGoogle(): Promise<User> {
  if (!isConfigured()) {
    throw new Error('Auth is not configured. Add Firebase + Google OAuth config in src/config.ts.');
  }

  const port = await oauthListen();
  const redirectUri = `http://127.0.0.1:${port}`;
  const verifier = randomString(64);
  const challenge = base64url(await sha256(verifier));
  const state = randomString(16);

  // Promise that resolves when the loopback receives the redirect.
  const codePromise = new Promise<string>((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('Sign-in timed out.')), 5 * 60 * 1000);
    onOauthRedirect((query) => {
      clearTimeout(timeout);
      const params = new URLSearchParams(query);
      if (params.get('state') !== state) return reject(new Error('OAuth state mismatch.'));
      const code = params.get('code');
      if (!code) return reject(new Error(params.get('error') || 'No authorization code returned.'));
      resolve(code);
    });
  });

  const authUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth');
  authUrl.search = new URLSearchParams({
    client_id: CONFIG.google.clientId,
    redirect_uri: redirectUri,
    response_type: 'code',
    scope: 'openid email profile',
    code_challenge: challenge,
    code_challenge_method: 'S256',
    state,
    access_type: 'offline',
    prompt: 'select_account',
  }).toString();
  await open(authUrl.toString());

  const code = await codePromise;

  // Exchange the authorization code for a Google id_token.
  const tokenBody = new URLSearchParams({
    code,
    client_id: CONFIG.google.clientId,
    redirect_uri: redirectUri,
    grant_type: 'authorization_code',
    code_verifier: verifier,
  });
  if (CONFIG.google.clientSecret) tokenBody.set('client_secret', CONFIG.google.clientSecret);

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: tokenBody.toString(),
  });
  if (!tokenRes.ok) throw new Error(`Google token exchange failed: ${await tokenRes.text()}`);
  const tokenJson = (await tokenRes.json()) as { id_token?: string };
  if (!tokenJson.id_token) throw new Error('Google did not return an id_token.');

  // Sign in to Firebase with the Google credential.
  const fbRes = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=${CONFIG.firebase.apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        postBody: `id_token=${tokenJson.id_token}&providerId=google.com`,
        requestUri: redirectUri,
        returnIdpCredential: true,
        returnSecureToken: true,
      }),
    },
  );
  if (!fbRes.ok) throw new Error(`Firebase sign-in failed: ${await fbRes.text()}`);
  const fb = (await fbRes.json()) as {
    localId: string;
    email: string;
    displayName?: string;
    photoUrl?: string;
    idToken: string;
    refreshToken: string;
  };

  const user: User = {
    uid: fb.localId,
    email: fb.email,
    displayName: fb.displayName || fb.email,
    photoUrl: fb.photoUrl || '',
    idToken: fb.idToken,
    refreshToken: fb.refreshToken,
  };
  saveUser(user);
  return user;
}

/** Refresh an expired Firebase idToken using the stored refresh token. */
export async function refreshSession(user: User): Promise<User> {
  const res = await fetch(`https://securetoken.googleapis.com/v1/token?key=${CONFIG.firebase.apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'refresh_token', refresh_token: user.refreshToken }).toString(),
  });
  if (!res.ok) throw new Error('Session refresh failed; please sign in again.');
  const j = (await res.json()) as { id_token: string; refresh_token: string };
  const updated: User = { ...user, idToken: j.id_token, refreshToken: j.refresh_token };
  saveUser(updated);
  return updated;
}
