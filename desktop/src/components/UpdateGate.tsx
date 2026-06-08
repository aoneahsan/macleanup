import { useState, useEffect } from 'react';
import type { Update } from '@tauri-apps/plugin-updater';
import { checkForUpdate, installAndRelaunch, type UpdatePhase } from '../lib/updater';
import { Logo } from './Logo';
import { Spinner } from './Spinner';

interface UpdateGateProps {
  onReady: () => void;
}

type GateState =
  | { kind: 'checking' }
  | { kind: 'ready' }
  | { kind: 'available'; update: Update; version: string; notes?: string }
  | { kind: 'downloading'; pct: number; update: Update }
  | { kind: 'installing' }
  | { kind: 'error'; message: string };

export function UpdateGate({ onReady }: UpdateGateProps) {
  const [gateState, setGateState] = useState<GateState>({ kind: 'checking' });

  useEffect(() => {
    let mounted = true;

    const handlePhase = (p: UpdatePhase) => {
      if (!mounted) return;
      switch (p.phase) {
        case 'checking':
          setGateState({ kind: 'checking' });
          break;
        case 'up-to-date':
        case 'error':
          // Fail open — let the app proceed
          setGateState({ kind: 'ready' });
          break;
        default:
          break;
      }
    };

    checkForUpdate(handlePhase).then((update) => {
      if (!mounted) return;
      if (!update) {
        setGateState({ kind: 'ready' });
      } else {
        setGateState({ kind: 'available', update, version: update.version, notes: update.body });
      }
    });

    return () => { mounted = false; };
  }, []);

  // When state becomes 'ready', call onReady after a tiny tick so the splash animates.
  useEffect(() => {
    if (gateState.kind === 'ready') {
      const t = setTimeout(onReady, 100);
      return () => clearTimeout(t);
    }
  }, [gateState, onReady]);

  const startInstall = async (update: Update) => {
    const onPhase = (p: UpdatePhase) => {
      if (p.phase === 'downloading') {
        setGateState({ kind: 'downloading', pct: p.pct, update });
      } else if (p.phase === 'installing') {
        setGateState({ kind: 'installing' });
      }
    };
    await installAndRelaunch(update, onPhase);
  };

  if (gateState.kind === 'checking') {
    return (
      <div className="splash">
        <Logo size={72} className="splash-logo" />
        <div className="splash-title">macleanup</div>
        <div className="splash-sub">Checking for updates…</div>
        <Spinner size={24} />
      </div>
    );
  }

  if (gateState.kind === 'available') {
    return (
      <div className="splash">
        <Logo size={72} className="splash-logo" />
        <div className="update-gate">
          <div className="splash-title">Update available</div>
          <div className="update-version-badge">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
              <path d="M12 2v10m0 0l-3-3m3 3l3-3M3 17v2a2 2 0 002 2h14a2 2 0 002-2v-2" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            v{gateState.version}
          </div>
          {gateState.notes && (
            <div className="update-notes">{gateState.notes}</div>
          )}
          <p className="splash-sub">
            An update is required before using macleanup. The app will relaunch automatically after installation.
          </p>
          <button
            className="btn btn-primary btn-lg"
            onClick={() => startInstall(gateState.update)}
            autoFocus
          >
            Install &amp; Relaunch
          </button>
        </div>
      </div>
    );
  }

  if (gateState.kind === 'downloading') {
    return (
      <div className="splash">
        <Logo size={72} className="splash-logo" />
        <div className="update-gate">
          <div className="splash-title">Downloading update…</div>
          <div className="progress-bar-wrap" style={{ width: '100%' }}>
            <div className="progress-bar-fill" style={{ width: `${gateState.pct}%` }} />
          </div>
          <div className="splash-sub">{gateState.pct}%</div>
        </div>
      </div>
    );
  }

  if (gateState.kind === 'installing') {
    return (
      <div className="splash">
        <Logo size={72} className="splash-logo" />
        <div className="splash-title">Installing…</div>
        <div className="splash-sub">The app will relaunch in a moment.</div>
        <Spinner size={24} />
      </div>
    );
  }

  // 'ready' — rendered briefly, then onReady fires
  return (
    <div className="splash">
      <Logo size={72} className="splash-logo" />
      <div className="splash-title">macleanup</div>
      <Spinner size={24} />
    </div>
  );
}
