import { signOut, type User } from '../lib/auth';
import type { Entitlement } from '../lib/entitlement';

interface AccountBarProps {
  user: User | null;
  entitlement: Entitlement;
  onUserChange: (user: User | null) => void;
  onSignIn: () => void;
}

export function AccountBar({ user, entitlement, onUserChange, onSignIn }: AccountBarProps) {
  const handleSignOut = () => {
    signOut();
    onUserChange(null);
  };

  return (
    <div className="account-page">
      {/* User card */}
      <div className="account-card">
        <div className="account-user-row">
          <div className="account-avatar">
            {user?.photoUrl ? (
              <img src={user.photoUrl} alt={user.displayName} />
            ) : (
              <div className="account-avatar-placeholder">
                {user ? user.displayName.charAt(0).toUpperCase() : '?'}
              </div>
            )}
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            {user ? (
              <>
                <div className="account-name">{user.displayName}</div>
                <div className="account-email">{user.email}</div>
              </>
            ) : (
              <>
                <div className="account-name">Not signed in</div>
                <div className="account-email">Anonymous user</div>
              </>
            )}
          </div>
          {user ? (
            <button className="btn btn-secondary btn-sm" onClick={handleSignOut}>
              Sign out
            </button>
          ) : (
            <button className="btn btn-primary btn-sm" onClick={onSignIn}>
              Sign in
            </button>
          )}
        </div>

        <EntitlementBanner entitlement={entitlement} />
      </div>
    </div>
  );
}

function EntitlementBanner({ entitlement }: { entitlement: Entitlement }) {
  if (entitlement.reason === 'dev-mode') {
    return (
      <div className="entitlement-banner dev">
        <span className="entitlement-banner-icon">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
            <path d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </span>
        <div className="entitlement-banner-text">
          <strong>Dev mode — unlimited runs</strong>
          Auth is not configured. Add Firebase + Google OAuth config in <code>src/config.ts</code> to enable sign-in gating.
        </div>
      </div>
    );
  }

  if (entitlement.reason === 'signed-in') {
    return (
      <div className="entitlement-banner ok">
        <span className="entitlement-banner-icon">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
            <path d="M20 6L9 17l-5-5" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </span>
        <div className="entitlement-banner-text">
          <strong>Unlimited runs</strong>
          You're signed in — all sections available.
        </div>
      </div>
    );
  }

  if (entitlement.reason === 'free-run') {
    const left = entitlement.freeRunsLeft;
    return (
      <div className="entitlement-banner warn">
        <span className="entitlement-banner-icon">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
            <path d="M12 9v4m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </span>
        <div className="entitlement-banner-text">
          <strong>{left} free run{left !== 1 ? 's' : ''} remaining</strong>
          Sign in with Google after that to keep cleaning.
        </div>
      </div>
    );
  }

  return (
    <div className="entitlement-banner danger">
      <span className="entitlement-banner-icon">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2"/>
          <path d="M12 8v4m0 4h.01" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
        </svg>
      </span>
      <div className="entitlement-banner-text">
        <strong>Free runs used</strong>
        Sign in with Google to continue running cleanups.
      </div>
    </div>
  );
}
