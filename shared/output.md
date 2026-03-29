# SpSk Branded Output Reference

This file defines the visual identity for ALL SpSk command output. Load this via `@${CLAUDE_PLUGIN_ROOT}/shared/output.md` in every command file.

**Every SpSk command output MUST follow this format.** Start with the signature line, use single-line boxes for sections, end with the footer. Keep output compact and professional -- no big ASCII art.

---

## Signature Line

The first line of every command output. Read version dynamically from `${CLAUDE_PLUGIN_ROOT}/VERSION`.

```
 SpSk  {command}  v{version}  ───  {specialist_count} specialists  ·  tier {tier}
```

- **{command}**: the command name (`design-review`, `design-improve`, `design-validate`, `design-init`)
- **{version}**: read from `${CLAUDE_PLUGIN_ROOT}/VERSION` (currently `1.0.0`)
- **{specialist_count}**: `8` for full mode, `4` for quick mode (`--quick`)
- **{tier}**: from environment detection:
  - Tier 1: Gemini + Playwright available (full capability)
  - Tier 2: Playwright only, no Gemini (Claude handles all specialists)
  - Tier 3: No Playwright (code-only analysis)

**Example:**
```
 SpSk  design-review  v1.0.0  ───  8 specialists  ·  tier 1
```

---

## Score Bar

Scores are displayed as filled/empty block bars on a **/10 display scale**.

- **Internal scale:** 1.0 to 4.0 (used in scoring logic)
- **Display scale:** Multiply internal by 2.5 to get /10 display value: `display = internal * 2.5`
- **Bar:** 10 blocks total. Filled blocks = `round(internal * 2.5)`. Filled char: `█`, empty char: `░`
- **Format:** `{bar} {display_value}/10`

### Conversion Examples

| Internal | Display | Filled Blocks | Bar |
|----------|---------|---------------|-----|
| 4.0 | 10.0 | 10 | `██████████ 10.0/10` |
| 3.2 | 8.0 | 8 | `████████░░ 8.0/10` |
| 2.8 | 7.0 | 7 | `███████░░░ 7.0/10` |
| 2.0 | 5.0 | 5 | `█████░░░░░ 5.0/10` |
| 1.0 | 2.5 | 3 | `███░░░░░░░ 2.5/10` |

**IMPORTANT:** Always display scores as /10 to users. The internal 1.0-4.0 scale is never shown directly. Conversion formula: `internal * 2.5 = display`.

---

## Symbol Vocabulary

Use these symbols consistently across all output:

| Symbol | Meaning | Usage |
|--------|---------|-------|
| `✓` | Pass / Complete | Checks that passed, items done |
| `✗` | Fail / Missing | Checks that failed, items missing |
| `◆` | In Progress | Currently executing specialist |
| `○` | Pending | Queued specialist, not yet started |
| `⚡` | Auto-approved | Checkpoints auto-approved in auto mode |
| `⚠` | Warning | Non-blocking issues, degraded capability |

---

## Box Drawing

Use **single-line** Unicode box characters for all sections and results. Do NOT use double-line characters.

**Correct (SpSk style):**
```
┌─────────────────────────────────────────────────────────────┐
│  Content here                                               │
└─────────────────────────────────────────────────────────────┘
```

Characters: `┌ ─ ┐ │ └ ┘`

**WRONG -- do NOT use double-line box drawing (that is GSD style, not SpSk).** Banned characters: double-line top-left, double horizontal, double top-right, double vertical, double bottom-left, double bottom-right. If you see any double-line box characters in SpSk output, replace them with the single-line equivalents above.

---

## Section Headers

Use single-line box for section headers within review output. The section name appears inline with the top border:

```
┌─ TYPOGRAPHY ─────────────────────────────────────────────────┐
│  ████████░░ 8.0/10                                           │
│  ✓ Font hierarchy clear                                      │
│  ✗ Body text too small (14px, recommend 16-18px)             │
└──────────────────────────────────────────────────────────────┘
```

```
┌─ COLOR ──────────────────────────────────────────────────────┐
│  █████░░░░░ 5.0/10                                           │
│  ✓ Contrast ratios pass WCAG AA                              │
│  ✗ Palette lacks cohesion -- too many unrelated hues         │
│  ⚠ Consider reducing to 3-4 core colors                     │
└──────────────────────────────────────────────────────────────┘
```

---

## Verdict Display

The final verdict uses a box with the overall score:

```
┌─ VERDICT ────────────────────────────────────────────────────┐
│  ████████░░ 8.0/10  ·  SHIP                                 │
│                                                               │
│  8 specialists  ·  6 passed  ·  2 conditional                │
└──────────────────────────────────────────────────────────────┘
```

Verdict values: `SHIP`, `CONDITIONAL`, `BLOCK`

---

## Footer

Every SpSk command output ends with this footer line. Always the last line, separated by a blank line from content above:

```
github.com/spsk-dev/tasteful-design
```

---

## Complete Output Structure

Every SpSk command output follows this order:

1. **Signature line** (always first)
2. **Section boxes** (specialist results, findings, etc.)
3. **Verdict box** (for review commands)
4. **Footer** (always last)

Minimal example:
```
 SpSk  design-review  v1.0.0  ───  8 specialists  ·  tier 1

┌─ TYPOGRAPHY ─────────────────────────────────────────────────┐
│  ████████░░ 8.0/10                                           │
│  ✓ Font hierarchy clear                                      │
│  ✓ Body text readable (18px)                                 │
└──────────────────────────────────────────────────────────────┘

┌─ VERDICT ────────────────────────────────────────────────────┐
│  ████████░░ 8.0/10  ·  SHIP                                 │
└──────────────────────────────────────────────────────────────┘

github.com/spsk-dev/tasteful-design
```
