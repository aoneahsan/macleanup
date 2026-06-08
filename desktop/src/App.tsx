import { useState, useCallback } from 'react';
import { UpdateGate } from './components/UpdateGate';
import { Home } from './components/Home';
import { SectionsPage } from './components/SectionsPage';
import { AccountBar } from './components/AccountBar';
import { Settings } from './components/Settings';
import { SignInGate } from './components/SignInGate';
import { Logo } from './components/Logo';
import { loadUser, type User } from './lib/auth';
import { getEntitlement, recordRun } from './lib/entitlement';
import { useSettings } from './hooks/useSettings';

type Tab = 'home' | 'sections' | 'account' | 'settings';
type AppPhase = 'boot' | 'app';

export default function App() {
  const [appPhase, setAppPhase] = useState<AppPhase>('boot');
  const [activeTab, setActiveTab] = useState<Tab>('home');
  const [user, setUser] = useState<User | null>(() => loadUser());
  const [showSignIn, setShowSignIn] = useState(false);
  const { settings, update: updateSetting } = useSettings();

  const entitlement = getEntitlement(user);

  const handleReady = useCallback(() => {
    setAppPhase('app');
  }, []);

  const handleUserChange = useCallback((u: User | null) => {
    setUser(u);
  }, []);

  const handleSignedIn = useCallback((u: User) => {
    setUser(u);
    setShowSignIn(false);
  }, []);

  const handleNeedsSignIn = useCallback(() => {
    setShowSignIn(true);
  }, []);

  const handleCancelSignIn = useCallback(() => {
    setShowSignIn(false);
  }, []);

  const handleRecordRun = useCallback(async () => {
    await recordRun(user);
    // Refresh user state to update entitlement (anon run counter changed)
    setUser(loadUser());
  }, [user]);

  const handleSignInFromAccount = useCallback(() => {
    setShowSignIn(true);
  }, []);

  if (appPhase === 'boot') {
    return (
      <div className="app-shell">
        <div className="titlebar" data-tauri-drag-region>
          <div className="titlebar-controls" />
          <div className="titlebar-title" />
          <div className="titlebar-actions" />
        </div>
        <UpdateGate onReady={handleReady} />
      </div>
    );
  }

  return (
    <div className="app-shell">
      {/* macOS titlebar drag region */}
      <div className="titlebar" data-tauri-drag-region>
        <div className="titlebar-controls" />
        <div className="titlebar-title" data-tauri-drag-region />
        <div className="titlebar-actions" />
      </div>

      {/* Navigation */}
      <nav className="navbar">
        <Logo size={24} className="nav-logo" />
        <NavTab id="home" label="Home" active={activeTab === 'home'} onClick={() => setActiveTab('home')}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none">
            <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            <polyline points="9 22 9 12 15 12 15 22" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          Home
        </NavTab>
        <NavTab id="sections" label="Sections" active={activeTab === 'sections'} onClick={() => setActiveTab('sections')}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none">
            <rect x="3" y="3" width="7" height="7" rx="1" stroke="currentColor" strokeWidth="2"/>
            <rect x="14" y="3" width="7" height="7" rx="1" stroke="currentColor" strokeWidth="2"/>
            <rect x="3" y="14" width="7" height="7" rx="1" stroke="currentColor" strokeWidth="2"/>
            <rect x="14" y="14" width="7" height="7" rx="1" stroke="currentColor" strokeWidth="2"/>
          </svg>
          Sections
        </NavTab>
        <div className="nav-spacer" />
        <NavTab id="account" label="Account" active={activeTab === 'account'} onClick={() => setActiveTab('account')}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none">
            <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            <circle cx="12" cy="7" r="4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          Account
        </NavTab>
        <NavTab id="settings" label="Settings" active={activeTab === 'settings'} onClick={() => setActiveTab('settings')}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="2"/>
            <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83 0 2 2 0 010-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z" stroke="currentColor" strokeWidth="2"/>
          </svg>
          Settings
        </NavTab>
      </nav>

      {/* Page content */}
      <div className={`page${activeTab === 'sections' ? ' page-sections' : ''}`} style={{ display: 'flex', flexDirection: 'column', minHeight: 0 }}>
        {activeTab === 'home' && (
          <Home
            settings={settings}
            canRun={entitlement.allowed}
            onNeedsSignIn={handleNeedsSignIn}
            onNavigateSections={() => setActiveTab('sections')}
          />
        )}
        {activeTab === 'sections' && (
          <div style={{ display: 'flex', flexDirection: 'column', flex: 1, minHeight: 0 }}>
            <SectionsPage
              settings={settings}
              canRun={entitlement.allowed}
              onNeedsSignIn={handleNeedsSignIn}
              onRecordRun={handleRecordRun}
            />
          </div>
        )}
        {activeTab === 'account' && (
          <AccountBar
            user={user}
            entitlement={entitlement}
            onUserChange={handleUserChange}
            onSignIn={handleSignInFromAccount}
          />
        )}
        {activeTab === 'settings' && (
          <Settings settings={settings} onUpdate={updateSetting} />
        )}
      </div>

      {/* Sign-in gate overlay */}
      {showSignIn && (
        <div className="dialog-backdrop">
          <div className="dialog-box" style={{ maxWidth: 420 }}>
            <SignInGate
              onSignedIn={handleSignedIn}
              onCancel={handleCancelSignIn}
            />
          </div>
        </div>
      )}
    </div>
  );
}

interface NavTabProps {
  id: string;
  label: string;
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}

function NavTab({ label, active, onClick, children }: NavTabProps) {
  return (
    <button
      className={`nav-tab${active ? ' active' : ''}`}
      onClick={onClick}
      aria-current={active ? 'page' : undefined}
      aria-label={label}
    >
      {children}
    </button>
  );
}
