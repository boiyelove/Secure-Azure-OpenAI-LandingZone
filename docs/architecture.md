# Architecture

## Trust boundaries

1. The internet-facing Application Gateway terminates TLS and applies OWASP CRS 3.2.
2. APIM runs in internal VNet mode and accepts traffic only from the gateway subnet.
3. APIM validates the caller's Entra token before applying caller-specific quotas.
4. APIM discards caller credentials and obtains a backend token with managed identity.
5. Azure OpenAI denies its public endpoint and accepts traffic through Private Link.

Control-plane access remains separate from data-plane access. Contributors able to
edit APIM policies can redirect managed-identity tokens, so policy changes require
review and control-plane audit alerting.

## Data flow

The caller sends an Entra bearer token and chat-completion request through the WAF.
APIM validates tenant, client application, and audience. It creates a stable quota
key from the authenticated principal, enforces requests and tokens per minute, and
adds a correlation identifier. The caller's token and any `api-key` header are
removed before APIM obtains an Azure Cognitive Services token and forwards the
request privately.

Diagnostics contain platform audit, request metadata, metrics, and correlation IDs.
This blueprint does not intentionally log message bodies.

## Availability and scaling

Application Gateway spans availability zones and autos-scales from one to two
instances in the development baseline. APIM Developer tier is deliberately
non-production and non-SLA. Production adopters should use a supported zone-redundant
APIM tier, validate regional capacity, and exercise failover separately.

## Cost boundaries

APIM and Application Gateway dominate idle development cost. Deploy to a disposable
resource group, configure a subscription budget outside this template, and destroy
the environment after a lab. Model capacity is opt-in and model availability must be
confirmed before deployment.
