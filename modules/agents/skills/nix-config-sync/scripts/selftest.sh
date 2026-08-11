#!/usr/bin/env bash
# Self-test for sync.py: builds a throwaway fixture repo and asserts every
# sync behavior without touching the real nix-config or GitHub.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

fail() { echo "FAIL: $1" >&2; exit 1; }

# Stub gh: reports feat-squash's head as a merged PR, nothing else.
mkdir -p "$T/bin"
cat > "$T/bin/gh" <<EOF
#!/usr/bin/env bash
if [[ "\$*" == *"--head feat-squash"* ]]; then
  echo "[{\"headRefOid\": \"\$(cat "$T/squash-head")\"}]"
else
  echo "[]"
fi
EOF
chmod +x "$T/bin/gh"
export PATH="$T/bin:$PATH"

# Fixture: bare origin with an initial commit on main.
git init -q --bare -b main "$T/origin"
git clone -q "$T/origin" "$T/seed"
(cd "$T/seed" && echo base > f && echo ".claude" > .gitignore && git add f .gitignore && git commit -qm base && git push -q origin main)
git clone -q "$T/origin" "$T/repo"
mkdir -p "$T/repo/.claude/worktrees"

wt() { git -C "$T/repo" worktree add -q "$T/repo/.claude/worktrees/$1" -b "$2" origin/main; }

# 1. merged-by-ancestry worktree -> removed
wt merged feat-merged
(cd "$T/repo/.claude/worktrees/merged" && echo a > a && git add a && git commit -qm a && git push -q origin feat-merged)
(cd "$T/seed" && git fetch -q && git merge -q --no-ff origin/feat-merged && git push -q origin main)

# 2. squash-merged worktree (different sha on main, gh stub vouches) -> removed
wt squashed feat-squash
(cd "$T/repo/.claude/worktrees/squashed" && echo b > b && git add b && git commit -qm b)
git -C "$T/repo" rev-parse feat-squash > "$T/squash-head"
(cd "$T/seed" && git pull -q && echo b > b && git add b && git commit -qm "b (squash)" && git push -q origin main)

# 3. dirty unmerged worktree -> kept
wt active feat-active
(cd "$T/repo/.claude/worktrees/active" && echo c > c)

# 4. dirty main checkout -> relocated to a WIP worktree
(cd "$T/repo" && git fetch -q && echo drift > drift)

python3 "$HERE/sync.py" --repo "$T/repo" | grep -q "PLAN" || fail "dry run should print a plan"
[ -e "$T/repo/.claude/worktrees/merged" ] || fail "dry run must not remove anything"

python3 "$HERE/sync.py" --repo "$T/repo" --apply > "$T/out"

[ ! -e "$T/repo/.claude/worktrees/merged" ] || fail "merged worktree not removed"
git -C "$T/repo" rev-parse -q --verify feat-merged >/dev/null && fail "feat-merged branch not deleted"
git ls-remote --heads "$T/origin" feat-merged | grep -q . && fail "remote feat-merged not deleted"
[ ! -e "$T/repo/.claude/worktrees/squashed" ] || fail "squash-merged worktree not removed"
[ -e "$T/repo/.claude/worktrees/active/c" ] || fail "active worktree must be untouched"
[ -z "$(git -C "$T/repo" status --porcelain)" ] || fail "main checkout should be clean"
ls "$T/repo/.claude/worktrees" | grep -q "^wip-" || fail "dirty main not relocated to wip worktree"
wip="$T/repo/.claude/worktrees/$(ls "$T/repo/.claude/worktrees" | grep "^wip-" | head -1)"
[ "$(cat "$wip/drift")" = "drift" ] || fail "relocated WIP content missing"
[ "$(git -C "$T/repo" rev-parse main)" = "$(git -C "$T/repo" rev-parse origin/main)" ] || fail "main not fast-forwarded"

echo "selftest OK"
