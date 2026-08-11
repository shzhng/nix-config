---
name: nix-config-sync
description: >-
  Tidy the nix-config repo (~/git/shzhng/nix-config): fast-forward the main
  checkout, relocate stray work out of it, and remove worktrees whose branches
  have merged (including squash merges). Use after merging a nix-config PR,
  when asked to sync or clean up the repo or its worktrees, or when the main
  checkout is found dirty or stale.
---

# nix-config-sync

The nix-config repo follows a strict invariant:

**The main checkout at `~/git/shzhng/nix-config` stays on a clean, up-to-date
`main`. All work — every branch, commit, experiment — happens in a worktree
under `.claude/worktrees/`.**

The main checkout exists to be read and to serve the running system config.
Work in progress never blocks a `git pull`, and nothing is ever lost in a
stray checkout.

## Syncing

Run the bundled script (paths relative to this skill's base directory). It is
**dry-run by default** — run it once, show the user the plan, then re-run with
`--apply`:

```bash
python3 scripts/sync.py           # plan only
python3 scripts/sync.py --apply   # execute
```

One pass does all of this:

- **Fast-forwards `main`** to origin/main (fetch --prune included).
- **Relocates drift**: uncommitted changes found in the main checkout are
  moved into a fresh `wip-*` worktree as a WIP commit — never discarded —
  and the checkout returns to clean `main`.
- **Removes merged worktrees**: a worktree whose branch is an ancestor of
  `origin/main`, or whose head matches a squash-merged PR (checked via `gh`),
  and whose tree is clean, is removed along with its local and remote branch.
- **Never touches** dirty worktrees, unmerged branches, or the worktree the
  current session is running in — those land in the `attention` section of
  the summary. Relay attention items to the user.

Run from anywhere; the script targets `~/git/shzhng/nix-config` (override
with `--repo`).

After changing `sync.py`, run `scripts/selftest.sh` — it builds a throwaway
fixture repo (with a stubbed `gh`) and asserts every behavior without touching
the real repo or GitHub.

## Starting new work

Use the harness's worktree mechanism (EnterWorktree) when available, or:

```bash
git -C ~/git/shzhng/nix-config worktree add \
  ~/git/shzhng/nix-config/.claude/worktrees/<name> -b worktree-<name> origin/main
```

Then install the pre-commit hooks in the new worktree (the generated
`.pre-commit-config.yaml` is git-ignored, so each worktree needs this once):

```bash
nix run .#install-git-hooks
```

## Finishing work

After a PR merges, the next sync removes its worktree and branches
automatically. PRs are squash-merged, so expect the squash detection (via
`gh pr list --head <branch> --state merged`) to be what matches.
