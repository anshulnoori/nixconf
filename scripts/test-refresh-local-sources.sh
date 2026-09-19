#!/usr/bin/env bash
set -euo pipefail
# Offline fixtures exercise validation; no downloads or installer execution.
# shellcheck source=scripts/refresh-local-sources.sh
source "$(dirname "${BASH_SOURCE[0]}")/refresh-local-sources.sh"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
cd "$scratch"
mkdir -p packages .github/workflows
printf '{"nodes":{}}\n' >flake.lock
printf '{"version":"27.0.1789118100"}\n' >"$sf_pro_pin"
fixture_sha=1111111111111111111111111111111111111111
old=2222222222222222222222222222222222222222
mode=valid
github_json() {
  local tag=v7.0.1
  [[ $1 != samueldr/lix-gha-installer-action ]] || tag=v2026-06-15
  case "$2" in
  releases/latest)
    if [[ $mode == prerelease ]]; then
      printf '{"draft":false,"prerelease":true,"tag_name":"v7.0.1"}'
    elif [[ $mode == malformed ]]; then
      printf '{}'
    else printf '{"draft":false,"prerelease":false,"tag_name":"%s"}' "$tag"; fi
    ;;
  git/ref/tags/*)
    local type=commit
    [[ $mode != annotated ]] || type=tag
    printf '{"ref":"refs/tags/%s","object":{"type":"%s","sha":"%s"}}' "$tag" "$type" "$fixture_sha"
    ;;
  git/tags/*) printf '{"sha":"%s","object":{"type":"commit","sha":"%s"}}' "$fixture_sha" "$fixture_sha" ;;
  git/commits/*) printf '{"sha":"%s"}' "$fixture_sha" ;;
  *) return 1 ;;
  esac
}
download_apple() { printf 'fixture DMG bytes' >"$1"; }
7zz() {
  local arg
  for arg in "$@"; do
    if [[ $arg == -o* ]]; then touch "${arg#-o}/SFProFonts.pkg"; fi
  done
}
bsdtar() {
  case "$*" in
  '-tf '*SFProFonts.pkg)
    [[ $mode != layout ]] || return 0
    printf 'SFProFontsPackage.pkg/PackageInfo\nSFProFontsPackage.pkg/Payload\n'
    ;;
  *PackageInfo)
    if [[ $mode == entity ]]; then
      printf '<!DOCTYPE pkg-info><pkg-info/>'
    else printf '<pkg-info identifier="com.apple.pkg.SFProFontsPackage" version="27.0.1789118100"/>'; fi
    ;;
  '-xOf '*Payload) printf 'fixture payload' ;;
  '-tf '*Payload)
    if [[ $mode == traversal ]]; then
      printf '../escape.otf\n'
    else printf './Library/Fonts/A.otf\n./Library/Fonts/B.ttf\n'; fi
    ;;
  '-xf '*)
    mkdir -p "$4/Library/Fonts"
    printf OTTO >"$4/Library/Fonts/A.otf"
    printf '\000\001\000\000' >"$4/Library/Fonts/B.ttf"
    if [[ $mode == font ]]; then printf bad >"$4/Library/Fonts/B.ttf"; fi
    ;;
  *) return 1 ;;
  esac
}
xmllint() {
  [[ $mode != xml ]] || return 1
  case "$*" in
  *identifier*)
    if [[ $mode == identifier ]]; then echo unexpected; else echo com.apple.pkg.SFProFontsPackage; fi
    ;;
  *version*)
    if [[ $mode == version ]]; then
      echo invalid
    elif [[ $mode == downgrade ]]; then
      echo 26.0.1
    else echo 27.0.1789118100; fi
    ;;
  esac
}
reset_workflow() {
  printf '    uses: actions/checkout@%s # v7.0.0\n    uses: samueldr/lix-gha-installer-action@%s # v2026-06-14\n' "$old" "$old" >"$workflow"
}
run_refresh() {
  local expected=$1 result
  set +e
  (
    set -e
    refresh_local_sources
  ) >test.log 2>&1
  result=$?
  set -e
  if [[ $expected == success && $result != 0 || $expected == failure && $result == 0 ]]; then
    cat test.log >&2
    fail "Expected $expected in $mode, got $result"
  fi
}
for mode in valid annotated; do
  reset_workflow
  run_refresh success
  grep -q "checkout@$fixture_sha # v7.0.1" "$workflow"
  grep -q "installer-action@$fixture_sha # v2026-06-15" "$workflow"
  # Expected digest derives from known fixture bytes, independently of helper output.
  expected="sha256-$(printf 'fixture DMG bytes' | openssl dgst -sha256 -binary | openssl base64 -A)"
  jq -e --arg hash "$expected" '.hash == $hash and .version == "27.0.1789118100"' "$sf_pro_pin" >/dev/null
done

# Devbox normalization uses Nix-verified bytes, and changes only locked.url.
mode=valid
latest=https://github.com/namespacelabs/devbox/releases/latest/download/checksums.txt
jq -n --arg url "$latest" '{nodes:{other:{unchanged:true},"namespace-devbox-release":{flake:false,original:{type:"file",url:$url},locked:{type:"file",url:$url,narHash:"sha256-dW8nIqVP3QAPID+CY0ykFXbCYa/4ohzUZ/9XZR1rbRo="}}}}' >flake.lock
cp flake.lock before-lock
printf '%064d  devbox_0.0.189_linux_amd64.tar.gz\n%064d  devbox_0.0.189_linux_arm64.tar.gz\n' 1 2 >manifest
nix() { printf '%s/manifest\n' "$scratch"; }
curl() {
  while [[ $1 != --output ]]; do shift; done
  cp manifest "$2"
  if [[ $mode == mismatch ]]; then printf '\n' >>"$2"; fi
}
reset_workflow
run_refresh success
jq -e --arg url "$latest" '.nodes["namespace-devbox-release"].original.url == $url and .nodes["namespace-devbox-release"].locked.url == "https://github.com/namespacelabs/devbox/releases/download/v0.0.189/checksums.txt"' flake.lock >/dev/null
jq '.nodes["namespace-devbox-release"].locked |= del(.url)' before-lock >expected-lock
jq '.nodes["namespace-devbox-release"].locked |= del(.url)' flake.lock >actual-lock
cmp expected-lock actual-lock
for mode in mismatch mixed-version missing-arch; do
  cp flake.lock before-lock
  cp "$sf_pro_pin" before-pin
  cp "$workflow" before-workflow
  if [[ $mode == mixed-version ]]; then
    printf '%064d  devbox_0.0.189_linux_amd64.tar.gz\n%064d  devbox_0.0.188_linux_arm64.tar.gz\n' 1 2 >manifest
  elif [[ $mode == missing-arch ]]; then
    printf '%064d  devbox_0.0.189_linux_amd64.tar.gz\n' 1 >manifest
  fi
  run_refresh failure
  cmp before-lock flake.lock
  cmp before-pin "$sf_pro_pin"
  cmp before-workflow "$workflow"
done
echo 'PASS: Devbox immutable normalization preserves original URL/hash/unrelated nodes and rejects mismatched bytes or versions'
echo 'PASS: stable and annotated action tags stay SHA-pinned; SF Pro digest uses downloaded bytes'
printf '{"nodes":{}}\n' >flake.lock
for mode in prerelease malformed layout entity traversal font xml identifier version downgrade moved; do
  reset_workflow
  if [[ $mode == moved ]]; then
    printf '    uses: actions/checkout@%s # v7.0.1\n    uses: samueldr/lix-gha-installer-action@%s # v2026-06-15\n' "$old" "$old" >"$workflow"
  fi
  cp "$workflow" before-workflow
  cp "$sf_pro_pin" before-pin
  run_refresh failure
  cmp before-workflow "$workflow"
  cmp before-pin "$sf_pro_pin"
  echo "PASS: $mode fails without changing either pin file"
done
