#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit

# Run only in the isolated candidate worktree. Nothing here commits or pushes.
apple_url=https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg
sf_pro_pin=packages/sf-pro-source.json
workflow=.github/workflows/cache.yml

fail() {
  printf '%s\n' "$*" >&2
  return 1
}

download_apple() {
  local destination=$1 effective_url
  effective_url=$(curl --fail --silent --show-error --location \
    --proto '=https' --proto-redir '=https' --connect-timeout 20 --max-time 600 --retry 3 \
    --output "$destination" --write-out '%{url_effective}' "$apple_url")
  [[ $effective_url == "$apple_url" ]] || fail 'SF Pro redirected to an unexpected URL; inspect the official source manually.'
}

github_json() {
  local repository=$1 endpoint=$2
  local -a headers=(-H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28')
  if [[ -n ${GH_TOKEN:-} ]]; then headers+=(-H "Authorization: Bearer $GH_TOKEN"); fi
  curl --fail --silent --show-error --proto '=https' \
    --connect-timeout 20 --max-time 60 --retry 3 "${headers[@]}" \
    "https://api.github.com/repos/$repository/$endpoint"
}

sf_pro_source() {
  local directory=$1 identifier version old_version hash path magic otf=0 ttf=0
  download_apple "$directory/SF-Pro.dmg"
  # Select one expected installer, never execute it or extract arbitrary DMG paths.
  7zz e -bd -y "-o$directory" "$directory/SF-Pro.dmg" SFProFonts.pkg >&2
  [[ -f $directory/SFProFonts.pkg && ! -L $directory/SFProFonts.pkg ]] || fail 'Expected SFProFonts.pkg is missing.'
  bsdtar -tf "$directory/SFProFonts.pkg" >"$directory/installer-paths"
  for path in SFProFontsPackage.pkg/PackageInfo SFProFontsPackage.pkg/Payload; do
    [[ $(grep -Fxc "$path" "$directory/installer-paths") == 1 ]] || fail "Unexpected SF Pro installer layout: $path"
  done
  bsdtar -xOf "$directory/SFProFonts.pkg" SFProFontsPackage.pkg/PackageInfo >"$directory/PackageInfo"
  if grep -Eq '<!DOCTYPE|<!ENTITY' "$directory/PackageInfo"; then
    fail 'Unexpected XML declarations in SF Pro PackageInfo.'
    return 1
  fi
  xmllint --nonet --noout "$directory/PackageInfo"
  identifier=$(xmllint --nonet --xpath 'string(/pkg-info/@identifier)' "$directory/PackageInfo")
  version=$(xmllint --nonet --xpath 'string(/pkg-info/@version)' "$directory/PackageInfo")
  [[ $identifier == com.apple.pkg.SFProFontsPackage ]] || fail 'Unexpected SF Pro package identifier.'
  [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'Unexpected SF Pro installer version format.'
  old_version=$(jq -er '.version' "$sf_pro_pin")
  [[ $(printf '%s\n' "$old_version" "$version" | sort -V | tail -1) == "$version" ]] || fail 'SF Pro version decreased; inspect the source manually.'

  bsdtar -xOf "$directory/SFProFonts.pkg" SFProFontsPackage.pkg/Payload >"$directory/Payload"
  bsdtar -tf "$directory/Payload" >"$directory/font-paths"
  while IFS= read -r path; do
    path=${path#./}
    case "$path" in
    . | '' | Library | Library/ | Library/Fonts | Library/Fonts/) ;;
    Library/Fonts/*.otf | Library/Fonts/*.ttf)
      [[ ${path#Library/Fonts/} != */* ]] || fail 'Unexpected nested SF Pro font path.'
      ;;
    *)
      fail "Unexpected SF Pro payload path: $path"
      return 1
      ;;
    esac
  done <"$directory/font-paths"
  mkdir "$directory/fonts"
  bsdtar -xf "$directory/Payload" -C "$directory/fonts" --no-same-owner --no-same-permissions
  for path in "$directory/fonts/Library/Fonts/"*; do
    [[ -f $path && ! -L $path ]] || fail 'SF Pro payload contains a missing or nonregular font.'
    magic=$(od -An -tx1 -N4 "$path" | tr -d ' \n')
    case "$path:$magic" in
    *.otf:4f54544f) otf=$((otf + 1)) ;;
    *.ttf:00010000) ttf=$((ttf + 1)) ;;
    *)
      fail 'SF Pro payload contains an unexpected font format.'
      return 1
      ;;
    esac
  done
  ((otf > 0 && ttf > 0)) || fail 'SF Pro payload must contain both OpenType and TrueType fonts.'
  hash="sha256-$(openssl dgst -sha256 -binary "$directory/SF-Pro.dmg" | openssl base64 -A)"
  jq -n --arg url "$apple_url" --arg version "$version" --arg hash "$hash" \
    '{url:$url,version:$version,hash:$hash}'
  printf 'SF Pro %s: validated %s OTF and %s TTF files.\n' "$version" "$otf" "$ttf" >&2
}

