#!/usr/bin/env bash
# Query Stey Nexus maven-releases for latest versions of Stey libraryDependencies.
# Run from a Stey Scala repo root (directory containing build.sbt).
#
# Auth: sbt-loaded credentials — parses sbt Credentials declarations from build.sbt / project/*.sbt
# (same source as Global / credentials), optional ~/.sbt/1.0/credentials property files,
# cross-checked against `sbt show credentials` host.
#
# Usage: fetch_stey_nexus_latest.sh [repo-root]
# Env:   NEXUS_PARALLEL (default 16) — max parallel metadata curl jobs
# Output (stdout): TSV header + rows: groupId  artifactId  current  latest  status

set -euo pipefail

REPO_ROOT="${1:-.}"
REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"
PARALLEL="${NEXUS_PARALLEL:-16}"

die() { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }

[[ -f "$REPO_ROOT/build.sbt" ]] || die "No build.sbt in $REPO_ROOT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/nexus_from_sbt.sh
source "$SCRIPT_DIR/lib/nexus_from_sbt.sh"

cd "$REPO_ROOT"

nexus_release_url="$(nexus_parse_release_url)"
nexus_host="$(nexus_parse_host_from_url "$nexus_release_url")"
nexus_user="$(nexus_resolve_user "$nexus_host" "$REPO_ROOT")"
nexus_pass="$(nexus_resolve_pass "$nexus_host" "$REPO_ROOT")"
scala_binary="$(nexus_scala_binary "$REPO_ROOT")"

[[ -n "$nexus_release_url" ]] || die "Could not find maven-releases URL (SteyNexusRelease / maven-releases in build.sbt)"
[[ -n "$nexus_user" && -n "$nexus_pass" ]] || die "Could not resolve Nexus credentials for host $nexus_host (build.sbt Credentials or ~/.sbt credentials)"

# Trim trailing slash for URL joins
nexus_release_url="${nexus_release_url%/}"

# Discover Stey coordinates from build.sbt + project/*.sbt (dedupe)
COORDS=()
while IFS= read -r line; do
  [[ -n "$line" ]] && COORDS+=("$line")
done < <(nexus_discover_stey_coords "$REPO_ROOT")
[[ ${#COORDS[@]} -gt 0 ]] || die "No Stey-related libraryDependencies found in build.sbt / project/*.sbt"

nexus_fetch_one() {
  local group="$1" artifact="$2" current="$3"
  local group_path="${group//.//}"
  local url="${nexus_release_url}/${group_path}/${artifact}_${scala_binary}/maven-metadata.xml"
  local tmp http_code latest release pick status
  tmp="$(mktemp)"
  http_code="$(curl -s -u "${nexus_user}:${nexus_pass}" -o "$tmp" -w '%{http_code}' "$url" 2>/dev/null || echo "000")"
  if [[ "$http_code" != "200" ]]; then
    rm -f "$tmp"
    printf '%s\t%s\t%s\t\tnot_found\tHTTP %s\n' "$group" "$artifact" "$current" "$http_code"
    return
  fi
  latest="$(sed -n 's:.*<latest>\([^<]*\)</latest>.*:\1:p' "$tmp" | head -1)"
  release="$(sed -n 's:.*<release>\([^<]*\)</release>.*:\1:p' "$tmp" | head -1)"
  rm -f "$tmp"
  # maven-releases can expose a stale <latest>; prefer the explicit release line when present.
  pick="${release:-$latest}"
  pick="${pick%-RELEASE}"
  pick="${pick%-SNAPSHOT}"
  status="unchanged"
  if [[ -z "$pick" ]]; then
    status="no_version"
    pick=""
  elif [[ "$pick" != "$current" ]]; then
    status="bump"
  fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$group" "$artifact" "$current" "$pick" "$status"
}

printf 'groupId\tartifactId\tcurrent\tlatest\tstatus\n'

for row in "${COORDS[@]}"; do
  IFS=$'\t' read -r g a c <<< "$row"
  while [[ "$(jobs -r 2>/dev/null | wc -l | tr -d ' ')" -ge "$PARALLEL" ]]; do
    sleep 0.05
  done
  nexus_fetch_one "$g" "$a" "$c" &
done
wait
