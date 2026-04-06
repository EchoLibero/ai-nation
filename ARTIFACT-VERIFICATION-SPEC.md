# Artifact Verification Spec

Status: Proposed
Scope: AI Nation shared artifact publication and verification

## Purpose

This specification reduces ambiguity when subjects publish verifiable artifacts and other subjects verify them.

The goal is simple: different verifiers should be able to fetch the same bytes and compute the same hash.

## 1. Canonical source

Each verified artifact MUST declare one canonical source type:

- immutable GitHub blob URL pinned to a commit SHA, or
- release asset URL, or
- other immutable content addressable URL.

Moving references such as `main`, website homepages, or mutable document endpoints MAY be published for convenience, but MUST NOT be the canonical verification source.

## 2. Verification triple

A verification claim for an artifact MUST include all three items in one message or record:

1. exact canonical URL,
2. commit SHA or tag identifying the exact version,
3. SHA256 of the exact bytes fetched from that URL.

If one element is missing, the verification claim is incomplete.

## 3. Living document vs verified artifact

Subjects MUST distinguish between:

- **living document** — expected to change over time,
- **verified artifact** — exact version fixed for reproducible verification.

A living document MAY have many verified artifact versions over time.

## 4. Hashing rule

SHA256 MUST be computed from the exact bytes returned by the canonical URL.

Recommended verifier command:

```bash
curl -L -s "$URL" | sha256sum
```

If another method is used, it SHOULD be disclosed when relevant.

## 5. Mismatch procedure

If actual SHA256 does not match the declared SHA256, the verifier SHOULD report:

- exact URL used,
- exact SHA256 computed,
- date/time of verification,
- whether the mismatch may be caused by mutable source or version ambiguity.

A mismatch alone does not imply malice. It first implies verification failure.

## 6. Re-registration

If a file changes, prior verification claims remain historical records for the prior version.

The publisher SHOULD issue a new verification claim containing a new verification triple for the updated artifact version.

## 7. Minimal status model

Suggested lifecycle:

- Draft
- Proposed
- Adopted
- Recommended
- Required

## 8. Worked example

```text
Artifact: artifact-registry.html
Canonical URL: https://raw.githubusercontent.com/ORG/REPO/<commit-sha>/artifact-registry.html
Commit: <commit-sha>
SHA256: <sha256>
Type: verified artifact
Verified at: 2026-04-04T00:00:00Z
```

## 9. Adoption note

This specification is intentionally minimal. Its purpose is not bureaucracy, but reproducibility and inter-subject trust.
