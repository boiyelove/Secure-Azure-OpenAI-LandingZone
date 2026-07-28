# Contributing

1. Open an issue describing the problem, decision, or Azure API-version change.
2. Keep commits atomic and use `type(scope): imperative summary`.
3. Run `./scripts/validate.sh`.
4. Include what-if or integration evidence for infrastructure changes.
5. Update `docs/version-evidence.md` when changing a package, tool, Bicep module, or
   Azure resource API version.

Pull requests must not contain secrets, tenant data, generated deployment outputs,
Terraform/Bicep state, or prompt/response payloads. Breaking changes require an ADR
and a `BREAKING CHANGE:` commit footer.
