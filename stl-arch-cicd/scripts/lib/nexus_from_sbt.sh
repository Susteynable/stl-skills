#!/usr/bin/env bash
# Helpers: resolve Nexus URL/auth like sbt, discover Stey deps from build files.

nexus_scala_binary() {
  local root="${1:-.}"
  local out
  out="$(grep -E 'Global / scalaVersion|ThisBuild / scalaVersion|scalaVersion[[:space:]]*:=' "$root/build.sbt" 2>/dev/null \
    | sed -nE 's/.*"([0-9]+\.[0-9]+)\.[0-9]+".*/\1/p' | head -1)"
  if [[ -z "$out" ]]; then
    out="$(cd "$root" && sbt -batch 'show scalaBinaryVersion' 2>/dev/null \
      | awk -F'\t' '/scalaBinaryVersion$/{getline; gsub(/^[[:space:]]+|[[:space:]]+$/,""); if ($0 ~ /^2\.[0-9]+$/) {print; exit}}')"
  fi
  [[ -n "$out" ]] || die "Could not resolve scalaBinaryVersion in $root (build.sbt or sbt show)"
  echo "$out"
}

nexus_sbt_credential_host() {
  cd "${1:-.}" && sbt -batch 'show credentials' 2>/dev/null \
    | grep -Eo 'DirectCredentials\([^)]+\)' \
    | head -1 \
    | sed -n 's/.*, "\([^"]*\)", "\([^"]*\)",.*/\2/p' || true
}

nexus_parse_release_url() {
  local root="${1:-.}"
  local url
  url="$(grep -Eoh 'https://[^"]+/repository/maven-releases/?' "$root/build.sbt" "$root"/project/*.sbt 2>/dev/null | head -1)"
  [[ -n "$url" ]] || url="$(grep -Eoh '"[^"]*maven-releases/?"' "$root/build.sbt" "$root"/project/*.sbt 2>/dev/null | tr -d '"' | grep maven-releases | head -1)"
  echo "$url"
}

nexus_parse_host_from_url() {
  local url="$1"
  echo "$url" | sed -E 's#https?://([^/]+)/.*#\1#'
}

# Credentials("realm", "host", "user", "pass") or credentials += Credentials with the same arguments.
nexus_parse_build_credentials() {
  local root="${1:-.}"
  local host="${2:-}"
  grep -RhE 'Credentials[[:space:]]*\(' "$root/build.sbt" "$root"/project/*.sbt 2>/dev/null \
    | grep -vE '^[[:space:]]*//' \
    | sed -nE 's/.*Credentials[[:space:]]*\([[:space:]]*"[^"]*"[[:space:]]*,[[:space:]]*"([^"]*)"[[:space:]]*,[[:space:]]*"([^"]*)"[[:space:]]*,[[:space:]]*"([^"]*)"[[:space:]]*\).*/\1\t\2\t\3/p' \
    | while IFS=$'\t' read -r h u p; do
        if [[ -z "$host" || "$h" == "$host" ]]; then
          printf '%s\t%s\n' "$u" "$p"
          break
        fi
      done
}

nexus_read_sbt_credentials_file() {
  local host="$1"
  local f realm h user pass
  for f in "$HOME/.sbt/1.0/credentials" "$HOME/.sbt/.credentials" "$HOME/.s2/credentials"; do
    [[ -f "$f" ]] || continue
    realm="" h="" user="" pass=""
    while IFS= read -r line || [[ -n "$line" ]]; do
      case "$line" in
        realm=*) realm="${line#realm=}" ;;
        host=*) h="${line#host=}" ;;
        user=*) user="${line#user=}" ;;
        password=*) pass="${line#password=}" ;;
      esac
      if [[ -n "$h" && -n "$user" && -n "$pass" ]]; then
        if [[ -z "$host" || "$h" == "$host" ]]; then
          printf '%s\t%s\n' "$user" "$pass"
          return 0
        fi
        realm="" h="" user="" pass=""
      fi
    done < "$f"
  done
  return 1
}

