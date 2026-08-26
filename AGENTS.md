# Workflow
- for git commits, stick to conventional commits style
- prefer using the home-manager way of configuring a tool rather than directly outputting the config file

# Commands
- `rebuild` (shell alias, run from this repo) to rebuild the system and push locally-built paths to the shzhng cachix cache
- `sudo darwin-rebuild switch --flake .` to rebuild the system without pushing to the cache

# Configuration
- when adding and removing cli tools, update `modules/agents/AGENTS.md` (the shared agent context; home-manager renders it to each harness's global instructions file, e.g. `~/.claude/CLAUDE.md`)
- when adding or removing MCP servers (`mcp-servers.programs` / `programs.mcp.servers` in `modules/agents/default.nix`), update the "MCP Servers" roster in `modules/agents/AGENTS.md` in the same change
- agent-facing config (instructions, skills, per-harness wiring) lives in `modules/agents/`

# Binary Cache (cachix)
- personal cache is `shzhng.cachix.org`; pull config (substituters + public keys) lives in `flake.nix` `nixConfig`; accept the trust prompt once when running interactively (saved to `~/.local/share/nix/trusted-settings.json`) or mirror the caches into `/etc/nix/nix.custom.conf` — otherwise non-interactive nix ignores flake nixConfig ("untrusted flake configuration setting" warnings) and everything not on cache.nixos.org compiles from source
- the `llm-agents` input deliberately does not `follows` our nixpkgs: rebasing changes derivation hashes and misses cache.numtide.com (codex alone is a huge Rust build); `llm-agents-ori` (fork branch carrying only the prebuilt-binary `ori` package) does follow, since it has no cache to preserve
- pushing needs two per-machine, non-repo steps: `cachix authtoken <write-token>` (writes `~/.config/cachix/cachix.dhall`) and `trusted-users = root shuo` in `/etc/nix/nix.custom.conf`
- `nix.settings` in nix-darwin is disabled (`nix.enable = false`, Determinate manages nix), so system-wide nix settings must go in `/etc/nix/nix.custom.conf`, not nix-darwin
- `rebuild` uploads only locally-built paths via cachix `watch-exec --watch-mode post-build-hook`, so it can't blow the cache quota