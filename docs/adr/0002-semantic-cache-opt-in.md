# ADR 0002: Semantic caching is opt-in

- Status: accepted
- Date: 2026-07-28

## Decision

Do not deploy or enable semantic caching in the secure baseline. Add it only through
a separate reviewed module with authenticated-principal and authorization context in
the cache boundary, short retention, deletion controls, and dedicated adversarial
tests.

## Consequences

The baseline has higher model consumption than a cache-enabled system but avoids
silent cross-user prompt/completion disclosure and an always-on cache dependency.
