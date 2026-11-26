# Run `just` for the list, `just <recipe>` to run one.

# validate and test every theme — what CI runs (needs the `claude` CLI)
check:
	for d in */.claude-plugin/plugin.json; do t=${d%%/*}; claude plugin validate "$t" && claude plugin test "$t" || exit 1; done

# bump every theme to one version, commit, tag vX.Y.Z and push after a confirmation — auto (default), patch|minor|major or X.Y.Z
release BUMP="auto":
	tools/release.sh {{BUMP}}
