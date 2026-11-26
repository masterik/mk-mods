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
just release catppuccin [bump]   # per-theme version + tag <theme>-vX.Y.Z, asks before pushing
claude --plugin-dir ./catppuccin # load one live
```

## Release

Per theme, independent: `tools/release.sh <theme> [auto|patch|minor|major|X.Y.Z]`. auto reads
Conventional Commits touching `<theme>/` since its last tag (`feat` → minor, breaking → major, minor
pre-1.0, else patch). Tag `<theme>-vX.Y.Z` → `release.yml` makes the GitHub Release (notes from commits
since the theme's previous tag). Users get `main`; the version bump is what triggers their update.
New theme: add the folder, then its entry in mk-toolkit's marketplace.
