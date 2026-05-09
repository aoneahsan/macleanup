# Security policy

`mac-cleanup` runs `rm -rf`, `sudo`, and AppleScript Trash moves against
your machine. Even small bugs can have outsized impact, so security
reports are taken seriously.

## Reporting a vulnerability

**Please do not open a public GitHub issue for security problems.**

Email <aoneahsan@gmail.com> with:

1. A short description of the problem class
   (path traversal, accidental `rm -rf`, command injection, sudo escape,
   data leak in logs/reports, etc.).
2. Steps to reproduce — ideally a minimal command line, environment
   description, and the observed vs. expected behaviour.
3. Impact assessment from your perspective (loss of data, privilege
   escalation, etc.).
4. Whether you'd like to be credited in the changelog when a fix ships.

You will receive an acknowledgement within **5 working days** in most
cases. There is no formal SLA — this is a single-author project — but
critical issues will be triaged ahead of feature work.

## What's in scope

- Anything in `mac-cleanup.sh` that could:
  - Delete files outside the intended target.
  - Bypass the `--dry-run` guarantee.
  - Inject shell or AppleScript through a crafted filename / bundle ID.
  - Leak personal data into logs that the user did not opt into.
  - Run unintended `sudo` commands.

## What's out of scope

- `rm`-ing files that the user explicitly selected and confirmed.
- Permission errors when running without `sudo` on system paths.
- Issues caused by the user editing the script (modification is not
  permitted by the license, but obviously a forked / patched copy is on
  the user, not on upstream).
- Bug reports for third-party tools the script invokes
  (`brew`, `npm`, `docker`, `xcrun`, `tmutil`, `mdls`, etc.).

## Coordinated disclosure

If a fix requires non-trivial work, the author may ask you to hold
public disclosure for up to **30 days** while a patch is prepared and
released. After that window you are free to publish your findings.
Credit (if you want it) lands in the matching CHANGELOG entry and, for
notable issues, in a brief Security note in the README.

## Defensive guidance for users

- Read the script. It's one file; that's deliberate.
- Always run `--dry-run` for any destructive section the first time.
- Keep an active Time Machine target (or a `tmutil snapshot`) before
  running unattended `--all --yes` on machines you care about.
- Inspect the dated reports in `logs/` before deciding what to remove.
