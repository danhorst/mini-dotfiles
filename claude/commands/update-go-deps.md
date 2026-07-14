Check this repo's Go module dependencies for updates, apply them, verify the build and tests, and hand off to `/release`.
Go-specific — applies to any repo with a `go.mod`.

Resolve `CLAUDE_ROOT="$(dirname "$(readlink ~/.claude/commands)")"` (see dotfiles/claude/README.md).
`$CLAUDE_ROOT/fixtures/update-go-deps/README.md` documents the shape this follows.

## Steps

1. Confirm `go.mod` exists. If not, this skill doesn't apply — stop.
2. Confirm `scripts/update-deps` exists. If missing, copy it from `$CLAUDE_ROOT/fixtures/update-go-deps/scripts-update-deps` and `chmod +x`.
3. Run `scripts/update-deps`. It refuses on a dirty tree, lists outdated modules, runs `go get -u ./...` + `go mod tidy`, then `go vet`/`go build`, then confirms nothing's left outdated.
4. Run the repo's test command (its `test` skill if one exists, else `go test ./...` or `make test`). Don't proceed past a failing test — report it and stop.
5. Draft a `CHANGELOG.md` `[Unreleased]` entry under `### Changes`, one line per bumped module (old → new version), using the `git diff go.mod` output from step 3.
6. If any open Dependabot PRs are now superseded by this update, note that in the report; only close them if DBH confirms.
7. Show DBH the diff (`go.mod`, `go.sum`, `CHANGELOG.md`) and confirm before committing.
8. Suggest running `/release` next — don't tag or release yourself.
