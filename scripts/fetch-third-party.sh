#!/usr/bin/env bash
# Download the third-party skills listed in scripts/third-party.txt into
# third_party/<name> (git-ignored), each checked out at its pinned commit.
#
#   scripts/fetch-third-party.sh                  # everything
#   scripts/fetch-third-party.sh superpowers gsap-skills
#
# Uses a blob-less partial clone plus sparse checkout, so only the listed
# paths are downloaded. Re-running updates an existing checkout in place.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
manifest="$root/scripts/third-party.txt"
dest_root="$root/third_party"
mkdir -p "$dest_root"

wanted=" $* "
matched=0
while read -r name repo ref paths; do
  case "$name" in '' | '#'*) continue ;; esac
  if [ $# -gt 0 ] && [[ "$wanted" != *" $name "* ]]; then
    continue
  fi
  matched=$((matched + 1))
  dest="$dest_root/$name"

  if [ ! -d "$dest/.git" ]; then
    git clone --quiet --filter=blob:none --no-checkout "https://github.com/$repo.git" "$dest"
  fi
  if [ "$paths" = "." ]; then
    git -C "$dest" sparse-checkout disable
  else
    # shellcheck disable=SC2086  # paths are a space-separated list on purpose
    git -C "$dest" sparse-checkout set --cone $paths
  fi
  if ! git -C "$dest" rev-parse --verify --quiet "$ref^{commit}" >/dev/null; then
    git -C "$dest" fetch --quiet origin "$ref"
  fi
  git -C "$dest" -c advice.detachedHead=false checkout --quiet "$ref"
  echo "$name -> third_party/$name @ ${ref:0:7}"
done <"$manifest"

if [ "$matched" -eq 0 ]; then
  echo "No entries matched: $*" >&2
  exit 1
fi
