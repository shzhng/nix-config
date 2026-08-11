# Workflow
- for git commits, stick to conventional commits style
- prefer using the home-manager way of configuring a tool rather than directly outputting the config file

# Commands
- `rebuild` (shell alias, run from this repo) to rebuild the system and push locally-built paths to the shzhng cachix cache
- `sudo darwin-rebuild switch --flake .` to rebuild the system without pushing to the cache

# Configuration
- when adding and removing cli tools, update `modules/agents/AGENTS.md` (the shared agent context; home-manager renders it to each harness's global instructions file, e.g. `~/.claude/CLAUDE.md`)
- agent-facing config (instructions, skills, per-harness wiring) lives in `modules/agents/`

# Binary Cache (cachix)
- personal cache is `shzhng.cachix.org`; pull config (substituters + public keys) lives in `flake.nix` `nixConfig` and applies to any flake command against this repo
- pushing needs two per-machine, non-repo steps: `cachix authtoken <write-token>` (writes `~/.config/cachix/cachix.dhall`) and `trusted-users = root shuo` in `/etc/nix/nix.custom.conf`
- `nix.settings` in nix-darwin is disabled (`nix.enable = false`, Determinate manages nix), so system-wide nix settings must go in `/etc/nix/nix.custom.conf`, not nix-darwin
- `rebuild` uploads only locally-built paths via cachix `watch-exec --watch-mode post-build-hook`, so it can't blow the cache quota