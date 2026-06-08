// Prevents an extra console window on Windows in release. Harmless on macOS.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

//! macleanup desktop — Rust backend.
//!
//! Thin, safe wrapper around the bundled `mac-cleanup.sh`. The Rust layer:
//!   * resolves + runs the bundled CLI in `--json` mode,
//!   * streams the human log (stderr) to the UI line-by-line via events,
//!   * captures the machine-readable JSON summary (stdout) and emits it on done,
//!   * provides a localhost loopback listener for the Google OAuth redirect
//!     (Google forbids OAuth inside embedded webviews, so we use the system
//!     browser + a loopback redirect).
//!
//! All cleanup logic, safety rules, and the 28 sections live in the shell
//! script — this binary never reimplements any of it.

use std::io::{BufRead, BufReader, Read, Write};
use std::process::{Command, Stdio};

use serde::{Deserialize, Serialize};
use tauri::{AppHandle, Emitter, Manager};

/// Arguments for a cleanup run, mirrored from the CLI flags.
#[derive(Debug, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
struct RunArgs {
    /// Comma-separated section list, e.g. "5,7,8". Ignored when `all` is true.
    #[serde(default)]
    sections: Option<String>,
    /// Run the safe batch (`--all`).
    #[serde(default)]
    all: bool,
    /// Preview only (`--dry-run`) — never touches disk.
    #[serde(default)]
    dry_run: bool,
    /// Auto-confirm prompts (`--yes`).
    #[serde(default)]
    yes: bool,
    /// Allow the deepest destructive sections unattended (`--i-understand-deep`).
    #[serde(default)]
    understand_deep: bool,
    /// Any additional raw flags (e.g. ["--cache-age-days","60"]).
    #[serde(default)]
    extra_args: Option<Vec<String>>,
}

#[derive(Serialize, Clone)]
struct OauthRedirect {
    query: String,
}

/// Absolute path to the bundled `mac-cleanup.sh` resource.
fn script_path(app: &AppHandle) -> Result<std::path::PathBuf, String> {
    app.path()
        .resolve(
            "resources/mac-cleanup.sh",
            tauri::path::BaseDirectory::Resource,
        )
        .map_err(|e| format!("could not locate bundled script: {e}"))
}

/// Write (idempotently) a graphical sudo askpass helper to the app cache dir
/// and return its path. When this is exported as MACLEANUP_ASKPASS, the CLI
/// routes sudo through it, so privileged sections prompt ONCE per run via a
/// native macOS password dialog (no Terminal needed). Returns None on failure
/// — privileged sections then simply skip, exactly as before.
fn ensure_askpass(app: &AppHandle) -> Option<std::path::PathBuf> {
    use std::os::unix::fs::PermissionsExt;
    let dir = app.path().app_cache_dir().ok()?;
    std::fs::create_dir_all(&dir).ok()?;
    let path = dir.join("macleanup-askpass.sh");
    // The helper shows a password dialog and prints the entered password to
    // stdout (what sudo --askpass expects); Cancel yields an empty string so
    // sudo simply fails and the section is skipped.
    let script = "#!/bin/bash\nosascript \
-e 'try' \
-e 'text returned of (display dialog \"macleanup needs administrator access to clean protected system files. Enter your macOS password to continue.\" with title \"macleanup\" default answer \"\" with hidden answer with icon caution)' \
-e 'on error' -e 'return \"\"' -e 'end try' 2>/dev/null\n";
    std::fs::write(&path, script).ok()?;
    std::fs::set_permissions(&path, std::fs::Permissions::from_mode(0o755)).ok()?;
    Some(path)
}

/// The app's own version (matches package.json / tauri.conf.json).
#[tauri::command]
fn app_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

