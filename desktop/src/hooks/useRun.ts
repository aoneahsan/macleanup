import { useState, useCallback, useRef } from 'react';
import { runClean, onLog, onDone, onError, type RunArgs, type CleanDone } from '../lib/cli';

export type RunPhase = 'idle' | 'running' | 'done' | 'error';

export interface RunState {
  phase: RunPhase;
  logs: string[];
  result: CleanDone | null;
  errorMsg: string | null;
}

export interface RunControls {
  state: RunState;
  start: (args: RunArgs) => Promise<void>;
  reset: () => void;
}

export function useRun(): RunControls {
  const [state, setState] = useState<RunState>({
    phase: 'idle',
    logs: [],
    result: null,
    errorMsg: null,
  });

  // Keep unlisten fns in a ref so we can call them on cleanup without stale closures.
  const unlistensRef = useRef<Array<() => void>>([]);

  const cleanup = useCallback(() => {
    for (const fn of unlistensRef.current) fn();
    unlistensRef.current = [];
  }, []);

  const reset = useCallback(() => {
    cleanup();
    setState({ phase: 'idle', logs: [], result: null, errorMsg: null });
  }, [cleanup]);

  const start = useCallback(async (args: RunArgs) => {
    cleanup();
    setState({ phase: 'running', logs: [], result: null, errorMsg: null });

    const unlistenLog = await onLog((line) => {
      setState((prev) => ({ ...prev, logs: [...prev.logs, line] }));
    });

    const unlistenDone = await onDone((done) => {
      setState((prev) => ({
        ...prev,
        phase: done.code === 0 ? 'done' : 'error',
        result: done,
        errorMsg: done.code !== 0 ? `Process exited with code ${done.code}` : null,
      }));
    });

    const unlistenError = await onError((msg) => {
      setState((prev) => ({
        ...prev,
        phase: 'error',
        errorMsg: msg,
      }));
    });

    unlistensRef.current = [unlistenLog, unlistenDone, unlistenError];

    try {
      await runClean(args);
    } catch (e) {
      setState((prev) => ({
        ...prev,
        phase: 'error',
        errorMsg: e instanceof Error ? e.message : String(e),
      }));
    }
  }, [cleanup]);

  return { state, start, reset };
}
