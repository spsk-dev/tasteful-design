# SpSk Demo Recording
# Simulates a /design-review run with branded output
#
# Usage:
#   vhs assets/demo.tape
#
# After recording:
#   gifsicle --lossy=80 --optimize=3 --colors 64 -o assets/demo.gif assets/demo-raw.gif

Output assets/demo-raw.gif
Set Shell bash
Set FontSize 14
Set FontFamily "Geist Mono"
Set Width 1200
Set Height 800
Set Theme "Catppuccin Mocha"
Set WindowBar Colorful
Set TypingSpeed 40ms
Set Padding 20

# Scene 1: Type the command (2s)
Type "claude /design-review http://localhost:3000"
Sleep 500ms
Enter
Sleep 1.5s

# Scene 2: Signature line (1s)
Type " SpSk  design-review  v1.1.0  ───  8 specialists  ·  tier 1"
Enter
Sleep 1s

# Scene 3: Specialist boxes scrolling by (8-10s)

# Typography specialist
Enter
Type "┌─ TYPOGRAPHY ─────────────────────────────────────────────────┐"
Enter
Type "│  ████████░░ 8.0/10                                           │"
Enter
Type "│  ✓ Font hierarchy clear -- DM Sans + Instrument Serif        │"
Enter
Type "│  ✓ Body text 18px, line-height 1.6                           │"
Enter
Type "│  ✗ Hero text needs negative letter-spacing at 64px           │"
Enter
Type "└──────────────────────────────────────────────────────────────┘"
Enter
Sleep 1.5s

# Color specialist
Type "┌─ COLOR ──────────────────────────────────────────────────────┐"
Enter
Type "│  ███████░░░ 7.0/10                                           │"
Enter
Type "│  ✓ Palette follows 60/30/10 rule                             │"
Enter
Type "│  ✓ WCAG AA contrast ratios pass on all text                  │"
Enter
Type "│  ⚠ Accent overused in secondary sections                    │"
Enter
Type "└──────────────────────────────────────────────────────────────┘"
Enter
Sleep 1.5s

# Layout specialist
Type "┌─ LAYOUT ─────────────────────────────────────────────────────┐"
Enter
Type "│  █████████░ 9.0/10                                           │"
Enter
Type "│  ✓ Consistent 8px grid spacing                               │"
Enter
Type "│  ✓ Responsive breakpoints at 768px and 1024px                │"
Enter
Type "│  ✓ Section rhythm varies -- no monotonous repetition         │"
Enter
Type "└──────────────────────────────────────────────────────────────┘"
Enter
Sleep 1.5s

# Intent specialist
Type "┌─ INTENT / ORIGINALITY / UX ──────────────────────────────────┐"
Enter
Type "│  ████████░░ 8.0/10  ·  ████████░░ 8.0/10  ·  ███████░░░ 7.0 │"
Enter
Type "│  ✓ Design matches landing page intent -- conversion-focused  │"
Enter
Type "│  ✓ CTA visible above fold, action hierarchy clear            │"
Enter
Type "│  ✗ Secondary CTA competes with primary -- reduce prominence  │"
Enter
Type "└──────────────────────────────────────────────────────────────┘"
Enter
Sleep 1.5s

# Scene 4: Summary of remaining specialists (1s)
Enter
Type "  ... 4 more specialists evaluated (Icon, Motion, Copy, Code/A11y)"
Enter
Sleep 1s

# Scene 5: Final verdict box (3s)
Enter
Type "┌─ VERDICT ────────────────────────────────────────────────────┐"
Enter
Type "│  ████████░░ 8.2/10  ·  SHIP                                 │"
Enter
Type "│                                                               │"
Enter
Type "│  8 specialists  ·  6 passed  ·  2 conditional                │"
Enter
Type "│  Top fix: reduce secondary CTA prominence                    │"
Enter
Type "└──────────────────────────────────────────────────────────────┘"
Enter
Sleep 1.5s

# Scene 6: Footer (1s)
Enter
Type "github.com/spsk-dev/tasteful-design"
Enter
Sleep 2s
