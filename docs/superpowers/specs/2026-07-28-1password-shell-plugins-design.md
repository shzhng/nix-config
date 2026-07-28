# API keys for CLI tools via 1Password shell plugins

**Date:** 2026-07-28
**Status:** Approved

## Problem

CLI tools like `hcloud` need API keys (e.g. `HCLOUD_TOKEN`). The nix config
manages everything else declaratively, but there is currently no story for
secrets: no sops-nix/agenix, no managed env files. Keys should not live in the
repo or in plaintext on disk.

## Decision

Use [1Password shell plugins](https://github.com/1Password/shell-plugins) via
their home-manager module. The machine already runs 1Password (Homebrew cask,
SSH agent configured in `home.nix`), and hcloud is an officially supported
plugin. Keys stay in 1Password and are injected per-invocation with biometric
unlock; nothing secret touches disk or the repo.

Alternatives considered:

- **sops-nix** — declarative and headless-capable, but plaintext lands on disk
  and requires per-machine age key management. Deferred; can be added later if
  headless scripts need secrets.
- **Gitignored env file** — simplest, but unmanaged and unencrypted.

## Changes

1. **`flake.nix`** — add input
   `_1password-shell-plugins.url = "github:1Password/shell-plugins"` (with
   `inputs.nixpkgs.follows = "nixpkgs"` to match existing inputs) and pass it
   through to home-manager modules.
2. **`modules/darwin/default.nix`** — add the `"1password-cli"` cask next to
   the existing `"1password"` cask. Homebrew-installed `op` avoids
   code-signing quirks with biometric unlock that nix-built binaries can hit,
   and matches the existing pattern of installing 1Password via Homebrew.
3. **`home.nix`** — import the shell-plugins home-manager module and enable:

   ```nix
   programs._1password-shell-plugins = {
     enable = true;
     plugins = with pkgs; [ hcloud ];
   };
   ```

   This generates shell aliases so `hcloud` runs as
   `op plugin run -- hcloud`. Future CLIs (aws, gh, flyctl, …) are one line
   each in `plugins`.
4. **`~/.claude/CLAUDE.md` generation in `home.nix`** — document `op` and the
   plugin wrapping in the CLI tools list, per the repo rule that tool changes
   must be reflected there.

## One-time per-machine setup (not nix-manageable)

- Enable *Settings → Developer → Integrate with 1Password CLI* in the
  1Password app.
- Store the Hetzner token as an API Credential item in 1Password.
- Run `op plugin init hcloud` once to link the item.

## Known limitation

Wrapped commands prompt for biometric unlock when 1Password is locked, so
fully-headless use (cron, CI) won't work through this path. For those cases,
use `op run` with a service account, or add sops-nix later.

## Verification

- `nix flake check` / `rebuild` succeeds.
- New shell: `type hcloud` shows the `op plugin run -- hcloud` alias.
- After `op plugin init hcloud`: `hcloud server list` (or similar) works with
  a biometric prompt and no `HCLOUD_TOKEN` in the environment.
