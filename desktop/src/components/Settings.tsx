import { useEffect, useState } from 'react';
import { open } from '@tauri-apps/plugin-shell';
import { appVersion } from '../lib/cli';
import type { AppSettings } from '../hooks/useSettings';

const FDA_URL = 'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles';

interface SettingsProps {
  settings: AppSettings;
  onUpdate: <K extends keyof AppSettings>(key: K, value: AppSettings[K]) => void;
}

export function Settings({ settings, onUpdate }: SettingsProps) {
  const [version, setVersion] = useState<string>('');

  useEffect(() => {
    appVersion().then(setVersion).catch(() => setVersion('—'));
  }, []);

  return (
    <div className="settings-page">
      <div style={{ marginBottom: 4 }}>
        <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--text)' }}>Settings</h2>
        <p style={{ fontSize: 13, color: 'var(--text-3)', marginTop: 4 }}>
          Thresholds are passed as extra arguments to the cleanup CLI.
        </p>
      </div>

      <div className="settings-section">
        <div className="settings-section-title">Behaviour</div>

        <div className="settings-row">
          <label className="settings-row-label" htmlFor="toggle-dry-run-first">
            <div className="settings-row-label-text">Always dry-run first</div>
            <div className="settings-row-label-desc">Preview what would be freed before any real clean.</div>
          </label>
          <label className="settings-toggle">
            <input
              id="toggle-dry-run-first"
              type="checkbox"
              checked={settings.alwaysDryRunFirst}
              onChange={(e) => onUpdate('alwaysDryRunFirst', e.target.checked)}
            />
            <span className="settings-toggle-track" aria-hidden="true" />
          </label>
        </div>
      </div>

      <div className="settings-section">
        <div className="settings-section-title">Thresholds</div>

        <div className="settings-row">
          <label className="settings-row-label" htmlFor="input-cache-age">
            <div className="settings-row-label-text">Cache age (days)</div>
            <div className="settings-row-label-desc">--cache-age-days: skip caches newer than this.</div>
          </label>
          <input
            id="input-cache-age"
            className="settings-input"
            type="number"
            min={1}
            max={365}
            value={settings.cacheAgeDays}
            onChange={(e) => onUpdate('cacheAgeDays', Math.max(1, parseInt(e.target.value, 10) || 1))}
          />
        </div>

        <div className="settings-row">
          <label className="settings-row-label" htmlFor="input-idle-days">
            <div className="settings-row-label-text">Idle days</div>
            <div className="settings-row-label-desc">--idle-days: apps/files unused for this long are flagged.</div>
          </label>
          <input
            id="input-idle-days"
            className="settings-input"
            type="number"
            min={1}
            max={730}
            value={settings.idleDays}
            onChange={(e) => onUpdate('idleDays', Math.max(1, parseInt(e.target.value, 10) || 1))}
          />
        </div>

        <div className="settings-row">
          <label className="settings-row-label" htmlFor="input-large-file-gb">
            <div className="settings-row-label-text">Large file size (GB)</div>
            <div className="settings-row-label-desc">--large-file-size-gb: files bigger than this are candidates.</div>
          </label>
          <input
            id="input-large-file-gb"
            className="settings-input"
            type="number"
            min={1}
            max={100}
            value={settings.largeFileSizeGb}
            onChange={(e) => onUpdate('largeFileSizeGb', Math.max(1, parseInt(e.target.value, 10) || 1))}
          />
        </div>
      </div>

      <div className="settings-section">
        <div className="settings-section-title">System access</div>

        <div className="settings-row">
          <label className="settings-row-label">
            <div className="settings-row-label-text">Administrator access</div>
            <div className="settings-row-label-desc">
              Cleaning system-level files (system caches, logs, periodic maintenance, DNS,
              snapshots) asks for your macOS password <strong>once per run</strong> via a native
              dialog. Previews never ask.
            </div>
          </label>
        </div>

        <div className="settings-row">
          <label className="settings-row-label">
            <div className="settings-row-label-text">Full Disk Access</div>
            <div className="settings-row-label-desc">
              For the deepest cleanups, grant macleanup Full Disk Access once in System Settings,
              then relaunch the app.
            </div>
          </label>
          <button
            className="btn btn-secondary"
            onClick={() => { void open(FDA_URL); }}
          >
            Open settings
          </button>
        </div>
      </div>

      {version && (
        <div className="settings-app-version">
          macleanup v{version}
        </div>
      )}
    </div>
  );
}
