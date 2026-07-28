# ADR 0001: APIM uses managed identity for Azure OpenAI

- Status: accepted
- Date: 2026-07-28

## Decision

Disable Azure OpenAI local authentication and grant the APIM system-assigned identity
`Cognitive Services OpenAI User` at the account scope. APIM obtains a Cognitive
Services token and replaces caller-supplied backend credentials.

## Consequences

There are no stored model API keys. APIM policy editors can indirectly use its
identity, so policy-write permissions and changes are privileged and audited.
