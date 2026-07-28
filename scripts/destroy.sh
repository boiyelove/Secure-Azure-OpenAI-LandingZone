#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! "$1" =~ ^rg-[a-z0-9-]+-(dev|test)$ ]]; then
  printf 'Usage: %s rg-<prefix>-(dev|test)\n' "$0" >&2
  exit 2
fi

resource_group="$1"
read -r -p "Delete Azure resource group '$resource_group'? Type the full name: " confirmation
if [[ "$confirmation" != "$resource_group" ]]; then
  printf 'Confirmation did not match; nothing deleted.\n' >&2
  exit 1
fi

az group delete --name "$resource_group" --yes --no-wait
printf 'Deletion requested for %s. Verify completion in Azure.\n' "$resource_group"
