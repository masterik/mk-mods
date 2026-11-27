import { expect, test } from 'claude-code/testing'

import { buildLook } from '../hooks/register'

test('both modes paint on Desktop', () => {
  const { problems } = buildLook()
  expect(problems.filter(line => line.startsWith("Desktop won't paint"))).toEqual([])
})
