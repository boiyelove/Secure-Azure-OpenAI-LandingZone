# Threat model

## Assets

- prompts, completions, model quota, API availability, audit evidence;
- APIM managed identity and policy integrity;
- Entra application identifiers and authorization configuration;
- Azure OpenAI deployment configuration.

## Principal threats and controls

| Threat | Preventive control | Detection or recovery |
|---|---|---|
| Direct model access | Public network disabled, Private Link, local auth disabled | Resource Graph and Azure Policy drift checks |
| Stolen or wrong-tenant token | Single-tenant Entra validation and client allowlist | APIM 401 metrics and sign-in investigation |
| Quota exhaustion | Per-principal request and token limits | 429 metrics, quota dashboards, capacity runbook |
| Caller injects backend credential | Delete `api-key`; overwrite `Authorization` | Policy review and API trace in a disposable environment |
| Managed-identity token exfiltration | Restrict policy-write permission and backend URL | Control-plane audit alert and immediate role revocation |
| Prompt leakage in telemetry | No body logging in default policy | Scheduled diagnostic-settings and query review |
| WAF bypass | APIM internal VNet mode and NSG source restriction | Network Watcher and APIM access-log review |
| Cross-user cache disclosure | Semantic cache disabled by default | ADR review before enabling a cache |
| Deployment/version drift | Pinned API versions and version evidence | CI compilation and scheduled dependency review |

## Residual risks

Azure service administrators retain control-plane authority. Model safety behavior
depends on the selected model and service configuration. WAF rules do not understand
prompt semantics. Consumers must add content-safety and application authorization
appropriate to their use case.
