# mkit-themes

Themes for the Claude Code desktop and mobile apps, as Claude Code mods. Each folder is one plugin,
listed in the [mkit marketplace](https://github.com/masterik/mk-toolkit) and released on its own.

| Theme | Does |
| --- | --- |
| [`catppuccin`](catppuccin/README.md) | Catppuccin: Latte light; Frappé, Macchiato or Mocha dark; 14 accents. |

## Install

```
/plugin marketplace add masterik/mk-toolkit
/plugin install catppuccin@masterik
```

The terminal draws no theme; the desktop and mobile apps do.

## Develop

- `just check` — `claude plugin validate` + `claude plugin test` for every theme (needs `claude`).
- Load a theme live: `claude --plugin-dir ./catppuccin`.
- `just release <theme> [auto|patch|minor|major|X.Y.Z]` — bump the theme's `plugin.json`, commit,
  tag `<theme>-vX.Y.Z`, push; the tag makes the GitHub Release. Claude Code offers the update once the
  version on `main` changes.

## License

[MIT](LICENSE).
