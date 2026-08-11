#!/usr/bin/env python3
"""Sync the nix-config repo: clean main checkout, prune merged worktrees.

Dry-run by default; pass --apply to execute the plan. Never discards work:
anything dirty, unmerged, or ambiguous lands in the attention list instead.
"""

import argparse
import datetime
import json
import os
import subprocess
import sys
from pathlib import Path

DEFAULT_REPO = "~/git/shzhng/nix-config"
WORKTREES_SUBDIR = ".claude/worktrees"


def run(args, cwd=None, check=True):
    return subprocess.run(
        args, cwd=cwd, check=check, capture_output=True, text=True
    ).stdout.strip()


def git(repo, *args, check=True):
    return run(["git", "-C", str(repo), *args], check=check)


class Sync:
    def __init__(self, repo, apply_mode):
        self.repo = repo
        self.apply_mode = apply_mode
        self.plan = []  # (description, thunk)
        self.attention = []
        self.created_this_run = set()

    def act(self, description, thunk):
        self.plan.append(description)
        if self.apply_mode:
            thunk()

    def note(self, description):
        self.attention.append(description)

    # -- main checkout ------------------------------------------------------

    def sync_main(self):
        branch = git(self.repo, "symbolic-ref", "--short", "-q", "HEAD", check=False)
        dirty = git(self.repo, "status", "--porcelain")

        if branch != "main":
            self.note(
                f"main checkout is on '{branch or 'detached HEAD'}' — "
                "relocate it manually; only dirty-on-main is auto-relocated"
            )
            return

        if dirty:
            self.relocate_dirty_main()

        local = git(self.repo, "rev-parse", "main")
        remote = git(self.repo, "rev-parse", "origin/main")
        if local == remote:
            return
        behind_only = subprocess.run(
            ["git", "-C", str(self.repo), "merge-base", "--is-ancestor", "main", "origin/main"]
        ).returncode == 0
        if behind_only:
            self.act(
                f"fast-forward main {local[:7]} -> {remote[:7]}",
                lambda: git(self.repo, "merge", "--ff-only", "origin/main"),
            )
        else:
            self.note("main has local commits not on origin/main — push or relocate them")

    def relocate_dirty_main(self):
        slug = "wip-" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        wt_path = self.repo / WORKTREES_SUBDIR / slug
        branch = f"worktree-{slug}"

        def do():
            git(self.repo, "stash", "push", "-u", "-m", f"nix-config-sync relocate to {slug}")
            git(self.repo, "worktree", "add", str(wt_path), "-b", branch, "origin/main")
            git(wt_path, "stash", "pop")
            git(wt_path, "add", "-A")
            git(wt_path, "commit", "-m", f"WIP: relocated from dirty main checkout by nix-config-sync")

        self.created_this_run.add(wt_path)
        self.act(f"relocate dirty main-checkout changes into {WORKTREES_SUBDIR}/{slug} (WIP commit on {branch})", do)

    # -- worktrees ----------------------------------------------------------

    def worktrees(self):
        entries, current = [], {}
        for line in git(self.repo, "worktree", "list", "--porcelain").splitlines():
            if not line.strip():
                if current:
                    entries.append(current)
                current = {}
            elif line.startswith("worktree "):
                current["path"] = Path(line.split(" ", 1)[1])
            elif line.startswith("branch "):
                current["branch"] = line.split(" ", 1)[1].removeprefix("refs/heads/")
        if current:
            entries.append(current)
        marker = str(self.repo / WORKTREES_SUBDIR)
        return [e for e in entries if str(e.get("path", "")).startswith(marker)]

    def squash_merged(self, branch, head):
        """A branch is squash-merged when a merged PR's recorded head matches it."""
        try:
            out = run(
                ["gh", "pr", "list", "--head", branch, "--state", "merged",
                 "--json", "headRefOid", "--limit", "10"],
                cwd=str(self.repo),
            )
            return any(pr.get("headRefOid") == head for pr in json.loads(out))
        except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError):
            return None  # gh unavailable — caller degrades to attention

    def sync_worktrees(self):
        cwd = os.getcwd()
        for wt in self.worktrees():
            path, branch = wt["path"], wt.get("branch")
            rel = path.relative_to(self.repo)
            if path in self.created_this_run:
                continue
            if not branch:
                self.note(f"{rel}: detached HEAD — resolve manually")
                continue
            if not path.exists():
                self.act(f"prune stale worktree registration {rel}",
                         lambda p=path: git(self.repo, "worktree", "remove", "--force", str(p)))
                continue
            if cwd.startswith(str(path)):
                self.note(f"{rel}: current session is inside it — exit before removing")
                continue

            dirty = git(path, "status", "--porcelain")
            head = git(path, "rev-parse", branch)
            ancestor = subprocess.run(
                ["git", "-C", str(path), "merge-base", "--is-ancestor", branch, "origin/main"]
            ).returncode == 0
            squashed = False if ancestor else self.squash_merged(branch, head)

            if ancestor or squashed:
                if dirty:
                    self.note(f"{rel}: branch '{branch}' is merged but the tree is dirty — inspect before removing")
                    continue
                self.act(
                    f"remove merged worktree {rel} (+ branch '{branch}')",
                    lambda p=path, b=branch: self.remove_worktree(p, b),
                )
            elif squashed is None and not ancestor:
                self.note(f"{rel}: '{branch}' not an ancestor of origin/main and gh unavailable to check squash-merge — kept")
            else:
                state = "dirty, " if dirty else ""
                self.note(f"{rel}: '{branch}' has unmerged work ({state}kept)")

    def remove_worktree(self, path, branch):
        git(self.repo, "worktree", "remove", "--force", str(path))
        git(self.repo, "branch", "-D", branch)
        if git(self.repo, "ls-remote", "--heads", "origin", branch):
            git(self.repo, "push", "origin", "--delete", branch, check=False)

    # -- driver -------------------------------------------------------------

    def sync(self):
        git(self.repo, "fetch", "--prune", "origin")
        self.sync_main()
        self.sync_worktrees()

        mode = "APPLIED" if self.apply_mode else "PLAN (re-run with --apply to execute)"
        print(f"== nix-config-sync: {mode} ==")
        for item in self.plan or ["nothing to do"]:
            print(f"  * {item}")
        if self.attention:
            print("== attention ==")
            for item in self.attention:
                print(f"  ! {item}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="execute the plan (default: dry run)")
    parser.add_argument("--repo", default=DEFAULT_REPO, help=f"repo path (default: {DEFAULT_REPO})")
    args = parser.parse_args()

    repo = Path(args.repo).expanduser().resolve()
    if not (repo / ".git").exists():
        sys.exit(f"not a git repo: {repo}")
    Sync(repo, args.apply).sync()


if __name__ == "__main__":
    main()
