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
under `.worktrees/`.**

The main checkout exists to be read and to serve the running system config.
Work is never discarded during a sync — only relocated or left alone.

## Sync procedure

Show the user what you intend to remove before removing it. `REPO` below is
`~/git/shzhng/nix-config`.

1. `git -C $REPO fetch --prune origin`

2. Bring the main checkout to clean `main`:
   - On `main` and clean: `git -C $REPO merge --ff-only origin/main`
   - Dirty: relocate the changes into a worktree, then fast-forward —
     ```bash
     git -C $REPO stash push -u -m "sync relocate"
     git -C $REPO worktree add $REPO/.worktrees/<slug> -b worktree-<slug> origin/main
     git -C $REPO/.worktrees/<slug> stash pop
     # then WIP-commit it there
     ```
   - On some other branch: stop and ask the user; don't guess.

3. For each worktree under `$REPO/.worktrees/` (`git -C $REPO worktree
   list`), skip any worktree the current session is running inside, then:
   - **Dirty tree** (`git status --porcelain`): leave it, report it.
   - **Merged?** Either ancestry — `git -C $REPO merge-base --is-ancestor
     <branch> origin/main` — or squash-merged: PRs here are squash-merged, so
     compare `git rev-parse <branch>` against
     `gh pr list --head <branch> --state merged --json headRefOid`.
   - **Merged and clean**: remove it —
     ```bash
     git -C $REPO worktree remove --force <path>   # --force: squash merges look unmerged to git
     git -C $REPO branch -D <branch>
     git push origin --delete <branch>             # if it still exists on origin
     ```
   - Otherwise it's active work: leave it, report it.

4. Summarize what was done and anything left alone.

## Starting new work

Use the harness's worktree mechanism (EnterWorktree) when available, or
`git worktree add` under `.worktrees/` from `origin/main` as above.
Then install the pre-commit hooks in the new worktree once (the generated
config is git-ignored, so worktrees don't inherit it):

```bash
nix run .#install-git-hooks
```

## Finishing work

After a PR merges, the next sync removes its worktree and branches. Rebuild
with the `rebuild` alias (never raw `darwin-rebuild`) so locally-built paths
reach the cachix cache.
