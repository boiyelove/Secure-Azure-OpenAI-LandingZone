# Security policy

## Supported versions

Only the latest tagged release receives security fixes. This repository is a
reference implementation, not a managed service.

## Reporting

Do not open a public issue for a suspected vulnerability. Use GitHub private
vulnerability reporting when enabled, or contact the repository owner privately.
Include the affected commit, reproduction steps, impact, and a safe proof of concept.
Never include real prompts, credentials, tokens, tenant identifiers, or customer data.

The maintainers will acknowledge a report within five business days, validate scope,
coordinate a fix and advisory, and credit the reporter unless anonymity is requested.

## Operational warning

Compromise of APIM policy-editing permissions can indirectly expose the APIM managed
identity token. Restrict `Microsoft.ApiManagement/service/apis/policies/write`, review
policy changes, and alert on unauthorized control-plane modifications.
