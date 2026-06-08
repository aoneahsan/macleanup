import { useState, useCallback } from 'react';
import { SECTIONS, GROUP_ORDER, type Section } from '../lib/sections';
import { ConfirmDialog } from './ConfirmDialog';

interface SectionListProps {
  selected: Set<number>;
  onToggle: (n: number) => void;
  onSelectAll: () => void;
  onClearAll: () => void;
}

function SectionBadges({ section }: { section: Section }) {
  return (
    <div className="section-badges">
      {section.deep && (
        <span className="badge badge-deep">
          Irreversible
        </span>
      )}
      {section.sudo && (
        <span className="badge badge-sudo">
          Requires sudo
        </span>
      )}
      {section.report && (
        <span className="badge badge-report">
          Read-only
        </span>
      )}
      {section.safeBatch && (
        <span className="badge badge-safe">
          Safe clean
        </span>
      )}
    </div>
  );
}

function SectionRow({
  section,
  isSelected,
  onToggle,
}: {
  section: Section;
  isSelected: boolean;
  onToggle: (n: number) => void;
}) {
  return (
    <div
      className={`section-row${isSelected ? ' selected' : ''}${section.deep ? ' is-deep' : ''}`}
      onClick={() => onToggle(section.n)}
      role="checkbox"
      aria-checked={isSelected}
      tabIndex={0}
      onKeyDown={(e) => { if (e.key === ' ' || e.key === 'Enter') { e.preventDefault(); onToggle(section.n); } }}
    >
      <div className="section-checkbox" aria-hidden="true">
        <svg width="10" height="8" viewBox="0 0 10 8" fill="none">
          <path d="M1 4l3 3 5-6" stroke="white" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </div>
      <div className="section-info">
        <div className="section-title">
          <span style={{ color: 'var(--text-3)', fontSize: 11, marginRight: 6 }}>#{section.n}</span>
          {section.title}
        </div>
        <div className="section-desc">{section.desc}</div>
        <SectionBadges section={section} />
      </div>
    </div>
  );
}

export function SectionList({ selected, onToggle, onSelectAll, onClearAll }: SectionListProps) {
  const [pendingDeepN, setPendingDeepN] = useState<number | null>(null);

  const handleToggle = useCallback((n: number) => {
    const section = SECTIONS.find(s => s.n === n);
    if (!section) return;
    // If selecting a deep section that isn't already selected, ask for confirm
    if (section.deep && !selected.has(n)) {
      setPendingDeepN(n);
    } else {
      onToggle(n);
    }
  }, [selected, onToggle]);

  const confirmDeep = useCallback(() => {
    if (pendingDeepN !== null) {
      onToggle(pendingDeepN);
      setPendingDeepN(null);
    }
  }, [pendingDeepN, onToggle]);

  const cancelDeep = useCallback(() => {
    setPendingDeepN(null);
  }, []);

  const deepSection = pendingDeepN !== null ? SECTIONS.find(s => s.n === pendingDeepN) : null;

  return (
    <>
      <div className="sections-header">
        <h2>All Sections</h2>
        <div className="sections-select-actions">
          <button className="btn btn-ghost btn-sm" onClick={onClearAll}>
            Clear all
          </button>
          <button className="btn btn-secondary btn-sm" onClick={onSelectAll}>
            Select all safe
          </button>
        </div>
      </div>

      {GROUP_ORDER.map((group) => {
        const groupSections = SECTIONS.filter(s => s.group === group);
        if (groupSections.length === 0) return null;
        return (
          <div key={group} className="section-group">
            <div className="section-group-title">{group}</div>
            {groupSections.map(section => (
              <SectionRow
                key={section.n}
                section={section}
                isSelected={selected.has(section.n)}
                onToggle={handleToggle}
              />
            ))}
          </div>
        );
      })}

      {pendingDeepN !== null && deepSection && (
        <ConfirmDialog
          title={`Include "${deepSection.title}"?`}
          body={`This section is marked irreversible${deepSection.sudo ? ' and requires sudo' : ''}. ${deepSection.desc} Are you sure you want to include it?`}
          confirmLabel="Yes, include it"
          cancelLabel="Cancel"
          danger
          onConfirm={confirmDeep}
          onCancel={cancelDeep}
        />
      )}
    </>
  );
}
