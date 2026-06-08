import { useEffect, useRef } from 'react';

interface LogPanelProps {
  lines: string[];
  label?: string;
  running?: boolean;
}

function classifyLine(line: string): string {
  const lower = line.toLowerCase();
  if (lower.includes('error') || lower.includes('failed') || lower.includes('fatal')) return 'error';
  if (lower.includes('warn') || lower.includes('warning')) return 'warn';
  if (lower.startsWith('  ') || lower.startsWith('\t') || line.startsWith('#')) return 'dim';
  return '';
}

export function LogPanel({ lines, label = 'Live output', running = false }: LogPanelProps) {
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = scrollRef.current;
    if (el) {
      el.scrollTop = el.scrollHeight;
    }
  }, [lines]);

  return (
    <div className="log-panel" role="log" aria-live="polite" aria-label={label}>
      <div className="log-panel-header">
        <span className="log-panel-label">{label}</span>
        {running && <div className="splash-spinner" style={{ width: 12, height: 12, borderWidth: 2 }} />}
      </div>
      <div className="log-scroll" ref={scrollRef}>
        {lines.length === 0 ? (
          <div className="log-empty">Waiting for output…</div>
        ) : (
          lines.map((line, i) => (
            <div key={i} className={`log-line ${classifyLine(line)}`}>
              {line}
            </div>
          ))
        )}
      </div>
    </div>
  );
}
