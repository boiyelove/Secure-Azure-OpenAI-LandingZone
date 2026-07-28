#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template="$repo_dir/infra/landing-zone.bicep"

required_patterns=(
  "disableLocalAuth: true"
  "publicNetworkAccess: 'Disabled'"
  "defaultAction: 'Deny'"
  "privateEndpointNetworkPolicies: 'Disabled'"
  "virtualNetworkType: 'Internal'"
  "mode: 'Prevention'"
  "ruleSetVersion: '3.2'"
  "enableLogAccessUsingOnlyResourcePermissions: true"
)

for pattern in "${required_patterns[@]}"; do
  if ! grep -Fq "$pattern" "$template"; then
    printf 'Missing required infrastructure control: %s\n' "$pattern" >&2
    exit 1
  fi
done

if grep -RIEq "(client_secret|api_key|password)[[:space:]]*[:=][[:space:]]*['\"][^'{]" \
  "$repo_dir/infra" "$repo_dir/policies"; then
  printf 'A credential-like literal was found in deployable files.\n' >&2
  exit 1
fi
