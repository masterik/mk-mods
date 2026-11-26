# AGENTS.md

**mkit-themes** — Claude Code theme mods, one plugin per top-level folder (`catppuccin/`). Listed in
`masterik/mk-toolkit`'s `.claude-plugin/marketplace.json` as `git-subdir` sources
(`url: masterik/mkit-themes`, `path: <theme>`); no marketplace file here. Claude Code only.

## Rules

- Be concise: cut words, never facts.
- A theme is a mod: `.claude-plugin/plugin.json`, `hooks/hooks.json` → `hooks/register.ts`
  (`$.theme.set` at `session.start`), tests in `tests/*.test.ts`.
- `hooks/make-colors.js`/`.d.ts` are vendored verbatim from Claude Code's plugin-authoring kit; never
  edit; re-copy when the build updates and rerun `just check` (contrast rules move with the design system).
- No colors key by hand: build with `makeColors`; keep every `"Desktop won't paint"` problem at zero
  (each theme's test asserts it).
- Never write into the real home folder while testing.

## Commands

```bash
just check                       # validate + test every theme (what CI runs)
just release [bump]              # one version for every theme + tag vX.Y.Z, asks before pushing
claude --plugin-dir ./catppuccin # load one live
```

## Release

One version per repo, independent of mkit's: `tools/release.sh [auto|patch|minor|major|X.Y.Z]` bumps
every `*/.claude-plugin/plugin.json` to it. auto reads Conventional Commits since the last tag (`feat` →
minor, breaking → major, minor pre-1.0, else patch); first release = the highest manifest version.
Tag `vX.Y.Z` → `release.yml` makes the GitHub Release (notes from commits since the previous tag).
Users get `main`; the version bump is what triggers their update. A release bumps every theme, changed
or not. New theme: add the folder (its `plugin.json` at any version ≤ the current one), then its entry in
mk-toolkit's marketplace.
