---
name: design-init
description: >
  Interactive setup wizard for design tokens. Creates .design/ directory with
  tokens.json (colors, fonts, mode) and config.json (page type, vibe preset).
  Run once per project. Takes under 2 minutes.
allowed-tools: Read, Write, Bash(mkdir *)
---

# Design Init -- Project Setup Wizard

Set up design tokens for this project through 5 quick questions. Creates `.design/` directory with `tokens.json` and `config.json` that all other design commands use for context-aware reviews and builds.

Load branding reference for output formatting:
@${CLAUDE_PLUGIN_ROOT}/shared/output.md

## Question 1: Page Type

Use AskUserQuestion to ask the user what type of page they are building. Present these options:

```
What type of page are you building?

1. landing   -- Landing pages, marketing sites, product pages
2. dashboard -- Data dashboards, analytics, admin panels
3. admin     -- Back-office tools, CMS, internal tools
4. docs      -- Documentation sites, knowledge bases, wikis
5. portfolio -- Personal sites, showcases, creative portfolios
```

Default: `landing`

Store the selected value as `page_type`. Valid values: `landing`, `dashboard`, `admin`, `docs`, `portfolio`.

## Question 2: Vibe Preset

Read the style presets file to get descriptions for each vibe:
@${CLAUDE_PLUGIN_ROOT}/config/style-presets.json

Use AskUserQuestion to present vibe options with human-friendly labels. Show the `description` field from each preset as context.

```
What vibe are you going for?

1. Corporate -- Clean, functional, data-dense. Think Linear, Grafana, Vercel Dashboard.
2. Editorial -- Typography-driven, content-first, quiet elegance. Think Medium, iA Writer, Monocle.
3. Playful   -- Playful, warm, personality-forward. Think Notion, Figma, Slack.
4. Bold      -- Bold, conversion-focused, energetic. Think Vercel homepage, Linear landing, Raycast.
5. Minimal   -- Motion-forward, cinematic, immersive. Think Apple, Stripe, Vercel.
```

Map the human-friendly label to the internal preset key:

| User Selection | Preset Key           |
|----------------|----------------------|
| Corporate      | `serious-dashboard`  |
| Editorial      | `minimal-editorial`  |
| Playful        | `fun-lighthearted`   |
| Bold           | `startup-landing`    |
| Minimal        | `animation-heavy`    |

Default based on page type:

| Page Type   | Default Preset Key   |
|-------------|----------------------|
| landing     | `startup-landing`    |
| dashboard   | `serious-dashboard`  |
| admin       | `serious-dashboard`  |
| docs        | `minimal-editorial`  |
| portfolio   | `animation-heavy`    |

Store the mapped preset key as `vibe_preset`.

## Question 3: Mode

Use AskUserQuestion to ask the user's mode preference:

```
Light or dark mode?

1. light -- Light background, dark text
2. dark  -- Dark background, light text
3. both  -- Support both (tokens for dark mode, review checks both)
```

Default: `dark`

Store the selected value as `mode`.

## Question 4: Brand Colors

Use AskUserQuestion to ask for brand colors:

```
Do you have brand colors? Enter hex values (e.g., "primary: #0F172A, accent: #3B82F6") or type "skip" for palette suggestions.
```

### If user provides colors

Parse the hex values from their response. Map them to the token fields:
- `primary` -- Main brand color
- `secondary` -- Supporting color (derive from primary if not provided, slightly lighter/darker)
- `accent` -- Highlight/CTA color
- `background` -- Page background (derive from mode if not provided: `#FFFFFF` for light, `#0A0A0B` for dark)
- `foreground` -- Text color (derive from mode if not provided: `#0F172A` for light, `#FAFAFA` for dark)
- `muted` -- Subdued text/borders (derive from primary if not provided)

### If user types "skip" (or similar: "none", "no", "suggest", empty)

Read the palette data:
@${CLAUDE_PLUGIN_ROOT}/config/palettes.json

