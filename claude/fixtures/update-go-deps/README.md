# Go dependency update fixture

Canonical `scripts/update-deps` for Go repos: list outdated modules, `go get -u`, `go mod tidy`, verify with `vet`/`build`, confirm nothing's left stale.
Used by the `update-go-deps` skill.

Go-only.
Applicability is a mechanical check (does the repo have a `go.mod`?), not a fixed list — the repos in [`danhorst/homebrew-tap`][1] span Go, Swift, Ruby, and plain-script, so this only fits a subset and that subset will change over time.

## Layout

```
scripts-update-deps   copy to <repo>/scripts/update-deps, chmod +x
```

No `__PLACEHOLDER__` tokens — the script is identical across repos, since it only reads `go.mod`/`go.sum` in the current directory and takes no repo-specific configuration.

[1]: https://github.com/danhorst/homebrew-tap
