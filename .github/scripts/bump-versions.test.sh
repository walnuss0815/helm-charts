#!/usr/bin/env bash
# Self-check for bump-versions.sh, run in a throwaway git repo.
set -euo pipefail

script=$(realpath "$(dirname "${BASH_SOURCE[0]}")/bump-versions.sh")
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
git init -q
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=false

# chart <name> <version> [tag...]: a chart released as the given tags
chart() {
  mkdir -p "charts/$1"
  printf 'name: %s\nversion: %s\n' "$1" "$2" >"charts/$1/Chart.yaml"
  git add . && git commit -q -m "chore($1): add"
  for t in "${@:3}"; do git tag "$1-$t"; done
}
# change <name> <message>: a commit touching the chart
change() {
  echo "$2" >>"charts/$1/file"
  git add . && git commit -q -m "$2"
}
version() { sed -n 's/^version: //p' "charts/$1/Chart.yaml"; }
check() { [[ $2 == "$3" ]] || { echo "FAIL $1: got '$2', want '$3'" >&2; exit 1; }; }

chart a 1.2.3 1.2.3
chart a-b 0.1.0 0.1.0
chart a-2fa 0.3.1 0.3.1
chart brk 1.0.0 1.0.0
chart big 1.0.0 1.0.0
chart manual 2.0.0 1.0.0
chart fresh 0.1.0
chart stale 1.0.0 1.0.0 1.1.0
chart quoted '"1.0.0"' 1.0.0
chart idle 1.0.0 1.0.0

change a "fix(a): x"
change a-b "feat(a-b): x"
change a-2fa "feat(a-2fa)!: x"
change brk "fix(brk): x

BREAKING CHANGE: y"
# The breaking commit is the newest, so grep -q stops reading the long log early
change big "fix(big): padding

$(head -c 120000 /dev/zero | tr '\0' x | fold -w 80)"
change big "feat(big)!: x"
change manual "fix(manual): x"
change stale "fix(stale): x"
change quoted "fix(quoted): x"
git add . && git commit -q --allow-empty -m "chore: unrelated"

out=$(bash "$script" 2>"$tmp/stderr")
before=$(git diff | md5sum)

check a "$(version a)" 1.2.4
check a-b "$(version a-b)" 0.2.0
check a-2fa "$(version a-2fa)" 1.0.0
check brk "$(version brk)" 2.0.0
check big "$(version big)" 2.0.0
check manual "$(version manual)" 2.0.0
check fresh "$(version fresh)" 0.1.0
check quoted "$(version quoted)" 1.0.1
check idle "$(version idle)" 1.0.0
check list "$out" "$(printf 'charts/a-2fa\ncharts/a-b\ncharts/a\ncharts/big\ncharts/brk\ncharts/fresh\ncharts/manual\ncharts/quoted')"
grep -q 'stale 1.0.0 is already released' "$tmp/stderr" || { echo "FAIL stale: no warning" >&2; exit 1; }

# A rerun before the tags exist changes nothing
out2=$(bash "$script" 2>/dev/null)
check rerun-list "$out2" "$out"
check rerun-diff "$(git diff | md5sum)" "$before"

echo "ok"
