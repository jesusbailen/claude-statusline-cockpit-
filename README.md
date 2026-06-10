# Claude Code Statusline Cockpit

Two-line custom statusline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that gives you real-time visibility into your session, project, and rate limits — right in the terminal.

```
Claude Opus 4.6 | 5h: 12% (4h32m) | 7d: 3% (6d11h) | ctx: 8% | ⎇ main
✓ clean  │  WP 6.7 · PHP 8.2 · wp-cli ✓  │  mcp: 3  │  ~/myproject
```

## How it works

The statusline is split into two scripts that run together:

### `statusline-cockpit.sh` (main entry point)

Reads the JSON blob that Claude Code pipes into the statusline command and renders two lines:

**Line 1** — delegates to `statusline-legacy.sh`:
- Active model name (e.g. `Claude Opus 4.6`)
- Rate limit usage for both windows (`5h` and `7d`) with time until reset
- Context window usage (`ctx`)
- Current git branch (`⎇ main`)

**Line 2** — assembled by cockpit itself:
- **Git status**: `✓ clean` or `✱N changes` (yellow) — number of dirty files via `git status --porcelain`
- **Stack detection**: auto-detects the project framework by checking for marker files:
  - `wp-config.php` / `wp-content/` → WordPress (+ version from `wp-includes/version.php`, PHP version, wp-cli availability)
  - `artisan` → Laravel
  - `core/lib/Drupal.php` → Drupal
  - `configuration.php` + `administrator/` → Joomla
  - `next.config.{js,mjs,ts}` → Next.js
  - `package.json` → Node (+ version)
  - `pyproject.toml` / `requirements.txt` → Python
- **MCP servers**: counts servers from project `.mcp.json` and global `~/.claude.json`
- **Working directory**: abbreviated with `~`

All segments are separated by `│` and color-coded with ANSI escape codes.

### `statusline-legacy.sh`

A Python script wrapped in bash that parses the Claude Code JSON input and renders line 1. Handles:
- Model display name from `model.display_name` or `model.id`
- Two rate-limit windows (`five_hour`, `seven_day`) — shows percentage used and countdown to reset, parsed from ISO 8601 timestamps or Unix epoch
- Context window percentage from `context_window.used_percentage`
- Git branch via `git symbolic-ref` (falls back to short SHA for detached HEAD)

### Color coding

| Usage    | Color    |
|----------|----------|
| 0–50%    | Green    |
| 51–80%   | Yellow   |
| > 80%    | Red      |

Applied to rate limits and context window.

## Installation

```bash
# 1. Copy scripts
cp statusline-cockpit.sh ~/.claude/
cp statusline-legacy.sh ~/.claude/
chmod +x ~/.claude/statusline-cockpit.sh ~/.claude/statusline-legacy.sh

# 2. Add to ~/.claude/settings.json
# (merge with your existing settings if needed)
```

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-cockpit.sh"
  }
}
```

Restart Claude Code.

## Dependencies

| Tool      | Used for                              | Required |
|-----------|---------------------------------------|----------|
| `jq`      | Parsing Claude Code JSON input        | Yes      |
| `git`     | Branch name, dirty file count         | Yes      |
| `python3` | Rate limits, context %, time parsing  | Yes      |
| `php`     | PHP version in WordPress detection    | No       |
| `wp`      | wp-cli availability indicator         | No       |
| `node`    | Node.js version in stack detection    | No       |

## File structure

```
~/.claude/
├── settings.json            # points statusLine to cockpit
├── statusline-cockpit.sh    # main script — renders both lines
└── statusline-legacy.sh     # line 1 — model, limits, context, branch
```

## License

MIT
