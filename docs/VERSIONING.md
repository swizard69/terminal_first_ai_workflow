# Documentation versioning

## Framework version

Single source of truth: [`VERSION`](../VERSION) at repo root (currently **1.0.0**).

Also mirrored in `manifest.md`:

```ini
framework_version=1.0.0
```

## Semantic versioning

| Bump | When |
|------|------|
| **MAJOR** | Breaking change to scripts, snapshot layout, or agent contract (`AGENTS.md` rules agents rely on). |
| **MINOR** | New scripts, skills, or workflow features; backward compatible. |
| **PATCH** | Doc fixes, typo, non-breaking script tweaks. |

## Workflow documentation

Each file under `docs/workflow/` carries a header:

```markdown
> Documentation **v1.0.0** · Updated **YYYY-MM-DD** · [Index](README.md) · [Changelog](../../CHANGELOG.md)
```

Rules:

- **Doc version** matches framework `VERSION` unless the page is a draft addendum (rare).
- **Updated** = last meaningful edit to that page (not drive-by typos in other files).
- On release: bump `VERSION`, add `CHANGELOG.md` section, refresh headers in touched workflow pages.

## Changelog

User-facing history: [`CHANGELOG.md`](../CHANGELOG.md) (Keep a Changelog format).

## Agent / human workflow on doc edits

1. Edit content.
2. Update `Updated` date in that file's header.
3. If behavior or contracts changed: bump `VERSION`, update `CHANGELOG.md`, sync headers on affected pages.
4. Tag release on GitHub: `v1.0.0` (optional but recommended for public repo).

## Related

- [Workflow index](workflow/README.md)
- [README](../README.md)