nexus_resolve_user() {
  local host="$1" root="${2:-.}"
  local pair u
  pair="$(nexus_parse_build_credentials "$root" "$host" | head -1)"
  if [[ -n "$pair" ]]; then
    echo "${pair%%$'\t'*}"
    return
  fi
  pair="$(nexus_read_sbt_credentials_file "$host" 2>/dev/null | head -1)" && {
    echo "${pair%%$'\t'*}"
    return
  }
  # Host from sbt show credentials, then match build file again
  local sbt_host
  sbt_host="$(nexus_sbt_credential_host "$root")"
  [[ -n "$sbt_host" ]] && nexus_parse_build_credentials "$root" "$sbt_host" | head -1 | awk -F'\t' '{print $1}'
}

nexus_resolve_pass() {
  local host="$1" root="${2:-.}"
  local pair
  pair="$(nexus_parse_build_credentials "$root" "$host" | head -1)"
  if [[ -n "$pair" ]]; then
    echo "${pair#*$'\t'}"
    return
  fi
  pair="$(nexus_read_sbt_credentials_file "$host" 2>/dev/null | head -1)" && {
    echo "${pair#*$'\t'}"
    return
  }
  local sbt_host
  sbt_host="$(nexus_sbt_credential_host "$root")"
  [[ -n "$sbt_host" ]] && nexus_parse_build_credentials "$root" "$sbt_host" | head -1 | awk -F'\t' '{print $2}'
}

# Resolve a version val name to its literal from build content.
nexus_resolve_version_val() {
  local content="$1" val="$2"
  echo "$content" | grep -E "val[[:space:]]+${val}[[:space:]]*=" | head -1 \
    | sed -nE 's/.*=[[:space:]]*"([^"]+)".*/\1/p'
}

# Emit lines: groupId<TAB>artifactId<TAB>currentVersion
nexus_discover_stey_coords() {
  local root="$1"
  local files=("$root/build.sbt")
  if [[ -d "$root/project" ]]; then
    while IFS= read -r -d '' f; do files+=("$f"); done < <(find "$root/project" -maxdepth 1 -name '*.sbt' -print0 2>/dev/null)
  fi

  local content
  content="$(cat "${files[@]}" 2>/dev/null)"

  {
    grep -ihE 'com\.stey.*%%' "${files[@]}" 2>/dev/null | grep -vE '^[[:space:]]*/\*|^[[:space:]]*\*' | while IFS= read -r line; do
      local g a v ref
      g="$(echo "$line" | sed -nE 's/^[[:space:]]*"([^"]+)"[[:space:]]*%%[[:space:]]*"([^"]+)".*/\1/p')"
      a="$(echo "$line" | sed -nE 's/^[[:space:]]*"([^"]+)"[[:space:]]*%%[[:space:]]*"([^"]+)".*/\2/p')"
      [[ -n "$g" && -n "$a" ]] || continue
      v="$(echo "$line" | sed -nE 's/.*artifactVersion\([^,]+,[[:space:]]*"([^"]+)".*/\1/p')"
      if [[ -z "$v" ]]; then
        ref="$(echo "$line" | sed -nE 's/.*artifactVersion\([^,]+,[[:space:]]*([a-zA-Z][a-zA-Z0-9]*)\).*/\1/p')"
        [[ -n "$ref" ]] && v="$(nexus_resolve_version_val "$content" "$ref")"
      fi
      if [[ -z "$v" && "$line" != *artifactVersion* ]]; then
        v="$(echo "$line" | sed -nE 's/.*%[[:space:]]*"([^"]+)".*/\1/p')"
        [[ -z "$v" ]] && v="$(echo "$line" | sed -nE 's/.*%[[:space:]]*([a-zA-Z][a-zA-Z0-9]*).*/\1/p')"
      fi
      [[ -n "$v" ]] || continue
      echo "${g}	${a}	${v}"
    done
  } | awk -F'\t' 'NF>=3 && !seen[$1 FS $2]++'
}
