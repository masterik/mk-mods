# mk-mods

Themes for the Claude Code desktop and mobile apps, as Claude Code mods. Each folder is one plugin,
listed in the [mkit marketplace](https://github.com/masterik/mk-toolkit). The repo releases as one: one
version for every theme, independent of mkit's.

| Theme | Does |
| --- | --- |
| [`catppuccin`](catppuccin/README.md) | Catppuccin: Latte light; Frappé, Macchiato or Mocha dark; 14 accents. |
| [`vscode`](vscode/README.md) | VS Code's default Light 2026 / Dark 2026. |

## Install

```
/plugin marketplace add masterik/mk-toolkit
/plugin install catppuccin@masterik
/plugin install vscode@masterik
```

The terminal draws no theme; the desktop and mobile apps do.

## Develop

- `just check` — `claude plugin validate` + `claude plugin test` for every theme (needs `claude`).
- Load a theme live: `claude --plugin-dir ./catppuccin`.
- `just release [auto|patch|minor|major|X.Y.Z]` — bump every theme's `plugin.json` to one version,
  commit, tag `vX.Y.Z`, push; the tag makes the GitHub Release. Claude Code offers the update once the
  version on `main` changes.

## License

[MIT](LICENSE).