stable_action() {
  local repository=$1 pattern release tag ref object sha type depth=0
  case "$repository" in
  actions/checkout) pattern='^v[0-9]+\.[0-9]+\.[0-9]+$' ;;
  samueldr/lix-gha-installer-action) pattern='^v[0-9]{4}-[0-9]{2}-[0-9]{2}$' ;;
  *)
    fail 'Unsupported action repository.'
    return 1
    ;;
  esac
  release=$(github_json "$repository" releases/latest)
  tag=$(jq -er --arg pattern "$pattern" \
    'select(.draft == false and .prerelease == false) | .tag_name | select(test($pattern))' <<<"$release")
  ref=$(github_json "$repository" "git/ref/tags/$tag")
  object=$(jq -ce --arg ref "refs/tags/$tag" 'select(.ref == $ref) | .object' <<<"$ref")
  while true; do
    sha=$(jq -er '.sha | select(test("^[0-9a-f]{40}$"))' <<<"$object")
    type=$(jq -er '.type' <<<"$object")
    case "$type" in
    commit) break ;;
    tag)
      ((depth < 8)) || fail 'Too many annotated tag indirections.'
      ref=$(github_json "$repository" "git/tags/$sha")
      object=$(jq -ce --arg sha "$sha" 'select(.sha == $sha) | .object' <<<"$ref")
      depth=$((depth + 1))
      ;;
    *)
      fail 'Release tag does not identify a Git commit.'
      return 1
      ;;
    esac
  done
  ref=$(github_json "$repository" "git/commits/$sha")
  jq -e --arg sha "$sha" '.sha == $sha' <<<"$ref" >/dev/null
  printf '%s %s\n' "$tag" "$sha"
}

action_workflow() {
  local line repository resolved tag sha old_tag old_sha prefix
  local pattern='^([[:space:]]*uses: )(actions/checkout|samueldr/lix-gha-installer-action)@([0-9a-f]{40}) # (v[0-9][0-9.-]*)$'
  local -A tags shas counts
  for repository in actions/checkout samueldr/lix-gha-installer-action; do
    resolved=$(stable_action "$repository")
    read -r tag sha <<<"$resolved"
    tags[$repository]=$tag
    shas[$repository]=$sha
    counts[$repository]=0
  done
  while IFS= read -r line || [[ -n $line ]]; do
    case "$line" in
    *'uses: actions/checkout@'* | *'uses: samueldr/lix-gha-installer-action@'*)
      [[ $line =~ $pattern ]] || fail 'Unexpected pinned action line; inspect the workflow manually.'
      prefix=${BASH_REMATCH[1]}
      repository=${BASH_REMATCH[2]}
      old_sha=${BASH_REMATCH[3]}
      old_tag=${BASH_REMATCH[4]}
      tag=${tags[$repository]}
      sha=${shas[$repository]}
      [[ $(printf '%s\n' "$old_tag" "$tag" | sort -V | tail -1) == "$tag" ]] || fail 'Stable action release decreased.'
      [[ $tag != "$old_tag" || $sha == "$old_sha" ]] || fail 'An existing action release tag moved; review it manually.'
      line="$prefix$repository@$sha # $tag"
      counts[$repository]=$((counts[$repository] + 1))
      ;;
    esac
    printf '%s\n' "$line"
  done <"$workflow"
  [[ ${counts['actions/checkout']} == 1 && ${counts['samueldr/lix-gha-installer-action']} == 1 ]] || fail 'Expected exactly one pin for each supported action.'
}

normalize_devbox_lock() {
  local directory=$1 manifest version url latest
  latest=https://github.com/namespacelabs/devbox/releases/latest/download/checksums.txt
  if ! jq -e '.nodes | has("namespace-devbox-release")' flake.lock >/dev/null; then
    cp flake.lock "$directory/flake.lock"
    return
  fi
  jq -e --arg latest "$latest" '
    .nodes["namespace-devbox-release"] |
    select(.flake == false and .original.type == "file" and .original.url == $latest) |
    .locked | select(.type == "file" and (.narHash | test("^sha256-[A-Za-z0-9+/]{43}=$"))) |
    select(.url == $latest or (.url | test("^https://github.com/namespacelabs/devbox/releases/download/v[0-9]+\\.[0-9]+\\.[0-9]+/checksums.txt$")))
  ' flake.lock >"$directory/locked.json"
  manifest=$(nix eval --impure --raw --expr \
    "(builtins.fetchTree (builtins.fromJSON (builtins.readFile $directory/locked.json))).outPath")
  [[ -f $manifest ]] || fail 'Devbox locked source is not a manifest file.'
  version=$(jq -Rrse '
    [split("\n")[] | select(length > 0) |
      capture("^[0-9a-f]{64}  devbox_(?<version>[0-9]+\\.[0-9]+\\.[0-9]+)_linux_(?<arch>amd64|arm64)\\.tar\\.gz$")] |
    select(length == 2 and ([.[].arch] | sort) == ["amd64", "arm64"]) |
    [.[].version] | unique | select(length == 1) | .[0]
  ' "$manifest")
  url="https://github.com/namespacelabs/devbox/releases/download/v$version/checksums.txt"
  curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
    --connect-timeout 20 --max-time 60 --retry 3 --output "$directory/immutable-checksums" "$url"
  cmp "$manifest" "$directory/immutable-checksums" || fail 'Versioned Devbox manifest differs from the locked source.'
  jq --arg url "$url" '.nodes["namespace-devbox-release"].locked.url = $url' flake.lock >"$directory/flake.lock"
}

refresh_local_sources() (
  local directory
  directory=$(mktemp -d)
  trap 'rm -rf "$directory"' EXIT
  sf_pro_source "$directory" >"$directory/sf-pro-source.json"
  action_workflow >"$directory/workflow.yml"
  normalize_devbox_lock "$directory"
  # Do not modify tracked files until all downloads and checks succeed.
  cp "$directory/sf-pro-source.json" "$sf_pro_pin"
  cp "$directory/workflow.yml" "$workflow"
  cp "$directory/flake.lock" flake.lock
)

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then refresh_local_sources; fi
