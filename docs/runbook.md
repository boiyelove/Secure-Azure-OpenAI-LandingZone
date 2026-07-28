# Operations runbook

## Deployment failure

1. Read the subscription deployment operations and identify the first failed resource.
2. Do not retry blindly if APIM is still provisioning; verify its provisioning state.
3. Correct the parameter or quota issue and redeploy with the same resource names.
4. Confirm that role assignment, private DNS, and diagnostics converged.

## Requests return 401

- Confirm the token tenant, client application ID, audience, and expiry.
- Confirm named values match the Entra registration.
- Never weaken token validation to diagnose a production incident.

## Requests return 429

- Correlate request-limit and token-limit headers with APIM metrics.
- Identify the caller using non-sensitive identity metadata.
- Raise limits only after confirming backend quota and a cost owner.

## Backend is unavailable

- Resolve the Azure OpenAI hostname from an allowed VNet and confirm a private IP.
- Check Private Endpoint connection state and APIM subnet/NSG health.
- Confirm the APIM identity retains `Cognitive Services OpenAI User`.
- Confirm the requested deployment and API version exist.

## Suspected policy compromise

1. Restrict APIM policy-write permissions.
2. Disable the APIM identity role assignment to Azure OpenAI if impact warrants it.
3. Export activity logs and preserve deployment/policy revisions.
4. Review backend changes, diagnostic settings, and unusual token/model usage.
5. Restore a reviewed policy and rotate affected application credentials.

## Teardown

Run `scripts/destroy.sh` only after exporting required evidence. Resource-group
deletion is asynchronous; verify completion and search for separately scoped budgets,
locks, DNS, or monitoring artifacts.
