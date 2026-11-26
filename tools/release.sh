#!/usr/bin/env bash
# Cut a release of the repo: bump every theme's plugin.json to one version, commit
# `chore(release): X.Y.Z`, tag vX.Y.Z, push both. The tag makes the GitHub Release (release.yml).
#
#   tools/release.sh [auto|patch|minor|major|X.Y.Z]    (default: auto)
#
# auto reads the Conventional Commits since the last tag: a breaking change is major (minor while
# pre-1.0), any feat is minor, anything else is patch. The first release is the highest version a
# theme's plugin.json carries. Human-run: asks before it pushes.
set -euo pipefail

die() { echo "release: $*" >&2; exit 1; }
semver='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
below() {
  local a1 a2 a3 b1 b2 b3
  IFS=. read -r a1 a2 a3 <<<"$1"
  IFS=. read -r b1 b2 b3 <<<"$2"
  ((a1 < b1 || (a1 == b1 && (a2 < b2 || (a2 == b2 && a3 < b3)))))
}

bump=${1:-auto}
cd "$(git rev-parse --show-toplevel)"
manifests=()
for f in */.claude-plugin/plugin.json; do
  if [[ -f $f ]]; then manifests+=("$f"); fi
done
((${#manifests[@]} > 0)) || die "no */.claude-plugin/plugin.json found"
[[ -t 0 ]] || die "needs a terminal to confirm on"
[[ $(git branch --show-current) == main ]] || die "release from main only"
dirty=$(git status --porcelain --untracked-files=no)
[[ -z $dirty ]] || die "commit or stash tracked changes first:"$'\n'"$dirty"
git fetch -q --tags origin main
[[ -z $(git rev-list HEAD..origin/main) ]] || die "main is behind origin/main; pull first"

# the highest version any manifest carries: never release below it
highest=0.0.0
for manifest in "${manifests[@]}"; do
  v=$(sed -nE 's/^  "version": "([^"]+)",$/\1/p' "$manifest")
  [[ $v =~ $semver ]] || die "cannot read the version in $manifest"
  ! below "$highest" "$v" || highest=$v
done

last=$(git describe --tags --match 'v[0-9]*.[0-9]*.[0-9]*' --abbrev=0 2>/dev/null || true)
if [[ -z $last ]]; then
  [[ $bump == auto ]] && bump=$highest
  range=HEAD
  base=$highest
else
  base=${last#v}
  [[ $base =~ $semver ]] || die "last tag $last is not vX.Y.Z"
  range=$last..HEAD
  [[ -n $(git rev-list "$range") ]] || die "no commits since $last"
fi
IFS=. read -r major minor patch <<<"$base"

subjects=$(git log "$range" --no-merges --format='%s')
if [[ $bump == auto ]]; then
  messages=$(git log "$range" --no-merges --format='%s%n%b')
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
! git rev-parse -q --verify "refs/tags/v$version" >/dev/null || die "tag v$version exists"
! below "$version" "$highest" || die "v$version is below a theme's $highest; run: just release $highest"

echo "${last:-(first release)} → v$version (${#manifests[@]} theme(s): ${manifests[*]%%/*})"
sed 's/^/  /' <<<"$subjects"
read -r -p "release v$version and push to origin? [y/N] " answer
[[ $answer == [yY] ]] || die "aborted; nothing changed"

for manifest in "${manifests[@]}"; do
  sed -E "s/^(  \"version\": \")[^\"]+(\",)$/\1$version\2/" "$manifest" >"$manifest.tmp" && mv "$manifest.tmp" "$manifest"
  grep -q "\"version\": \"$version\"" "$manifest" || die "could not bump $manifest"
done
git add "${manifests[@]}"
# --allow-empty: releasing the version the manifests already carry changes no file
git commit -q --allow-empty -m "chore(release): $version"
git tag -a "v$version" -m "v$version"
git push --atomic origin main "v$version"
echo "released v$version — https://github.com/masterik/mkit-themes/releases/tag/v$version"
