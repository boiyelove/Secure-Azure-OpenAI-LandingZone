#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
policy="$repo_dir/policies/api-policy.xml"

required_patterns=(
  '<validate-azure-ad-token'
  '<azure-openai-token-limit'
  '<rate-limit-by-key'
  '<authentication-managed-identity'
  'resource="https://cognitiveservices.azure.com"'
  '<set-header name="api-key" exists-action="delete"'
  '<set-backend-service base-url="{{openai-backend-url}}"'
)

for pattern in "${required_patterns[@]}"; do
  if ! grep -Fq "$pattern" "$policy"; then
    printf 'Missing required APIM policy control: %s\n' "$pattern" >&2
    exit 1
  fi
done

if grep -Eqi '(api[-_]?key|password)[[:space:]]*=[[:space:]]*"[^"{]' "$policy"; then
  printf 'A literal credential-like value was found in the APIM policy.\n' >&2
  exit 1
fi
