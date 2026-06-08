import { useState, useCallback } from 'react';
import { SECTIONS, SAFE_BATCH } from '../lib/sections';
import { SectionList } from './SectionList';
import { RunView } from './RunView';
import { ResultCard } from './ResultCard';
import { ConfirmDialog } from './ConfirmDialog';
import { useRun } from '../hooks/useRun';
import type { AppSettings } from '../hooks/useSettings';
import { humanKb } from '../lib/format';
import { buildExtraArgs } from '../lib/runargs';

type SectionsPhase =
  | { kind: 'browse' }
  | { kind: 'dry-running' }
  | { kind: 'dry-done' }
  | { kind: 'confirm-deep' }
  | { kind: 'confirm-run' }
  | { kind: 'running' }
  | { kind: 'done' };

interface SectionsPageProps {
  settings: AppSettings;
  canRun: boolean;
  onNeedsSignIn: () => void;
  onRecordRun: () => void;
}

export function SectionsPage({ settings, canRun, onNeedsSignIn, onRecordRun }: SectionsPageProps) {
  const [selected, setSelected] = useState<Set<number>>(new Set(SAFE_BATCH));
  const [phase, setPhase] = useState<SectionsPhase>({ kind: 'browse' });
  const dryRun = useRun();
  const realRun = useRun();

  const extraArgs = buildExtraArgs(settings);

  const anyDeepSelected = SECTIONS.some(s => s.deep && selected.has(s.n));

  const handleToggle = useCallback((n: number) => {
    setSelected(prev => {
      const next = new Set(prev);
      if (next.has(n)) next.delete(n); else next.add(n);
      return next;
    });
  }, []);

  const handleSelectAllSafe = useCallback(() => {
    setSelected(new Set(SAFE_BATCH));
  }, []);

  const handleClearAll = useCallback(() => {
    setSelected(new Set());
  }, []);

  const sectionsArg = [...selected].sort((a, b) => a - b).join(',');

  const handleDryRun = useCallback(() => {
    if (selected.size === 0) return;
    dryRun.reset();
    realRun.reset();
    if (anyDeepSelected) {
      setPhase({ kind: 'confirm-deep' });
    } else {
      setPhase({ kind: 'dry-running' });
      dryRun.start({ sections: sectionsArg, dryRun: true, understandDeep: false, extraArgs });
    }
  }, [selected, dryRun, realRun, anyDeepSelected, sectionsArg, extraArgs]);

  const handleConfirmDeep = useCallback(() => {
    setPhase({ kind: 'dry-running' });
    dryRun.start({ sections: sectionsArg, dryRun: true, understandDeep: true, extraArgs });
  }, [dryRun, sectionsArg, extraArgs]);

  const handleDryDone = useCallback(() => {
    setPhase({ kind: 'dry-done' });
  }, []);

  const handleRunNow = useCallback(() => {
    if (!canRun) { onNeedsSignIn(); return; }
    setPhase({ kind: 'confirm-run' });
  }, [canRun, onNeedsSignIn]);

  const handleConfirmRun = useCallback(() => {
    realRun.reset();
    setPhase({ kind: 'running' });
    realRun.start({ sections: sectionsArg, yes: true, understandDeep: anyDeepSelected, extraArgs });
  }, [realRun, sectionsArg, anyDeepSelected, extraArgs]);

  const handleRealDone = useCallback(() => {
    onRecordRun();
    setPhase({ kind: 'done' });
  }, [onRecordRun]);

  const handleBack = useCallback(() => {
    dryRun.reset();
    realRun.reset();
    setPhase({ kind: 'browse' });
  }, [dryRun, realRun]);

  if (phase.kind === 'confirm-deep') {
    const deepNames = SECTIONS.filter(s => s.deep && selected.has(s.n)).map(s => s.title);
    return (
      <ConfirmDialog
        title="Irreversible sections selected"
        body={`You've selected irreversible sections: ${deepNames.join(', ')}. These actions CANNOT be undone and may require a reboot. Proceeding will pass --i-understand-deep to the CLI. Continue to dry-run preview?`}
        confirmLabel="Yes, I understand — dry run first"
        cancelLabel="Cancel"
        danger
        onConfirm={handleConfirmDeep}
        onCancel={() => setPhase({ kind: 'browse' })}
      />
    );
  }

  if (phase.kind === 'dry-running') {
    const { state } = dryRun;
    if (state.phase === 'done') setTimeout(handleDryDone, 0);
    return (
      <RunView
        state={state}
        title={`Dry-run — ${selected.size} section${selected.size !== 1 ? 's' : ''}`}
        isDryRun
        onBack={handleBack}
        onDone={state.phase === 'done' ? handleDryDone : undefined}
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
              Run selected
            </button>
          </div>
        )}

        {summary && <ResultCard summary={summary} isDryRun />}

        {anyDeepSelected && (
          <div className="error-banner">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" style={{ flexShrink: 0 }}>
              <path d="M12 9v4m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            Selection includes irreversible sections. The real run CANNOT be undone.
          </div>
        )}

        <div className="flex-row" style={{ justifyContent: 'flex-end', gap: 8 }}>
          <button className="btn btn-secondary" onClick={handleBack}>Cancel</button>
          <button className={`btn btn-lg ${anyDeepSelected ? 'btn-danger' : 'btn-primary'}`} onClick={handleRunNow}>
            {anyDeepSelected ? 'Run selected (irreversible)' : 'Run selected'}
          </button>
        </div>
      </div>
    );
  }

  if (phase.kind === 'confirm-run') {
    const deepNames = anyDeepSelected
      ? SECTIONS.filter(s => s.deep && selected.has(s.n)).map(s => s.title)
      : [];
    return (
      <ConfirmDialog
        title="Run selected sections?"
        body={anyDeepSelected
          ? `This will run ${selected.size} section(s) including IRREVERSIBLE actions: ${deepNames.join(', ')}. This CANNOT be undone.`
          : `This will run ${selected.size} section(s) for real. All changes will be applied immediately.`}
        confirmLabel="Run now"
        cancelLabel="Cancel"
        danger={anyDeepSelected}
        onConfirm={handleConfirmRun}
        onCancel={() => setPhase({ kind: 'dry-done' })}
      />
    );
  }

  if (phase.kind === 'running') {
    const { state } = realRun;
    if (state.phase === 'done') setTimeout(handleRealDone, 0);
    return (
      <RunView
        state={state}
        title={`Running — ${selected.size} section${selected.size !== 1 ? 's' : ''}`}
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
        {summary ? <ResultCard summary={summary} isDryRun={false} /> : <div className="info-banner">No summary returned.</div>}
        <button className="btn btn-secondary" onClick={handleBack} autoFocus>
          Back to Sections
        </button>
      </div>
    );
  }

  // Browse
  return (
    <>
      <SectionList
        selected={selected}
        onToggle={handleToggle}
        onSelectAll={handleSelectAllSafe}
        onClearAll={handleClearAll}
      />

      <div className="sections-toolbar">
        <div className="sections-toolbar-info">
          <strong>{selected.size}</strong> section{selected.size !== 1 ? 's' : ''} selected
          {anyDeepSelected && (
            <span className="text-danger" style={{ marginLeft: 8 }}>
              · includes irreversible actions
            </span>
          )}
        </div>
        <button
          className="btn btn-secondary"
          onClick={handleDryRun}
          disabled={selected.size === 0}
        >
          Dry-run preview
        </button>
        <button
          className={`btn ${anyDeepSelected ? 'btn-danger' : 'btn-primary'}`}
          onClick={handleRunNow}
          disabled={selected.size === 0}
        >
          {anyDeepSelected ? 'Run selected (irreversible)' : 'Run selected'}
        </button>
      </div>
    </>
  );
}

