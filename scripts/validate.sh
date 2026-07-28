#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
azure_config_dir="${AZURE_CONFIG_DIR:-/tmp/secure-aoai-azure-config}"
mkdir -p "$azure_config_dir"
dotnet_extract_dir="${DOTNET_BUNDLE_EXTRACT_BASE_DIR:-/tmp/secure-aoai-dotnet}"
mkdir -p "$dotnet_extract_dir"

export AZURE_CONFIG_DIR="$azure_config_dir"
export DOTNET_BUNDLE_EXTRACT_BASE_DIR="$dotnet_extract_dir"

az bicep version >/dev/null
az bicep build --file "$repo_dir/infra/main.bicep" --stdout >/dev/null

jq -e '
  .openapi == "3.0.3"
  and (.paths["/deployments/{deployment}/chat/completions"].post.operationId == "createChatCompletion")
' "$repo_dir/policies/openapi.json" >/dev/null

xmllint --noout "$repo_dir/policies/api-policy.xml"

"$repo_dir/tests/test-policy.sh"
"$repo_dir/tests/test-security-baseline.sh"

printf 'Validation passed.\n'
