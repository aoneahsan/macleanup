import { useState, useCallback } from 'react';

export interface AppSettings {
  cacheAgeDays: number;
  idleDays: number;
  largeFileSizeGb: number;
  alwaysDryRunFirst: boolean;
}

const SETTINGS_KEY = 'macleanup.settings';

const DEFAULT_SETTINGS: AppSettings = {
  cacheAgeDays: 30,
  idleDays: 90,
  largeFileSizeGb: 5,
  alwaysDryRunFirst: true,
};

function loadSettings(): AppSettings {
  try {
    const raw = localStorage.getItem(SETTINGS_KEY);
    if (!raw) return { ...DEFAULT_SETTINGS };
    return { ...DEFAULT_SETTINGS, ...(JSON.parse(raw) as Partial<AppSettings>) };
  } catch {
    return { ...DEFAULT_SETTINGS };
  }
}

export function useSettings() {
  const [settings, setSettings] = useState<AppSettings>(loadSettings);

  const update = useCallback(<K extends keyof AppSettings>(key: K, value: AppSettings[K]) => {
    setSettings((prev) => {
      const next = { ...prev, [key]: value };
      localStorage.setItem(SETTINGS_KEY, JSON.stringify(next));
      return next;
    });
  }, []);

  return { settings, update };
}
