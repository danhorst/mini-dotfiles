Wire a new repo into the standard homebrew-tap release process: `scripts/release`, `.github/workflows/release.yml`, a CHANGELOG template, and a Formula stub in `homebrew-tap`.
Resolve `CLAUDE_ROOT="$(dirname "$(readlink ~/.claude/commands)")"` (see dotfiles/claude/README.md).
Canonical fixtures live in `$CLAUDE_ROOT/fixtures/release/` — read `fixtures/release/README.md` first; it documents both flavors and every `__PLACEHOLDER__`.

## Steps

1. Identify the target repo's artifact type:
   - **github-tarball** — Homebrew builds from `archive/refs/tags/vX.Y.Z.tar.gz`. Used by Swift, Go, and plain-script projects (after-midnight, md-tools, photo-management, wrk).
   - **rubygems-gem** — Homebrew installs a published gem. Only applies to Ruby gems (gemkeeper).
   If ambiguous, ask DBH rather than guessing.

2. Copy the matching flavor's `scripts-release` → `<repo>/scripts/release` (`chmod +x`) and `release.yml` → `<repo>/.github/workflows/release.yml`. Fill in `__REPO__`, `__FORMULA_NAME__`, and — for `rubygems-gem` — `__GEM_NAME__`.

3. Decide whether the repo hardcodes its version in source (gemkeeper, md-tools, and wrk do; after-midnight and photo-management don't). If yes, uncomment and fill the version-bump block in `scripts/release`, and extend the dirty-check exclusion to cover that file. If no, leave those blocks commented out.

4. If `CHANGELOG.md` doesn't exist, create it from `CHANGELOG.template.md`. If it exists, confirm it already has a `## [Unreleased]` header in Keep a Changelog format — don't overwrite existing entries.

5. Add a Formula stub to `../homebrew-tap/Formula/<name>.rb` and a matching entry to `../homebrew-tap/README.md`, following the shape of the existing formulas. This touches a second repo — show DBH the diff before committing there.

6. Tell DBH to set the `HOMEBREW_TAP_TOKEN` secret on the new repo: `gh secret set HOMEBREW_TAP_TOKEN --repo danhorst/<repo>` with a PAT that has write access to `danhorst/homebrew-tap`. Don't source or set the token value yourself.

7. Report the new/changed files across both repos for DBH's review. Don't commit either repo automatically.
