# Claude Code Statusline Cockpit

A two-line statusline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that turns your terminal into a cockpit with real-time context.

## What it shows

**Line 1** — Model & session info:
- Model name (e.g. Claude Opus 4.6)
- Rate limit usage (5h and 7d windows) with color coding
- Context window usage (%)
- Current git branch

**Line 2** — Project context:
- Git status (dirty/clean + number of changes)
- Auto-detected stack: WordPress (with version + PHP version), Laravel, Drupal, Joomla, Next.js, Node, Python
- Number of MCP servers connected
- Current working directory

## Screenshot

![statusline](screenshot.png)

## Installation

1. Copy the scripts to your Claude config directory:

```bash
cp statusline-cockpit.sh ~/.claude/
cp statusline-legacy.sh ~/.claude/
chmod +x ~/.claude/statusline-cockpit.sh ~/.claude/statusline-legacy.sh
```

2. Add the statusline config to your `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-cockpit.sh"
  }
}
```

3. Restart Claude Code. Done!

## Requirements

- `jq` — for parsing the JSON input from Claude Code
- `git` — for branch and status info
- `python3` — for the legacy statusline (rate limits, context %)

## Color coding

| Usage   | Color  |
|---------|--------|
| < 50%   | Green  |
| 50–80%  | Yellow |
| > 80%   | Red    |

## License

MIT
