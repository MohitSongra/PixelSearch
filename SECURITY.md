# Security Policy

## Supported versions

PixelSearch has no supported release yet. It is a final-year student project; no release-signed build has been
made, and only debug builds exist. Security fixes go into the source in this repository; there are no release
branches.

The optional backend in `enhancement_backend/` is meant to be deployed by its operator. A deployment may run older
code than this repository.

## Reporting a vulnerability

Please report vulnerabilities privately.

1. **Preferred:** use GitHub's private vulnerability reporting. On the repository's **Security** tab, choose
   **Report a vulnerability**, if that option is shown.
2. **If private reporting is not available:** open a public issue (the bug report form) titled "Security contact
   request", with **no technical details**. Ask for a private way to send the report. A maintainer will reply with a
   private contact and then close the issue.

Include in the private report: what is affected (app, backend or tooling), the steps to reproduce, the impact you
expect, and the commit you tested.

## Never include personal data

In any report, issue, pull request, log or screenshot, never attach or paste:

- personal or gallery photos, or face crops
- person names, face descriptors or anything that identifies a person
- GPS coordinates or location history
- device serial numbers
- backend URLs, install tokens, API keys or other secrets

Use synthetic test images, placeholders such as `<name>` or `<backend-url>`, and aggregate numbers instead.

## Scope

In scope:

- the Flutter app in `pixelsearch_app/` (local storage, consent and online clients, People data handling)
- the optional FastAPI backend in `enhancement_backend/`
- the repository tooling in `tool/` and `model_kit/`

Known, accepted limits (not vulnerabilities on their own):

- The app does not encrypt its local data itself; it relies on Android's app-private storage.
- Deletion is logical (database rows and files), not forensic erasure.
- Optional online features send data off the device only after the user's consent, as described in the
  [README's privacy model](README.md#privacy-model).

The most recent review is [docs/SECURITY_REVIEW_2026-09-18.md](docs/SECURITY_REVIEW_2026-09-18.md).
