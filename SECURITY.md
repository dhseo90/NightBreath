# Security Policy

NightBreath is designed as an on-device, local-first app. Security and privacy
reports should protect users while preserving that boundary.

## Reporting

Use GitHub private vulnerability reporting if it is available for this
repository. If it is not available, open a minimal public issue only after
removing sensitive details.

Do not include:

- secrets, tokens, private keys, or account details
- personal health exports or real audio recordings
- local absolute paths, device identifiers, or private logs
- exploit instructions that would put users at risk

## Supported Scope

Security review currently covers the repository source, local tooling, release
guardrails, and the iOS app code in this repository. App Store, TestFlight,
Apple platform services, HealthKit itself, and third-party apps remain governed
by their own providers.

## Expected Boundaries

NightBreath should not add server upload, cloud processing, account login,
external analytics, ad SDKs, HealthKit write behavior, or Fitdays server/API
integration. HealthKit use must remain read-only and user-triggered from the
health dashboard.
