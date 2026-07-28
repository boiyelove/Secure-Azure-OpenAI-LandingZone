# Version evidence

This file records versions used by real commits. A version must not be represented as
historically available unless its release or Microsoft resource-template reference
supports that date.

## Baseline captured 2026-07-28

| Component | Pinned version | Evidence and rationale |
|---|---:|---|
| Azure CLI | 2.85.0 | Locally installed version used for validation |
| Bicep CLI | 0.45.15 | Official binary installed by `az bicep install` on the capture date |
| Cognitive Services account/deployment API | 2025-06-01 | Stable resource API available before the capture date |
| API Management service/API/policy API | 2024-05-01 | Stable resource API and current APIM service change-log baseline |
| Network resources API | 2024-07-01 | Stable API for VNet, Private Endpoint, WAF, and Application Gateway |
| Private DNS API | 2024-06-01 | Stable Private DNS zone/link API |
| Log Analytics workspace API | 2025-02-01 | Stable workspace API available before the capture date |
| Diagnostic settings API | 2021-05-01-preview | Current broadly used diagnostic-settings schema; preview status is an accepted residual risk |
| Azure OpenAI inference API | 2024-10-21 | GA data-plane version explicitly allowed by the OpenAPI contract |
| OWASP CRS | 3.2 | Application Gateway managed ruleset configured by the WAF policy |

## Upgrade policy

Before changing a version:

1. link the official release notes or Azure template reference in the pull request;
2. verify that the version existed on the real commit date;
3. compile Bicep and run what-if in a disposable subscription;
4. document breaking properties, migration, rollback, and regional limitations;
5. update this table in the same commit.

Official references:

- <https://learn.microsoft.com/azure/templates/microsoft.cognitiveservices/accounts>
- <https://learn.microsoft.com/azure/templates/microsoft.apimanagement/service>
- <https://learn.microsoft.com/azure/api-management/azure-openai-token-limit-policy>
- <https://learn.microsoft.com/azure/api-management/validate-azure-ad-token-policy>
- <https://learn.microsoft.com/azure/api-management/authentication-managed-identity-policy>