Look up the `page_type` selected in Q1. This gives an array of 3 named palettes.

Use AskUserQuestion to present the 3 palettes:

```
Here are 3 palettes designed for {page_type} pages:

1. {palette_1_name}
   primary: {primary}  secondary: {secondary}  accent: {accent}
   background: {background}  foreground: {foreground}  muted: {muted}

2. {palette_2_name}
   primary: {primary}  secondary: {secondary}  accent: {accent}
   background: {background}  foreground: {foreground}  muted: {muted}

3. {palette_3_name}
   primary: {primary}  secondary: {secondary}  accent: {accent}
   background: {background}  foreground: {foreground}  muted: {muted}

Pick a palette (1, 2, or 3):
```

Use the selected palette's colors for the token values.

## Question 5: Font Preference

Use AskUserQuestion to ask for font preference:

```
Font preference? Enter a font name (e.g., "Geist", "Inter", "Instrument Serif") or type "skip" for a suggestion based on your vibe.
```

### If user provides a font name

Use it as `primary` font. Derive `secondary` font as a complementary choice:
- If user chose a sans-serif: secondary is a serif (e.g., "Instrument Serif")
- If user chose a serif: secondary is a sans-serif (e.g., "Geist")

### If user types "skip" (or similar: "suggest", "default", empty)

Read the vibe preset's typography field from:
@${CLAUDE_PLUGIN_ROOT}/config/style-presets.json

Extract the primary font recommendation from the `typography` field of the selected vibe preset:

| Vibe Preset          | Primary Font       | Secondary Font     |
|----------------------|--------------------|--------------------|
| `serious-dashboard`  | Geist              | DM Sans            |
| `minimal-editorial`  | Instrument Serif   | Geist              |
| `fun-lighthearted`   | Plus Jakarta Sans  | Nunito             |
| `startup-landing`    | Geist              | General Sans       |
| `animation-heavy`    | Clash Display      | Cabinet Grotesk    |

Suggest the font to the user: "Based on your {vibe_label} vibe, I'd suggest **{primary_font}**. Using that."

Set `mono` font to `Geist Mono` (consistent SpSk default).

## Output: Create .design/ Directory

After all 5 questions are answered, create the output files.

**IMPORTANT:** Create `.design/` in the user's current working directory (CWD), NOT inside `${CLAUDE_PLUGIN_ROOT}`. This is a project-level configuration directory.

### Step 1: Create directory

```bash
mkdir -p .design
```

### Step 2: Write .design/tokens.json

Write the following structure using the collected answers:

```json
{
  "colors": {
    "primary": "{from Q4}",
    "secondary": "{from Q4}",
    "accent": "{from Q4}",
    "background": "{from Q4}",
    "foreground": "{from Q4}",
    "muted": "{from Q4}"
  },
  "fonts": {
    "primary": "{from Q5}",
    "secondary": "{from Q5}",
    "mono": "Geist Mono"
  },
  "mode": "{from Q3}"
}
```

### Step 3: Write .design/config.json

Write the following structure:

```json
{
  "page_type": "{from Q1}",
  "vibe_preset": "{mapped preset key from Q2}",
  "initialized": "{current ISO-8601 timestamp}"
}
```

## Completion Message

After writing both files, display a branded summary using the output format from `shared/output.md`.

Show:

```
┌──────────────────────────────────────────────────────────────┐
│  DESIGN INIT COMPLETE                                        │
└──────────────────────────────────────────────────────────────┘

  Page type:    {page_type}
  Vibe:         {vibe_label} ({vibe_preset})
  Mode:         {mode}
  Primary:      {primary_color}  ██
  Accent:       {accent_color}   ██
  Font:         {primary_font}

  Created:
    ✓ .design/tokens.json   (colors, fonts, mode)
    ✓ .design/config.json   (page type, vibe, timestamp)

  Next: Run /design review to get your first design review.

                                        github.com/spsk-dev/tasteful-design
```
