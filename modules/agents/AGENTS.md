# Available CLI Tools

This file documents the CLI tools available in this environment to help coding agents make better recommendations.

## File Operations
- `rg` (ripgrep) - Fast recursive grep replacement for searching file contents
- `fd` - Fast find replacement for searching files and directories
- `bat` - Cat replacement with syntax highlighting and paging
- `lsd` - Modern ls replacement with icons and colors
- `duf` - Modern df replacement for disk usage
- `dust` - Modern du replacement for directory sizes

## Text Processing
- `jq` - JSON processor for parsing and manipulating JSON data
- `doggo` - DNS lookup utility
- `fzf` - Fuzzy finder for interactive filtering

## System Monitoring
- `bottom` (btop) - Cross-platform system monitor
- `btop` - Resource monitor with better interface

## Development Tools
- `git` - Version control
- `git-lfs` - Git Large File Storage (enabled via programs.git.lfs)
- `gh` - GitHub CLI for interacting with GitHub from the command line
- `herdr` - Agent multiplexer that lives in your terminal (configured via programs.herdr)
- `codex` - OpenAI Codex coding agent CLI (configured via programs.codex)
- `opencode` - OpenCode coding agent CLI (configured via programs.opencode)
- `ccr` - Claude Code Router, a local model gateway that routes coding agents (Claude Code, Codex, OpenCode) to OpenRouter and other providers
- `lazygit` - Terminal UI for git commands
- `node` - Node.js JavaScript runtime (version 18+)
- `npm` - Node.js package manager
- `kubectl` - Kubernetes command line tool
- `helm` - Kubernetes package manager
- `opentofu` - Infrastructure as code tool
- `cf-terraforming` - CloudFlare terraform generator

## Cloud Tools
- `azure-cli` (az) - Azure command line interface
- `awscli2` (aws) - AWS command line interface v2
- `hcloud` - Hetzner Cloud CLI
- `flyctl` - Fly.io deployment tool

## Package Managers
- `uv` - Fast Python package installer and resolver
- `cargo` - Rust package manager

## Shell Enhancement
- `zoxide` - Smart cd command with frecency
- `atuin` - Shell history replacement with sync
- `starship` - Cross-shell prompt
- `tmux` - Terminal multiplexer
- `direnv` - Environment variable management per directory

## Database Tools
- `duckdb` - Analytical SQL database

## Nix Tools
- `cachix` - Binary cache client (personal cache: shzhng.cachix.org)
- `nil` - Nix language server
- `nixfmt` - Nix code formatter
- `nixd` - Nix language server

## System Information
- `fastfetch` - System information display

## Aliases
- `cat` -> `bat --paging=never`
- `g` -> `git` (plus many git aliases like `ga`, `gc`, `gst`, etc.)
- `rebuild` -> darwin-rebuild build+switch, pushing built paths to cachix (run from the nix-config repo)

## herdr
- When `$HERDR_TAB_ID` is set, this session is running inside a herdr pane
- At the start of a task, rename the tab to a short 2-4 word label for the task: `herdr tab rename "$HERDR_TAB_ID" "<label>"`; update it if the task changes significantly

## Per-repo Agent Docs
- Repo-level agent instructions go in `AGENTS.md`; `CLAUDE.md` is a regular file containing only `@AGENTS.md` (Claude Code import), never a symlink or a copy

## Git Worktrees
- Feature/PR work goes in worktrees at `<repo>/.worktrees/<branch>` (agent-agnostic convention; `.worktrees/` is globally gitignored)
- Branch = directory: to work on a worktree's branch, open its directory — a branch checked out in a worktree cannot be checked out elsewhere
- In direnv-enabled repos, give a new worktree an `.envrc` containing `source_up` so it inherits the repo root's environment
- Remove worktrees once their branch merges (`git worktree remove <path>`)

## Notes
- All tools are installed via Nix and available in PATH
- Many tools have enhanced configurations
- Delta is available for manual use: `git diff | delta`
- Shell completions are automatically configured for zsh and fish
- Prefer these modern alternatives over traditional tools when available
