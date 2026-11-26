#!/usr/bin/env bash
# Release one theme: bump <theme>/.claude-plugin/plugin.json, commit `chore(release): <theme> X.Y.Z`,
# tag <theme>-vX.Y.Z, push both. The tag makes the GitHub Release (release.yml).
#
#   tools/release.sh <theme> [auto|patch|minor|major|X.Y.Z]    (default: auto)
#
# auto reads the Conventional Commits touching <theme>/ since its last tag: a breaking change is
# major (minor while pre-1.0), any feat is minor, anything else is patch. The first release of a
# theme is the version its plugin.json carries. Human-run: asks before it pushes.
set -euo pipefail

die() { echo "release: $*" >&2; exit 1; }
semver='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
below() {
  local a1 a2 a3 b1 b2 b3
  IFS=. read -r a1 a2 a3 <<<"$1"
  IFS=. read -r b1 b2 b3 <<<"$2"
  ((a1 < b1 || (a1 == b1 && (a2 < b2 || (a2 == b2 && a3 < b3)))))
}

theme=${1:-}
bump=${2:-auto}
cd "$(git rev-parse --show-toplevel)"
[[ -n $theme ]] || die "usage: tools/release.sh <theme> [auto|patch|minor|major|X.Y.Z]"
manifest=$theme/.claude-plugin/plugin.json
[[ -f $manifest ]] || die "$manifest is missing; themes: $(ls -d */.claude-plugin 2>/dev/null | cut -d/ -f1 | tr '\n' ' ')"
[[ -t 0 ]] || die "needs a terminal to confirm on"
[[ $(git branch --show-current) == main ]] || die "release from main only"
dirty=$(git status --porcelain --untracked-files=no)
[[ -z $dirty ]] || die "commit or stash tracked changes first:"$'\n'"$dirty"
git fetch -q --tags origin main
[[ -z $(git rev-list HEAD..origin/main) ]] || die "main is behind origin/main; pull first"

current=$(sed -nE 's/^  "version": "([^"]+)",$/\1/p' "$manifest")
[[ $current =~ $semver ]] || die "cannot read the version in $manifest"
last=$(git describe --tags --match "$theme-v[0-9]*.[0-9]*.[0-9]*" --abbrev=0 2>/dev/null || true)

if [[ -z $last ]]; then
  # first release: the version the manifest already carries, unless one was named
  [[ $bump == auto ]] && bump=$current
  range=HEAD
  base=$current
else
  base=${last#"$theme-v"}
  [[ $base =~ $semver ]] || die "last tag $last is not $theme-vX.Y.Z"
  range=$last..HEAD
  [[ -n $(git rev-list "$range" -- "$theme/") ]] || die "no commits under $theme/ since $last"
fi
IFS=. read -r major minor patch <<<"$base"

subjects=$(git log "$range" --no-merges --format='%s' -- "$theme/")
if [[ $bump == auto ]]; then
  messages=$(git log "$range" --no-merges --format='%s%n%b' -- "$theme/")
  if grep -qE '^[a-z]+(\([^)]*\))?!:|^BREAKING[ -]CHANGE:' <<<"$messages"; then
    bump=major
  elif grep -qE '^feat(\([^)]*\))?:' <<<"$subjects"; then
    bump=minor
  else
    bump=patch
  fi
  [[ $bump == major && $major == 0 ]] && bump=minor
fi

case $bump in
  major) version="$((major + 1)).0.0" ;;
  minor) version="$major.$((minor + 1)).0" ;;
  patch) version="$major.$minor.$((patch + 1))" ;;
  *)
    [[ $bump =~ $semver ]] || die "bump must be auto, patch, minor, major or X.Y.Z, not '$bump'"
    [[ -z $last ]] || below "$base" "$bump" || die "$bump is not above $last"
    version=$bump
    ;;
esac
tag=$theme-v$version
! git rev-parse -q --verify "refs/tags/$tag" >/dev/null || die "tag $tag exists"
! below "$version" "$current" || die "$version is below $manifest's $current; run: just release $theme $current"

echo "${last:-(first release)} → $tag"
sed 's/^/  /' <<<"$subjects"
read -r -p "release $tag and push to origin? [y/N] " answer
[[ $answer == [yY] ]] || die "aborted; nothing changed"

tmp=$manifest.tmp
sed -E "s/^(  \"version\": \")[^\"]+(\",)$/\1$version\2/" "$manifest" >"$tmp" && mv "$tmp" "$manifest"
grep -q "\"version\": \"$version\"" "$manifest" || die "could not bump $manifest"
git add "$manifest"
git commit -q --allow-empty -m "chore(release): $theme $version"
git tag -a "$tag" -m "$tag"
git push --atomic origin main "$tag"
echo "released $tag — https://github.com/masterik/mkit-themes/releases/tag/$tag"
