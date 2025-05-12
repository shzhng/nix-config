# Nix/MacOS System Configurations

[![NixOS 24.05](https://img.shields.io/badge/NixOS-24.05-blue.svg?style=flat-square&logo=NixOS&logoColor=white)](https://nixos.org)
[![NixOS 24.05](https://img.shields.io/badge/nixpkgs-24.05-blue.svg?style=flat-square&logo=NixOS&logoColor=white)](https://github.com/NixOS/nixpkgs)

This repository contains my own personal MacOS (using
[nix-darwin](https://github.com/LnL7/nix-darwin)) and
[home-manager](https://github.com/nix-community/home-manager) system
configurations. I use this to provision my MacOS instance, as well as provision
the same environment on Linux systems (currently non-NixOS) using standalone
home-manager.

> [!IMPORTANT]
> This is a work in progress and may not work as expected. It isn't
> intended to be used by other people in their own setup, but feel free to
> reference it as you get into using `nix`.

![MacOS](./assets/darwin-wezterm.png)

## Setup

1. Install `nix` (if not on NixOS) I prefer to use the [Determinate Systems
installer](https://github.com/DeterminateSystems/nix-installer).

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

2.a Initialize the MacOS system, with home-manager as a module

```sh
nix run nix-darwin -- switch --flake .
```

2.b. Initialize home-manager on a Linux system

```sh
nix run home-manager -- switch --flake .
```

3.a. Reload the full system on MacOS

```sh
darwin-rebuild switch --flake .
```

3.b. Reload home-manager on a Linux system

```sh
home-manager switch --flake .
```

## Code Formatting

This repository uses automatic code formatting to maintain consistent style across all Nix files. The formatting is enforced using git pre-commit hooks that run before each commit.

### Setting Up Pre-commit Hooks

To set up the pre-commit hooks:

```sh
nix run .#install-git-hooks
```

This will install a git pre-commit hook that automatically formats all Nix files using `nixfmt-rfc-style` whenever you make a commit.

### Manual Formatting

If you want to manually format all Nix files in the repository:

```sh
find . -name "*.nix" -type f -exec nix run nixpkgs#nixfmt-rfc-style -- {} \;
```

### How It Works

- The hooks are configured in the `flake.nix` file using [git-hooks.nix](https://github.com/cachix/git-hooks.nix)
- A `.pre-commit-config.yaml` file is generated automatically (and git-ignored)
- The hooks run `nixfmt-rfc-style` on all Nix files before each commit
- If formatting fails, the commit is aborted

### Skipping Hooks

If you need to bypass the pre-commit hooks for a specific commit:

```sh
git commit --no-verify
```

However, it's generally recommended to let the hooks run to maintain consistent formatting.
