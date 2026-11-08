#!/usr/bin/env bash
# Bumps charts changed since their last release tag and prints the
# directories of charts whose version is not released yet.
set -euo pipefail
# Same chart order and tag sort on every machine
export LC_ALL=C

for dir in charts/*/; do
  dir=${dir%/}
  chart=${dir#charts/}
  [[ -f $dir/Chart.yaml ]] || continue
  version=$(sed -n 's/^version: *//p' "$dir/Chart.yaml" | tr -d "\"'")
  # Exact match, so `immich-kiosk-*` never counts as a tag of `immich`
  tag=$(git tag --merged HEAD -l "$chart-*" | grep -E "^$chart-[0-9]+\.[0-9]+\.[0-9]+$" | sort -V | tail -n 1 || true)

  # A version that differs from the last tag was set by hand: keep it
  if [[ -n $tag && $version == "${tag#"$chart"-}" ]]; then
    messages=$(git log --format=%B "$tag..HEAD" -- "$dir")
    subjects=$(git log --format=%s "$tag..HEAD" -- "$dir")
    if [[ -n $subjects ]]; then
      IFS=. read -r major minor patch <<<"$version"
      if grep -qE 'BREAKING CHANGE|!:' <<<"$messages"; then
        version=$((major + 1)).0.0
      elif grep -q '^feat' <<<"$subjects"; then
        version=$major.$((minor + 1)).0
      else
        version=$major.$minor.$((patch + 1))
      fi
      sed -i "s/^version:.*/version: $version/" "$dir/Chart.yaml"
    fi
  elif [[ -n $tag ]] && git rev-parse -q --verify "refs/tags/$chart-$version" >/dev/null; then
    echo "warning: $chart $version is already released, but $tag is newer; not releasing" >&2
    continue
  fi

  git rev-parse -q --verify "refs/tags/$chart-$version" >/dev/null || echo "$dir"
done
