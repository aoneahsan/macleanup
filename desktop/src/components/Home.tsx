import { useState, useCallback } from 'react';
import { Logo } from './Logo';
import { RunView } from './RunView';
import { ConfirmDialog } from './ConfirmDialog';
import { ResultCard } from './ResultCard';
import { useRun } from '../hooks/useRun';
import type { AppSettings } from '../hooks/useSettings';
import { humanKb } from '../lib/format';

type HomePhase =
  | { kind: 'idle' }
  | { kind: 'dry-running' }
  | { kind: 'dry-done' }
  | { kind: 'confirm' }
  | { kind: 'running' }
  | { kind: 'done' };

interface HomeProps {
  settings: AppSettings;
  canRun: boolean;
  onNeedsSignIn: () => void;
  onNavigateSections: () => void;
}

export function Home({ settings, canRun, onNeedsSignIn, onNavigateSections }: HomeProps) {
  const [phase, setPhase] = useState<HomePhase>({ kind: 'idle' });
  const dryRun = useRun();
  const realRun = useRun();

  const extraArgs = buildExtraArgs(settings);

  const handleScanAndClean = useCallback(() => {
    if (!canRun) { onNeedsSignIn(); return; }
    dryRun.reset();
    realRun.reset();
    setPhase({ kind: 'dry-running' });
    dryRun.start({ all: true, dryRun: true, extraArgs });
  }, [canRun, onNeedsSignIn, dryRun, realRun, extraArgs]);

  const handleDryRunDone = useCallback(() => {
    if (settings.alwaysDryRunFirst) {
      setPhase({ kind: 'dry-done' });
    } else {
      setPhase({ kind: 'confirm' });
    }
  }, [settings.alwaysDryRunFirst]);

  const handleRunNow = useCallback(() => {
    if (!canRun) { onNeedsSignIn(); return; }
    setPhase({ kind: 'confirm' });
  }, [canRun, onNeedsSignIn]);

  const handleConfirmClean = useCallback(() => {
    realRun.reset();
    setPhase({ kind: 'running' });
    realRun.start({ all: true, yes: true, extraArgs });
  }, [realRun, extraArgs]);

  const handleRealDone = useCallback(() => {
    setPhase({ kind: 'done' });
  }, []);

  const handleBack = useCallback(() => {
    dryRun.reset();
    realRun.reset();
    setPhase({ kind: 'idle' });
  }, [dryRun, realRun]);

  // Dry-run is showing
  if (phase.kind === 'dry-running') {
    const { state } = dryRun;
    const isRunning = state.phase === 'running';
    // When done, auto-advance
    if (state.phase === 'done' || state.phase === 'error') {
      // Trigger phase transition on next render
      if (state.phase === 'done') {
        setTimeout(handleDryRunDone, 0);
      }
    }
    return (
      <RunView
        state={state}
        title="Dry-run Preview"
        isDryRun
        onBack={handleBack}
        onDone={!isRunning && state.phase === 'done' ? handleDryRunDone : undefined}
      />
    );
  }

  if (phase.kind === 'dry-done') {
    const summary = dryRun.state.result?.summary ?? null;
    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        <div className="flex-row" style={{ marginBottom: 4 }}>
          <button className="btn btn-ghost btn-sm" onClick={handleBack}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <path d="M19 12H5m0 0l7 7m-7-7l7-7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            Back
          </button>
          <h2 style={{ fontSize: 17, fontWeight: 700, flex: 1 }}>Preview Complete</h2>
          <span className="dry-run-label">Dry run</span>
        </div>

        {summary && (
          <div className="preview-summary-box">
            <div>
              <div className="preview-summary-label">Estimated space to free</div>
              <div className="preview-summary-value accent">{humanKb(summary.freed_kb)}</div>
            </div>
            <button className="btn btn-primary btn-lg" onClick={handleRunNow} autoFocus>
              Clean now
            </button>
          </div>
        )}

        {summary && <ResultCard summary={summary} isDryRun />}

        {!summary && (
          <div className="info-banner">No summary data returned from dry run.</div>
        )}

        <div className="flex-row" style={{ justifyContent: 'flex-end', gap: 8 }}>
          <button className="btn btn-secondary" onClick={handleBack}>Cancel</button>
          <button className="btn btn-primary btn-lg" onClick={handleRunNow}>
            Clean now
          </button>
        </div>
      </div>
    );
  }

  if (phase.kind === 'running') {
    const { state } = realRun;
    if (state.phase === 'done') {
      setTimeout(handleRealDone, 0);
    }
    return (
      <RunView
        state={state}
        title="Safe Clean"
        isDryRun={false}
        onBack={handleBack}
        onDone={state.phase === 'done' ? handleRealDone : undefined}
      />
    );
  }

  if (phase.kind === 'done') {
    const summary = realRun.state.result?.summary ?? null;
    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        <div className="flex-row" style={{ marginBottom: 4 }}>
          <h2 style={{ fontSize: 17, fontWeight: 700, flex: 1 }}>Clean Complete</h2>
          <span className="real-run-label">Done</span>
        </div>

        {summary ? (
          <ResultCard summary={summary} isDryRun={false} />
        ) : (
          <div className="info-banner">No summary returned.</div>
        )}

        <button className="btn btn-secondary" onClick={handleBack} autoFocus>
          Back to Home
        </button>
      </div>
    );
  }

  // Idle state
  return (
    <div>
      <div className="home-hero">
        <Logo size={64} className="home-logo" />
        <h1 className="home-title">macleanup</h1>
        <p className="home-tagline">Reclaim disk space. Keep your Mac fast.</p>
      </div>

      <div className="home-actions">
        <div className="home-primary-action">
          <button
            className="btn btn-primary btn-lg"
            onClick={handleScanAndClean}
            autoFocus
            style={{ width: '100%', justifyContent: 'center' }}
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
              <path d="M5 12h14M12 5l7 7-7 7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            {settings.alwaysDryRunFirst ? 'Scan & Preview (Safe)' : 'Scan & Clean (Safe)'}
          </button>
          <p className="home-action-desc">
            Runs the safe batch of {10} sections — no irreversible actions, no sudo.
            {settings.alwaysDryRunFirst && ' A dry-run preview comes first.'}
          </p>
        </div>

        <button className="home-link-btn" onClick={onNavigateSections}>
          Browse all 28 sections →
        </button>
      </div>

      {!canRun && (
        <div className="entitlement-banner danger" style={{ borderRadius: 'var(--radius-md)', padding: '12px 16px' }}>
          <span className="entitlement-banner-icon">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2"/>
              <path d="M12 8v4m0 4h.01" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
            </svg>
          </span>
          <div className="entitlement-banner-text">
            <strong>Free runs used</strong>
            Sign in to continue cleaning.
          </div>
        </div>
      )}

      {phase.kind === 'confirm' && (
        <ConfirmDialog
          title="Run Safe Clean?"
          body="This will clean safe sections including user caches, logs, temp files, update caches, and package manager caches. Some sections require your password (sudo). All changes are real — not reversible."
          confirmLabel="Clean now"
          cancelLabel="Cancel"
          onConfirm={handleConfirmClean}
          onCancel={handleBack}
        />
      )}
    </div>
  );
}

function buildExtraArgs(settings: AppSettings): string[] {
  return [
    `--cache-age-days=${settings.cacheAgeDays}`,
    `--idle-days=${settings.idleDays}`,
    `--large-file-size-gb=${settings.largeFileSizeGb}`,
  ];
}
