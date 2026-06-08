// The 28 cleanup sections (0–27), mirrored from mac-cleanup.sh's
// SECTION_CATALOGUE, with UI grouping + safety metadata. Single source of
// truth for the GUI. Keep in sync with the script.

export type Group =
  | 'Overview'
  | 'Caches'
  | 'Developer'
  | 'Logs & Temp'
  | 'System'
  | 'Apps & Data'
  | 'Reports';

export interface Section {
  n: number;
  title: string;
  desc: string;
  group: Group;
  /** Requires sudo (the app will surface a password note). */
  sudo?: boolean;
  /** Deepest, irreversible — gated behind explicit confirm + --i-understand-deep. */
  deep?: boolean;
  /** Read-only / advisory (never deletes). */
  report?: boolean;
  /** Part of the one-click Safe Clean batch (--all). */
  safeBatch?: boolean;
}

/** Sections that `--all` runs unattended (mirrors SAFE_BATCH in the script). */
export const SAFE_BATCH = [0, 3, 5, 7, 8, 9, 15, 18, 22, 26];
/** Deepest destructive sections (mirrors DEEP_INTERACTIVE_SECTIONS). */
export const DEEP_SECTIONS = [6, 11, 14, 21, 24];

export const SECTIONS: Section[] = [
  { n: 0, title: 'System health & process monitor', desc: 'Read-only snapshot: macOS, RAM, disk, CPU/mem hogs, battery, SMART.', group: 'Overview', report: true, safeBatch: true },
  { n: 1, title: 'Xcode caches, DerivedData, simulators', desc: 'Prune Xcode build caches & unavailable simulators (age-aware).', group: 'Developer' },
  { n: 2, title: 'Android / Gradle caches', desc: 'Prune Gradle & Android build caches unused for a while.', group: 'Developer' },
  { n: 3, title: 'Package-manager caches', desc: 'npm, yarn, pnpm, brew, pip, pod, cargo, go, ruby, Bun, Deno, uv, Composer…', group: 'Developer', safeBatch: true },
  { n: 4, title: 'Docker prune', desc: 'Remove unused images/containers/networks (volumes are opt-in only).', group: 'Developer' },
  { n: 5, title: 'User caches', desc: '~/Library/Caches, Saved State, DiagnosticReports (browsers & password managers preserved).', group: 'Caches', safeBatch: true },
  { n: 6, title: 'System caches (/Library/Caches)', desc: 'Clear non-Apple system caches. Runs as root.', group: 'System', sudo: true, deep: true },
  { n: 7, title: 'Logs (user + system)', desc: 'Prune old user & system logs.', group: 'Logs & Temp', sudo: true, safeBatch: true },
  { n: 8, title: 'Temp files', desc: '$TMPDIR, /tmp, ~/tmp — old, user-owned only.', group: 'Logs & Temp', safeBatch: true },
  { n: 9, title: 'Update caches', desc: 'Clear downloaded OS/app update caches.', group: 'Caches', sudo: true, safeBatch: true },
  { n: 10, title: 'Empty Trash', desc: 'Empty home Trash + external-volume trashes. Irreversible.', group: 'Apps & Data' },
  { n: 11, title: 'Time Machine local snapshots', desc: 'Delete local APFS snapshots. Runs as root.', group: 'System', sudo: true, deep: true },
  { n: 12, title: 'Orphaned app data scan', desc: 'Find leftover data from uninstalled apps (idle ≥ threshold). Moves to Trash.', group: 'Apps & Data' },
  { n: 13, title: 'System maintenance (periodic)', desc: 'Run macOS daily/weekly/monthly periodic scripts. Runs as root.', group: 'System', sudo: true },
  { n: 14, title: 'Deep cache /private/var/folders', desc: 'Full wipe of the per-user temp/cache state. Needs REBOOT. Runs as root.', group: 'System', sudo: true, deep: true },
  { n: 15, title: 'Installer leftovers report', desc: 'Advisory: find macOS installers & leftover system folders.', group: 'Reports', report: true, safeBatch: true },
  { n: 16, title: 'iOS / iPadOS device backups', desc: 'Review device backups + sweep old .ipsw downloads.', group: 'Apps & Data' },
  { n: 17, title: 'Xcode archives', desc: 'Review & delete old .xcarchive build archives.', group: 'Developer' },
  { n: 18, title: 'Large files report', desc: 'Advisory: biggest files in your home folder.', group: 'Reports', report: true, safeBatch: true },
  { n: 19, title: 'Browser caches', desc: 'Chrome, Brave, Edge, Vivaldi, Opera, Arc, Firefox & forks — all profiles.', group: 'Caches' },
  { n: 20, title: 'DNS / mDNS reset', desc: 'Flush DNS cache & renew DHCP. Runs as root.', group: 'System', sudo: true },
  { n: 21, title: 'Apps unused N+ days', desc: 'Review & uninstall idle apps + their data. Moves to Trash.', group: 'Apps & Data', deep: true },
  { n: 22, title: 'Purgeable space trigger', desc: 'Nudge macOS to release purgeable space.', group: 'System', safeBatch: true },
  { n: 23, title: 'Stale build artefacts', desc: 'Old node_modules, vendor, dist, target… in your dev folders.', group: 'Developer' },
  { n: 24, title: 'Large stale files', desc: 'Big files unused for a long time → Trash.', group: 'Apps & Data', deep: true },
  { n: 25, title: 'LaunchAgents / LaunchDaemons audit', desc: 'Find & remove orphaned login items.', group: 'System' },
  { n: 26, title: 'Disk usage report', desc: 'Advisory: heaviest folders in $HOME & ~/Library.', group: 'Reports', report: true, safeBatch: true },
  { n: 27, title: 'macOS UI maintenance', desc: 'Reset QuickLook thumbnail cache & font caches.', group: 'Caches' },
];

export const sectionByN = (n: number): Section | undefined => SECTIONS.find((s) => s.n === n);

export const GROUP_ORDER: Group[] = [
  'Overview',
  'Caches',
  'Developer',
  'Logs & Temp',
  'System',
  'Apps & Data',
  'Reports',
];
