import { humanKb, humanDuration } from '../lib/format';
import { sectionByN } from '../lib/sections';
import type { CleanSummary } from '../lib/cli';

interface ResultCardProps {
  summary: CleanSummary;
  isDryRun?: boolean;
}

export function ResultCard({ summary, isDryRun }: ResultCardProps) {
  const freedLabel = isDryRun ? 'Would free' : 'Freed';
  const deltaLabel = isDryRun ? 'Projected delta' : 'Disk delta';

  return (
    <div className="result-card">
      <div className="result-card-title">
        {isDryRun ? (
          <span className="dry-run-label">Dry-run Preview</span>
        ) : (
          <span className="real-run-label">Completed</span>
        )}
        <span>Results</span>
      </div>

      <div className="result-stats">
        <div className="result-stat">
          <div className="result-stat-label">{freedLabel}</div>
          <div className={`result-stat-value ${isDryRun ? 'accent' : 'success'}`}>
            {humanKb(summary.freed_kb)}
          </div>
        </div>
        {summary.disk_free_delta_kb !== 0 && (
          <div className="result-stat">
            <div className="result-stat-label">{deltaLabel}</div>
            <div className="result-stat-value accent">
              {humanKb(Math.abs(summary.disk_free_delta_kb))}
            </div>
          </div>
        )}
        <div className="result-stat">
          <div className="result-stat-label">Elapsed</div>
          <div className="result-stat-value">{humanDuration(summary.elapsed_s)}</div>
        </div>
        <div className="result-stat">
          <div className="result-stat-label">Sections</div>
          <div className="result-stat-value">{summary.sections_done.length}</div>
        </div>
      </div>

      {summary.sections_done.length > 0 && (
        <div>
          <div className="result-stat-label" style={{ marginBottom: 6 }}>Sections cleaned</div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
            {summary.sections_done.map((n) => {
              const sec = sectionByN(n);
              return (
                <span key={n} className="badge badge-safe">
                  {sec ? sec.title : `#${n}`}
                </span>
              );
            })}
          </div>
        </div>
      )}

      {summary.reports.length > 0 && (
        <div className="result-reports">
          <div className="result-report-label">Report files</div>
          {summary.reports.map((r, i) => (
            <div key={i} className="result-report-path">{r}</div>
          ))}
        </div>
      )}

      {summary.log_file && (
        <div className="result-reports">
          <div className="result-report-label">Log file</div>
          <div className="result-report-path">{summary.log_file}</div>
        </div>
      )}
    </div>
  );
}
