# ChalkLens Design System

## Direction

ChalkLens uses premium utilitarian minimalism: warm document surfaces,
plain classroom language, clear hierarchy, and color used only when it helps
the teacher understand state.

The interface should feel like a quiet notebook for making lessons, not a
marketing site. A Grade 3 to Grade 5 student should be able to understand the
main actions without explanation.

## Palette

- Canvas: `#FBFBFA`
- Surface: `#FFFFFF`
- Muted surface: `#F7F6F3`
- Border: `#EAEAEA`
- Primary ink: `#2F3437`
- Muted ink: `#787774`
- Subtle ink: `#9B9996`

Muted semantic washes:

- Blue: `#E1F3FE`, text `#1F6C9F`
- Green: `#EDF3EC`, text `#346538`
- Red: `#FDEBEC`, text `#9F2F2D`
- Yellow: `#FBF3DB`, text `#956400`
- Lavender: `#F3EFF8`, text `#5B4A6B`

## Rules

- Keep cards flat with a single `1px` border.
- Use radius `4px` for buttons, `6px` for controls, and `8px` for cards.
- Use off-black, never pure black.
- Keep shadows absent or below `0.05` opacity.
- Do not use gradients, neon colors, glass effects, or bright brand blocks.
- Use pastel washes only for compact status, icon tiles, and instructional
  hints.
- Keep display text short and concrete.
- Avoid AI copywriting cliches. Say what the app is doing.

## Key Flows

Launch:

- Show a short splash screen with the ChalkLens mark.
- Check offline AI readiness.
- Send ready users to Home; send setup users to Model Setup.

Home:

- Lead with `Make today's lesson easy.`
- Show the three-step path: Add page, Choose class, Teach.
- Keep secondary actions quieter than the main lesson action.

Scan:

- Treat the page as three small steps.
- Support photo first, text paste second.
- Use child-friendly labels: Class, Language, Lesson time, Help level.

Generation:

- Never show only a spinner.
- Keep the user in the loop with staged messages:
  Reading page, choosing level, writing notes, making questions, checking kit.
