// Run-gating: anonymous users get CONFIG.freeRuns runs; after Google sign-in
// they get more. When auth isn't configured the app is in DEV MODE (unlimited,
// no sign-in) so the cleanup UI is fully usable before Firebase is wired.
//
// Firestore holds a per-user doc (users/{uid}) so you have a record and can
// build real plans/quotas later. Client-side gating is convenience; the
// Firestore security rules are the real server-side guard.
import { CONFIG, isConfigured } from '../config';
import { refreshSession, type User } from './auth';

const LOCAL_RUNS_KEY = 'macleanup.anonRuns';

export type Reason = 'dev-mode' | 'free-run' | 'signed-in' | 'needs-signin';

export interface Entitlement {
  allowed: boolean;
  reason: Reason;
  freeRunsLeft: number;
  signedIn: boolean;
}

function anonRunsUsed(): number {
  return parseInt(localStorage.getItem(LOCAL_RUNS_KEY) || '0', 10) || 0;
}

export function getEntitlement(user: User | null): Entitlement {
  if (!isConfigured()) {
    return { allowed: true, reason: 'dev-mode', freeRunsLeft: Number.POSITIVE_INFINITY, signedIn: false };
  }
  if (user) {
    return { allowed: true, reason: 'signed-in', freeRunsLeft: 0, signedIn: true };
  }
  const left = Math.max(0, CONFIG.freeRuns - anonRunsUsed());
  return { allowed: left > 0, reason: left > 0 ? 'free-run' : 'needs-signin', freeRunsLeft: left, signedIn: false };
}

const docPath = (uid: string) =>
  `projects/${CONFIG.firebase.projectId}/databases/(default)/documents/users/${uid}`;
const docUrl = (uid: string) => `https://firestore.googleapis.com/v1/${docPath(uid)}`;
const commitUrl = () =>
  `https://firestore.googleapis.com/v1/projects/${CONFIG.firebase.projectId}/databases/(default)/documents:commit`;

/** Create/merge the user's Firestore doc on sign-in (best-effort). */
export async function ensureUserDoc(user: User): Promise<void> {
  if (!isConfigured()) return;
  try {
    await fetch(`${docUrl(user.uid)}?updateMask.fieldPaths=email&updateMask.fieldPaths=displayName`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.idToken}` },
      body: JSON.stringify({
        fields: {
          email: { stringValue: user.email },
          displayName: { stringValue: user.displayName },
        },
      }),
    });
  } catch {
    /* non-fatal */
  }
}

/** Record a completed run: anon → local counter; signed-in → Firestore increment. */
export async function recordRun(user: User | null): Promise<void> {
  if (!isConfigured()) return;
  if (!user) {
    localStorage.setItem(LOCAL_RUNS_KEY, String(anonRunsUsed() + 1));
    return;
  }
  const commit = (tok: string) =>
    fetch(commitUrl(), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tok}` },
      body: JSON.stringify({
        writes: [
          {
            transform: {
              document: docPath(user.uid),
              fieldTransforms: [
                { fieldPath: 'runs', increment: { integerValue: '1' } },
                { fieldPath: 'lastRunAt', setToServerValue: 'REQUEST_TIME' },
              ],
            },
          },
        ],
      }),
    });
  try {
    let res = await commit(user.idToken);
    if (res.status === 401) {
      const u = await refreshSession(user);
      res = await commit(u.idToken);
    }
  } catch {
    /* never block a finished run on telemetry */
  }
}
