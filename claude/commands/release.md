Run the standard homebrew-tap release process for the current repo: promote CHANGELOG entries, tag, push, and confirm CI landed the tap formula update.
Applies to any repo with `scripts/release` and a `.github/workflows/release.yml` matching the pattern in `homebrew-tap` — currently after-midnight, gemkeeper, md-tools, photo-management, wrk.
See `~/git/danhorst/dotfiles/claude/fixtures/release/README.md` for the shape this follows.

## Steps

1. Confirm the repo has `scripts/release`. If it's missing, stop and point at the `bootstrap-release` skill instead — don't hand-roll a release.
2. Read `CHANGELOG.md`'s `[Unreleased]` section. If it's empty, stop and ask DBH to write entries first.
3. Suggest a semver bump from the `[Unreleased]` content: `patch` for fixes/chores only, `minor` if there's a `### Features`/`### Added` entry, `major` if there's a breaking-change note. State the suggestion alongside the latest tag (`git tag --sort=-version:refname | head -1`) and let DBH confirm or override the version.
4. Confirm with DBH before running — this commits, tags, and pushes to `origin`.
5. Run `scripts/release vX.Y.Z`.
6. Watch the `Release` workflow run for the new tag (`gh run list --workflow=release.yml -L 1`, then `gh run watch <id>`). Report failures verbatim — don't paper over them.
7. Verify the tap landed: fetch `../homebrew-tap` and check the relevant `Formula/*.rb` now has the new version and a fresh commit. If the tap step failed (commonly a stale `HOMEBREW_TAP_TOKEN`), say so explicitly rather than reporting success.
8. Report the release URL and formula status. Don't push to `../homebrew-tap` directly yourself — the workflow owns that.