/// Run a cleanup in a background thread. Returns immediately; progress is
/// delivered via events:
///   * `clean:log`   — one stderr line of human-readable output
///   * `clean:done`  — `{ code: i32, json: string }` with the JSON summary
///   * `clean:error` — `string` if the process could not be spawned
#[tauri::command]
fn run_clean(app: AppHandle, args: RunArgs) -> Result<(), String> {
    let script = script_path(&app)?;
    let askpass = ensure_askpass(&app);
    std::thread::spawn(move || {
        let mut cmd = Command::new("/bin/bash");
        // --json => JSON summary on stdout, human log on stderr (we stream it).
        cmd.arg(&script).arg("--json").arg("--no-color");
        // Graphical one-prompt-per-run sudo for privileged sections.
        if let Some(ap) = &askpass {
            cmd.env("MACLEANUP_ASKPASS", ap);
            cmd.env("SUDO_ASKPASS", ap);
        }
        if args.all {
            cmd.arg("--all");
        } else if let Some(s) = args.sections.as_ref().filter(|s| !s.is_empty()) {
            cmd.arg("--only").arg(s);
        }
        if args.dry_run {
            cmd.arg("--dry-run");
        }
        if args.yes {
            cmd.arg("--yes");
        }
        if args.understand_deep {
            cmd.arg("--i-understand-deep");
        }
        if let Some(extra) = args.extra_args {
            for a in extra {
                cmd.arg(a);
            }
        }
        cmd.stdout(Stdio::piped()).stderr(Stdio::piped());

        let mut child = match cmd.spawn() {
            Ok(c) => c,
            Err(e) => {
                let _ = app.emit("clean:error", format!("failed to start cleanup: {e}"));
                return;
            }
        };

        // Stream stderr (the human log) line-by-line.
        let log_handle = child.stderr.take().map(|err| {
            let app2 = app.clone();
            std::thread::spawn(move || {
                for line in BufReader::new(err).lines().map_while(Result::ok) {
                    let _ = app2.emit("clean:log", line);
                }
            })
        });

        // Collect stdout (the JSON summary).
        let mut out = String::new();
        if let Some(mut so) = child.stdout.take() {
            let _ = so.read_to_string(&mut out);
        }
        if let Some(h) = log_handle {
            let _ = h.join();
        }
        let code = child.wait().ok().and_then(|s| s.code()).unwrap_or(-1);
        let _ = app.emit(
            "clean:done",
            serde_json::json!({ "code": code, "json": out.trim() }),
        );
    });
    Ok(())
}

/// Start a one-shot localhost listener for the Google OAuth redirect.
/// Returns the chosen port; the frontend uses `http://127.0.0.1:<port>` as the
/// redirect URI. On redirect we emit `oauth:redirect` with the raw query string
/// (contains `code` + `state`) and serve a friendly "you can close this" page.
#[tauri::command]
fn oauth_listen(app: AppHandle) -> Result<u16, String> {
    let listener =
        std::net::TcpListener::bind("127.0.0.1:0").map_err(|e| format!("bind failed: {e}"))?;
    let port = listener
        .local_addr()
        .map_err(|e| e.to_string())?
        .port();

    std::thread::spawn(move || {
        if let Ok((mut stream, _)) = listener.accept() {
            let mut buf = [0u8; 8192];
            let n = stream.read(&mut buf).unwrap_or(0);
            let req = String::from_utf8_lossy(&buf[..n]);
            // First request line: "GET /?code=...&state=... HTTP/1.1"
            let path = req
                .lines()
                .next()
                .and_then(|l| l.split_whitespace().nth(1))
                .unwrap_or("/");
            let query = path.splitn(2, '?').nth(1).unwrap_or("").to_string();

            let body = "<!doctype html><html><head><meta charset=\"utf-8\"><title>macleanup</title></head>\
<body style=\"font-family:-apple-system,BlinkMacSystemFont,sans-serif;background:#0f1117;color:#e6e8f0;display:flex;align-items:center;justify-content:center;height:100vh;margin:0\">\
<div style=\"text-align:center\"><h2 style=\"margin:0 0 8px\">Signed in to macleanup ✓</h2>\
<p style=\"opacity:.7\">You can close this window and return to the app.</p></div></body></html>";
            let resp = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
                body.len(),
                body
            );
            let _ = stream.write_all(resp.as_bytes());
            let _ = stream.flush();
            let _ = app.emit("oauth:redirect", OauthRedirect { query });
        }
    });

    Ok(port)
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_updater::Builder::new().build())
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_process::init())
        .invoke_handler(tauri::generate_handler![app_version, run_clean, oauth_listen])
        .run(tauri::generate_context!())
        .expect("error while running macleanup");
}
