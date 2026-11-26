# Run `just` for the list, `just <recipe>` to run one.

# validate and test every theme — what CI runs (needs the `claude` CLI)
check:
	for d in */.claude-plugin/plugin.json; do t=${d%%/*}; claude plugin validate "$t" && claude plugin test "$t" || exit 1; done

# bump, commit, tag and push one theme's release after a confirmation
release THEME BUMP="auto":
	tools/release.sh {{THEME}} {{BUMP}}
