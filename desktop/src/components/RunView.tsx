import { useEffect } from 'react';
import { LogPanel } from './LogPanel';
import { ResultCard } from './ResultCard';
import { Spinner } from './Spinner';
import type { RunState } from '../hooks/useRun';

interface RunViewProps {
  state: RunState;
  title: string;
  isDryRun?: boolean;
  onBack: () => void;
  onDone?: () => void;
}

export function RunView({ state, title, isDryRun = false, onBack, onDone }: RunViewProps) {
  const { phase, logs, result, errorMsg } = state;

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && phase !== 'running') onBack();
    };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [phase, onBack]);

  const statusDotClass = phase === 'running' ? 'running' : phase === 'done' ? 'done' : phase === 'error' ? 'error' : '';

  const statusText =
    phase === 'running' ? 'Running…' :
    phase === 'done' ? 'Complete' :
    phase === 'error' ? 'Error' :
    'Idle';

  return (
    <div className="run-view">
      <div className="run-header">
        <button className="btn btn-ghost btn-sm" onClick={onBack} disabled={phase === 'running'} aria-label="Back">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
            <path d="M19 12H5m0 0l7 7m-7-7l7-7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          Back
        </button>
        <h2>{title}</h2>
        {isDryRun && <span className="dry-run-label">Dry run</span>}
        <div className="run-status">
          <div className={`run-status-dot ${statusDotClass}`} />
          {statusText}
          {phase === 'running' && <Spinner size={14} />}
        </div>
      </div>

      <LogPanel lines={logs} running={phase === 'running'} label={isDryRun ? 'Dry-run output' : 'Live output'} />

      {errorMsg && (
        <div className="error-banner" style={{ marginTop: 12, flexShrink: 0 }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" style={{ flexShrink: 0 }}>
            <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2"/>
            <path d="M12 8v4m0 4h.01" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
          </svg>
          {errorMsg}
        </div>
      )}

      {phase === 'done' && result?.summary && (
        <div style={{ marginTop: 12, flexShrink: 0 }}>
          <ResultCard summary={result.summary} isDryRun={isDryRun} />
        </div>
      )}

      {phase === 'done' && onDone && (
        <div style={{ marginTop: 12, flexShrink: 0, display: 'flex', gap: 8 }}>
          <button className="btn btn-secondary" onClick={onBack}>
            Back
          </button>
          <button className="btn btn-primary" onClick={onDone} autoFocus>
            Continue
          </button>
        </div>
      )}

      {phase !== 'running' && !onDone && (
        <div style={{ marginTop: 12, flexShrink: 0 }}>
          <button className="btn btn-secondary" onClick={onBack}>
            Back
          </button>
        </div>
      )}
    </div>
  );
}
