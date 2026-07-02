# Release process fixtures

Canonical shape of the release process shared by every repo in [`danhorst/homebrew-tap`][1]: promote `CHANGELOG.md`'s `[Unreleased]` section, tag, push, and let CI create the GitHub release and update the tap formula.

Extracted from five existing repos, which converge on two artifact-type flavors:

| Repo             | Flavor           | Version bump in source       | Build/test step                        |
| ---------------- | ---------------- | ---------------------------- | -------------------------------------- |
| after-midnight   | `github-tarball` | none                         | Swift (in CI's build, not release.yml) |
| md-tools         | `github-tarball` | `internal/cli/version.go`    | `go vet/test/build`                    |
| photo-management | `github-tarball` | none (ldflags at build time) | `go vet/test/build`                    |
| wrk              | `github-tarball` | the `wrk` script itself      | none                                   |
| gemkeeper        | `rubygems-gem`   | `lib/gemkeeper/version.rb`   | none (handled by CI's gem build step)  |

## Layout

```
github-tarball/scripts-release   used when Homebrew builds from the GitHub source tarball
github-tarball/release.yml
rubygems-gem/scripts-release     used when Homebrew installs a published RubyGem
rubygems-gem/release.yml
CHANGELOG.template.md            Keep a Changelog starting point
```

## Variation points

Both flavors' `scripts-release` and `release.yml` carry `__PLACEHOLDER__` tokens to fill in when bootstrapping a new repo (see the `bootstrap-release` skill):

- `__REPO__` — repo name under `danhorst/` (e.g. `md-tools`).
- `__FORMULA_NAME__` — the formula's filename (without `.rb`) in `homebrew-tap/Formula/`. Usually matches `__REPO__`, but not always (`photo-management` → `pm.rb`).
- `__GEM_NAME__` — RubyGems package name (`rubygems-gem` flavor only).
- `__VERSION_FILE_PATH__` / `__VERSION_PATTERN__` / `__VERSION_REPLACEMENT__` — only relevant to `github-tarball` repos that hardcode their version in source (three of four don't need this; see the table above). Uncomment the relevant blocks in `scripts-release` and extend the CI's `re.sub` calls to also patch the source file if the tap formula needs a version derived from it — usually it doesn't, since `url`/`sha256` alone are enough for a tarball build.

Repos that verify a build before tagging (`go vet`/`test`/`build`, `bundle exec rspec`, etc.) add that as a commented-out step in `release.yml`; uncomment and adapt per language.

Each repo also needs a `HOMEBREW_TAP_TOKEN` secret — a PAT with write access to `danhorst/homebrew-tap` — set via `gh secret set HOMEBREW_TAP_TOKEN --repo danhorst/<repo>`.
`bootstrap-release` doesn't set this for you.

[1]: https://github.com/danhorst/homebrew-tap
