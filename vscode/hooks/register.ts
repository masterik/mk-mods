import type { EngineInterface, Register, ThemeSetArgs } from 'claude-code'

import { makeColors } from './make-colors.js'

// VS Code's default themes, extensions/theme-defaults/themes/2026-{light,dark}.json in
// https://github.com/microsoft/vscode (MIT).

/** The whole look: Light 2026 in light mode, Dark 2026 in dark. */
export function buildLook(): { look: ThemeSetArgs; problems: string[] } {
  const { theme, problems } = makeColors({
    label: 'VS Code Light / Dark 2026',
    id: 'vscode-2026',
    light: {
      gray: {
        // Side bar, panels and widgets are `#FAFAFD`; the editor and active tab white, so cards sit
        // lighter than the page.
        anchors: {
          'surface-0': '#fafafd',
          'surface-1': '#ffffff',
          'surface-2': '#ffffff',
          'surface-3': '#ffffff',
          'text-primary': '#202020', // foreground
          'text-muted': '#606060', // descriptionForeground
        },
      },
      roles: {
        accent: '#0069cc', // button, link, focus
        danger: '#ad0707', // errorForeground
        success: '#388a34', // charts.green
        warning: '#895503', // chat.editedFileForeground
        pro: '#8250df', // function names
      },
      git: {
        added: '#587c0c',
        removed: '#ad0707',
        modified: '#667309',
        merged: '#652d90', // charts.purple
        closed: '#ad0707',
        conflicting: '#ad0707',
        draft: '#8e8e90', // ignored
      },
    },
    dark: {
      gray: {
        // The editor `#121314` carries the chat column, side panel and composer strip alike; the
        // side bar and panels step to `#191A1B`, widgets and menus to `#202122`.
        anchors: {
          'surface-0': '#121314',
          'surface-1': '#121314',
          'surface-2': '#191a1b',
          'surface-3': '#202122',
          'text-primary': '#bfbfbf', // foreground
          'text-muted': '#8c8c8c', // descriptionForeground
        },
      },
      roles: {
        accent: '#3994bc', // focusBorder, panelTitle.activeBorder
        danger: '#f48771', // errorForeground
        success: '#73c991', // gitDecoration added
        warning: '#e5ba7d', // list.warningForeground
        pro: '#d2a8ff', // function names
      },
      git: {
        added: '#73c991',
        removed: '#f48771',
        modified: '#e5ba7d',
        merged: '#ad80d7', // charts.purple
        closed: '#f48771',
        conflicting: '#f48771',
        draft: '#8c8c8c', // ignored
      },
    },
    // 2026's token colors are GitHub's.
    codeTheme: { light: 'github-light', dark: 'github-dark' },
  })

  // The person's bubble: `chat.requestBubbleBackground` laid over the editor.
  const inputs = theme.inputs as Record<'light' | 'dark', Record<string, string> | undefined>
  if (inputs.light) {
    inputs.light['bg-user-message'] = '#edf4fb' // #0069CC12 on #FFFFFF
    inputs.light['text-user-message'] = '#202020'
  }
  if (inputs.dark) {
    inputs.dark['bg-user-message'] = '#242526' // #ffffff13 on #121314
    inputs.dark['text-user-message'] = '#bfbfbf'
  }

  // The ground behind the conversation is the editor: white light, `#121314` dark.
  return { look: { colors: theme, backdrop: { color: 'surface-1' } }, problems }
}

async function apply($: EngineInterface): Promise<void> {
  const { look, problems } = buildLook()
  const unpainted = problems.find(line => line.startsWith("Desktop won't paint"))
  if (unpainted !== undefined) {
    $.ui.toast(unpainted)
  }
  let set
  try {
    set = await $.theme.set(look)
  } catch (error) {
    // A build that takes no backdrop: the colors alone.
    $.ui.log(String(error))
    set = await $.theme.set({ colors: look.colors })
  }
  // Clears a reason left from an earlier set once the theme draws.
  $.ui.status(set.isDrawn ? undefined : set.reason)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await apply($)
    return next(e)
  })

  // A session can start before any app attaches; set the look again once one that draws it joins.
  on('session.attach', async ($, e, next) => {
    const result = await next(e)
    if (e.surface === 'desktop' || e.surface === 'mobile') {
      await apply($)
    }
    return result
  })
}
