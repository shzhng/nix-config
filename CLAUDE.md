# Workflow
- for git commits, stick to conventional commits style
- prefer using the home-manager way of configuring a tool rather than directly outputting the config file

# Commands
- `rebuild` (shell alias, run from this repo) to rebuild the system and push locally-built paths to the shzhng cachix cache
- `sudo darwin-rebuild switch --flake .` to rebuild the system without pushing to the cache

# Configuration
- when adding and removing cli tools, make sure to update our configuration to output it into our `~/.claude/CLAUDE.md` file