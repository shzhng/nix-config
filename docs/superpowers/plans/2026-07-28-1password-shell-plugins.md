# 1Password Shell Plugins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Inject CLI API keys (starting with `hcloud`) from 1Password at invocation time via 1Password shell plugins, so no secret lives on disk or in the repo.

**Architecture:** Add the `1Password/shell-plugins` flake input and its home-manager module (wired into both the darwin home-manager block and the standalone Linux `homeConfigurations.shuo`), enable `programs._1password-shell-plugins` with `hcloud` in `home.nix`, install the `op` CLI via the `1password-cli` Homebrew cask, and update the generated `~/.claude/CLAUDE.md` tool docs.

**Tech Stack:** Nix flakes, nix-darwin, home-manager, nix-homebrew, 1Password shell plugins.

**Spec:** `docs/superpowers/specs/2026-07-28-1password-shell-plugins-design.md`

---

### Task 1: Add the shell-plugins flake input and wire its home-manager module

**Files:**
- Modify: `flake.nix:43-48` (inputs), `flake.nix:50-62` (outputs args), `flake.nix:94-99` (darwin hm imports), `flake.nix:205-212` (standalone hm modules)
- Modify: `flake.lock` (via `nix flake lock`)

- [ ] **Step 1: Add the input** — in `flake.nix` after the `claude-code` input block:

```nix
    # 1Password shell plugins: inject CLI API keys (e.g. hcloud) from
    # 1Password at invocation time instead of storing them on disk.
    _1password-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 2: Add to outputs destructure** — the outputs function uses explicit destructuring with no `...`, so the new input must be added after `claude-code,`:

```nix
      claude-code,
      _1password-shell-plugins,
    }:
```

- [ ] **Step 3: Import the hm module in the darwin block** — in `home-manager.users.shuo.imports`:

```nix
            users.shuo = {
              imports = [
                ./home.nix
                catppuccin.homeModules.catppuccin
                _1password-shell-plugins.hmModules.default
              ];
            };
```

- [ ] **Step 4: Import the hm module in the standalone Linux config** — in `homeConfigurations.shuo.modules` (without this, enabling the option in the shared `home.nix` breaks Linux eval):

```nix
        modules = [
          ./home.nix
          catppuccin.homeModules.catppuccin
          _1password-shell-plugins.hmModules.default
        ];
```

- [ ] **Step 5: Update the lock file**

Run: `nix flake lock`
Expected: adds a `_1password-shell-plugins` node to `flake.lock`, no errors.

- [ ] **Step 6: Verify the system still evaluates and builds**

Run: `darwin-rebuild build --flake .`
Expected: completes successfully, `result` symlink updated. (Module is imported but not yet enabled, so no behavior change.)

- [ ] **Step 7: Commit**

```bash
git add flake.nix flake.lock
git commit -m "feat: add 1password shell-plugins flake input and hm module"
```

### Task 2: Enable the hcloud plugin in home.nix

**Files:**
- Modify: `home.nix:244-247` (the `programs` block)

- [ ] **Step 1: Enable the plugin** — replace the `programs` block at the bottom of `home.nix`:

```nix
  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    # Alias supported CLIs to `op plugin run -- <tool>` so their API keys are
    # injected from 1Password at invocation time (nothing secret on disk).
    # Needs the 1password-cli cask plus one-time `op plugin init <tool>`.
    _1password-shell-plugins = {
      enable = true;
      plugins = with pkgs; [ hcloud ];
    };
  };
```

- [ ] **Step 2: Verify build**

Run: `darwin-rebuild build --flake .`
Expected: completes successfully.

- [ ] **Step 3: Commit**

```bash
git add home.nix
git commit -m "feat: inject hcloud api token via 1password shell plugin"
```

### Task 3: Install the op CLI via Homebrew cask

**Files:**
- Modify: `modules/darwin/default.nix:76-92` (casks list)

- [ ] **Step 1: Add the cask** — in the `homebrew.casks` list, after `"1password"`:

```nix
    casks = [
      "1password"
      "1password-cli"
```

- [ ] **Step 2: Verify build**

Run: `darwin-rebuild build --flake .`
Expected: completes successfully.

- [ ] **Step 3: Commit**

```bash
git add modules/darwin/default.nix
git commit -m "feat(homebrew): add 1password-cli cask for op"
```

### Task 4: Update generated ~/.claude/CLAUDE.md tool docs

**Files:**
- Modify: `home.nix` (the `".claude/CLAUDE.md".text` block)

- [ ] **Step 1: Document op and the hcloud wrapping** — in the generated text, change the `hcloud` line under `## Cloud Tools` and add an `op` line:

```markdown
        ## Cloud Tools
        - `azure-cli` (az) - Azure command line interface
        - `awscli2` (aws) - AWS command line interface v2
        - `hcloud` - Hetzner Cloud CLI (aliased to `op plugin run -- hcloud`; API token injected from 1Password)
        - `flyctl` - Fly.io deployment tool
        - `op` - 1Password CLI (installed via Homebrew; used for secret/API-key injection via shell plugins)
```

And add one line under `## Notes`:

```markdown
        - CLI API keys are managed via 1Password shell plugins (`op plugin init <tool>` to link a credential); no tokens in env vars or on disk
```

- [ ] **Step 2: Verify build**

Run: `darwin-rebuild build --flake .`
Expected: completes successfully.

- [ ] **Step 3: Commit**

```bash
git add home.nix
git commit -m "docs(claude): document op and 1password shell plugin for hcloud"
```

### Task 5: Switch and verify

- [ ] **Step 1: Rebuild and switch** (the repo's `rebuild` alias, spelled out for non-interactive shells):

Run: `cachix watch-exec --watch-mode post-build-hook shzhng -- darwin-rebuild build --flake . && sudo darwin-rebuild switch --flake .`
Expected: activation completes; Homebrew installs `1password-cli`.

- [ ] **Step 2: Verify the alias and op install**

Run: `zsh -ic 'type hcloud' && op --version`
Expected: `hcloud is an alias for op plugin run -- hcloud` (wording may vary) and an op version number.

- [ ] **Step 3: Manual one-time steps (user, not automatable):**
  - In the 1Password app: *Settings → Developer → Integrate with 1Password CLI*.
  - Save the Hetzner API token as an **API Credential** item in 1Password.
  - Run `op plugin init hcloud` and select that item.
  - Test: `hcloud server list` → biometric prompt, then output, with no `HCLOUD_TOKEN` in the environment.
