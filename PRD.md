# NIGHTOUT Product Requirements Document
## Ultra-Polish Redesign v2.0

---

## Executive Summary

NIGHTOUT is "Strava for going out" - a social party tracking app that lets users track their nights out with friends, log drinks, capture moments, and share summaries. This PRD details the pixel-perfect UI redesign based on reference screenshots.

---

## Screen-by-Screen Specifications

### 1. Sign Up / Sign In Screen

#### Visual Hierarchy (Top to Bottom)

```
┌─────────────────────────────────────┐
│                                     │
│        ┌─────────────────┐          │
│        │     🪩           │          │  ← Disco ball (80pt) with purple glow ring
│        │   (glow ring)   │          │
│        └─────────────────┘          │
│                                     │
│           NIGHTOUT                  │  ← Title: 34pt bold white
│                                     │
│    ┌─────────────────────────┐      │
│    │  Sign In  │  Sign Up    │      │  ← Toggle pills
│    └─────────────────────────┘      │
│                                     │
│    ┌─────────────────────────┐      │
│    │ 📧  Email                │      │  ← Input field
│    └─────────────────────────┘      │
│                                     │
│    ┌─────────────────────────┐      │
│    │ @  Username             │      │  ← Input field
│    └─────────────────────────┘      │
│                                     │
│    ┌─────────────────────────┐      │
│    │ 🔒  Password            │      │  ← Secure field
│    └─────────────────────────┘      │
│                                     │
│    ┌─────────────────────────┐      │
│    │ 🔒  Confirm Password    │      │  ← Secure field
│    └─────────────────────────┘      │
│                                     │
│    ╔═════════════════════════╗      │
│    ║   Create Account 🎉     ║      │  ← Gradient button
│    ╚═════════════════════════╝      │
│                                     │
│    By signing up, you agree to      │  ← Legal text: 12pt silver
│    our terms and conditions         │
│                                     │
│      Continue as Guest →            │  ← Link: 15pt silver
│      Some features require sign in  │  ← Subtitle: 11pt dimmed
│                                     │
└─────────────────────────────────────┘
```

#### Component Specifications

**Background**
- Type: Radial gradient
- Center: Top-center of screen
- Colors: Dark purple (#1A0A20) fading to black (#000000)
- Additional: Subtle vignette effect around edges

**Disco Ball Logo**
- Size: 80x80pt
- Emoji: 🪩 (or custom asset)
- Container: Circle with purple stroke
- Stroke: 3pt, purple gradient (#8B5CF6)
- Glow: Purple shadow, 20pt radius, 50% opacity
- Animation: Subtle slow rotation (optional)

**App Title**
- Text: "NIGHTOUT"
- Font: 34pt, bold, SF Pro Rounded
- Color: White (#FFFFFF)
- Letter spacing: 2pt
- Position: 16pt below logo

**Sign In / Sign Up Toggle**
- Container width: Full width - 32pt margins
- Height: 48pt
- Background: #1A1A1E
- Corner radius: 24pt (pill)
- Padding: 4pt internal
- Each segment:
  - Width: 50%
  - Height: 40pt
  - Corner radius: 20pt
  - Selected background: #2A2A30
  - Selected text: White, 15pt semibold
  - Unselected text: Silver, 15pt regular

**Input Fields**
- Width: Full width - 32pt margins
- Height: 56pt
- Background: #1A1A1E
- Border: 1pt, white 10% opacity
- Corner radius: 12pt
- Icon: Left-aligned, 16pt from edge
- Icon size: 20pt
- Icon color: Silver (#A0A0A8)
- Placeholder: 17pt, #606068
- Text: 17pt, white
- Padding: 16pt left (after icon), 16pt right
- Spacing between fields: 16pt

**Create Account Button**
- Width: Full width - 32pt margins
- Height: 56pt
- Corner radius: 16pt
- Gradient: #FF6B9D → #8B5CF6 (left to right)
- Text: "Create Account 🎉"
- Font: 17pt, semibold, white
- Shadow: #8B5CF6 at 40% opacity, radius 16, y: 4
- Top margin: 24pt from last field

**Terms Text**
- Font: 12pt, regular
- Color: Silver
- Alignment: Center
- Top margin: 16pt

**Continue as Guest**
- Main text: 15pt, silver, "Continue as Guest →"
- Subtitle: 11pt, dimmed, "Some features require sign in"
- Top margin: 24pt
- Bottom margin: 40pt from bottom safe area

---

### 2. Profile Screen

#### Visual Hierarchy

```
┌─────────────────────────────────────┐
│  Profile                    ⚙️      │  ← Nav bar: title + settings icon
├─────────────────────────────────────┤
│                                     │
│           ┌─────────┐               │
│           │  👤     │               │  ← Avatar (100pt) with placeholder
│           │    📷   │               │  ← Camera badge (28pt, purple)
│           └─────────┘               │
│                                     │
│          henryvanti                 │  ← Username: 22pt bold white
│   Living for the nights I'll       │  ← Bio: 15pt silver
│   never remember 🪩                 │
│                                     │
│     1        0        10           │  ← Stats row
│   Nights   Friends   Posts         │
│                                     │
│    ┌─────────────────────┐         │
│    │  ✏️  Edit Profile   │         │  ← Edit button (pill)
│    └─────────────────────┘         │
│                                     │
│  YOUR NIGHTS            See All    │  ← Section header
│  ┌──────────┐ ┌──────────┐         │
│  │    🪩    │ │    🪩    │         │  ← Night cards (2-col grid)
│  │   00:05  │ │   00:03  │         │
│  │ Untitled │ │ Untitled │         │
│  │ Tuesday  │ │ Tuesday  │         │
│  └──────────┘ └──────────┘         │
│  ┌──────────┐ ┌──────────┐         │
│  │    🪩    │ │    🪩    │         │
│  │   00:44  │ │   00:55  │         │
│  │ Untitled │ │ Untitled │         │
│  │ Monday   │ │ Sunday   │         │
│  └──────────┘ └──────────┘         │
│                                     │
├─────────────────────────────────────┤
│  🏠    🔴    🪩    📊    👤        │  ← Tab bar
│ Feed  Live  Track Stats Profile    │
└─────────────────────────────────────┘
```

#### Component Specifications

**Navigation Bar**
- Background: Transparent (black background shows through)
- Title: "Profile" - 17pt semibold, white, centered
- Right icon: gearshape (settings) - 22pt, white

**Avatar Section**
- Avatar size: 100x100pt
- Avatar background: #2A2A30
- Default icon: person.fill, 48pt, blue-gray
- Border: None (clean edge)
- Camera badge:
  - Size: 28x28pt
  - Position: Bottom-right of avatar, offset -4pt
  - Background: Purple (#8B5CF6)
  - Icon: camera, 14pt, white
  - Corner radius: 50% (circle)

**Username**
- Font: 22pt, bold, white
- Top margin: 16pt from avatar

**Bio**
- Font: 15pt, regular, silver
- Max lines: 2
- Alignment: Center
- Top margin: 4pt from username
- Max width: 280pt

**Stats Row**
- Layout: 3 equal columns
- Top margin: 20pt from bio
- Number: 22pt bold, white
- Label: 11pt medium, silver
- Spacing between number and label: 4pt

**Edit Profile Button**
- Width: Auto (content + 32pt padding)
- Height: 40pt
- Corner radius: 20pt (pill)
- Background: #2A2A30
- Border: None
- Content: "✏️ Edit Profile"
- Font: 15pt, medium, white
- Top margin: 16pt from stats

**Your Nights Section**
- Header:
  - "YOUR NIGHTS" - 12pt medium, silver, uppercase, tracking 1pt
  - "See All" - 12pt medium, purple (#8B5CF6)
  - Top margin: 32pt from edit button
- Grid:
  - Columns: 2
  - Gap: 12pt
  - Top margin: 12pt from header

**Night Card (Grid Item)**
- Aspect ratio: Square (1:1)
- Background: #1A1A1E
- Corner radius: 16pt
- Padding: 16pt
- Content layout (top to bottom):
  - Disco ball emoji: 🪩, 32pt, centered
  - Duration: 15pt regular, white, centered, 8pt below emoji
  - Title: 15pt semibold, white, left-aligned, at bottom
  - Date: 11pt regular, silver, left-aligned, 4pt below title

---

### 3. Stats Screen

#### Visual Hierarchy

```
┌─────────────────────────────────────┐
│              Stats                  │  ← Nav bar title
├─────────────────────────────────────┤
│                                     │
│  ALL TIME                          │  ← Section header
│                                     │
│  ┌──────────┐ ┌──────────┐         │
│  │    🌙    │ │    ⏱️    │         │
│  │    13    │ │    1h    │         │
│  │  Nights  │ │  Total   │         │
│  └──────────┘ └──────────┘         │
│                                     │
│  ┌──────────┐ ┌──────────┐         │
│  │    🏃    │ │    🍺    │         │
│  │  0.4 mi  │ │    12    │         │
│  │ Distance │ │  Drinks  │         │
│  └──────────┘ └──────────┘         │
│                                     │
│  ┌──────────┐ ┌──────────┐         │
│  │    🎵    │ │    📸    │         │
│  │    0     │ │    0     │         │
│  │  Songs   │ │  Photos  │         │
│  └──────────┘ └──────────┘         │
│                                     │
│  THIS MONTH           December 2025 │  ← Section header
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │     📊 Activity Chart       │   │  ← Chart placeholder
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ACHIEVEMENTS           See All    │  ← Section header
│  ...                               │
│                                     │
├─────────────────────────────────────┤
│  🏠    🔴    🪩    📊    👤        │
└─────────────────────────────────────┘
```

#### Component Specifications

**Navigation Bar**
- Title: "Stats" - 17pt semibold, white, centered
- Style: Large title display mode (optional)

**Section Headers**
- Text: Uppercase, 12pt medium, silver
- Letter spacing: 1pt
- Left-aligned with 16pt margin
- Bottom margin: 12pt

**Stat Cards Grid**
- Columns: 2
- Gap: 12pt
- Margin: 16pt horizontal

**Stat Card**
- Size: Equal width, ~165pt each
- Height: Auto (content-based), ~110pt
- Background: #1A1A1E
- Corner radius: 16pt
- Padding: 16pt
- Content (centered, vertical stack):
  - Emoji: 28pt
  - Value: 36pt bold, white
  - Label: 11pt medium, silver
- Spacing: 8pt between each element

**Stat Card Content**

| Position | Emoji | Value Format | Label |
|----------|-------|--------------|-------|
| Row 1, Col 1 | 🌙 | Integer | "Nights" |
| Row 1, Col 2 | ⏱️ | "Xh" format | "Total" |
| Row 2, Col 1 | 🏃 | "X.X mi" | "Distance" |
| Row 2, Col 2 | 🍺 | Integer | "Drinks" |
| Row 3, Col 1 | 🎵 | Integer | "Songs" |
| Row 3, Col 2 | 📸 | Integer | "Photos" |

**This Month Section**
- Left text: "THIS MONTH" - 12pt medium, silver
- Right text: Month + Year (e.g., "December 2025") - 12pt medium, white
- Top margin: 24pt from stat grid

**Activity Chart Card**
- Width: Full width - 32pt
- Height: 120pt minimum
- Background: #1A1A1E
- Corner radius: 16pt
- When empty:
  - Icon: 📊 emoji, 32pt, centered
  - Label: "Activity Chart" - 15pt regular, silver
- Top margin: 12pt from section header

**Achievements Section**
- Header: Same style as other sections
- "See All" link: 12pt medium, purple
- Top margin: 24pt from chart

---

### 4. Active Tracking Screen

#### Visual Hierarchy

```
┌─────────────────────────────────────┐
│ 🔴I     Your Night          👥    │  ← Header: rec indicator, title, friends
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │     00:00:01        🔴👥   │   │  ← Timer card with glass effect
│  │   "Saturday vibes"          │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │  ← Stats pills row
│  │🏃0.0│ │🍺 0 │ │📸 0 │ │📍 0 │   │
│  │ mi  │ │drnk │ │pics │ │spot │   │
│  └─────┘ └─────┘ └─────┘ └─────┘   │
│                                     │
│         (Map Background)            │  ← Full-screen dark map
│              📍                     │  ← User location pin (blue dot)
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📸  │  🎵  │  ✨  │  📍   │   │  ← Quick action buttons
│  │Photo│ Song │ Vibe │ Spot  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ╔═══════════════════════╗    🌙   │
│  ║  🍺  Add Drink        ║         │  ← Add drink FAB + moon button
│  ╚═══════════════════════╝         │
│                                     │
├─────────────────────────────────────┤
│  🏠    🔴      LIVE     📊    👤   │  ← Tab bar with LIVE center
└─────────────────────────────────────┘
```

#### Component Specifications

**Header Bar**
- Left: Recording indicator (red dot + "I")
- Center: "Your Night" - 17pt semibold, white
- Right: Friends icon (👥 silhouettes) - 24pt, teal

**Recording Indicator**
- Red circle: 8pt diameter, solid red (#EF4444)
- Container: Pill shape, red 15% opacity background
- Border: 1pt, red 30% opacity
- Padding: 8pt horizontal, 4pt vertical
- Position: Top-left safe area

**Timer Card**
- Background: White 8% opacity + ultraThinMaterial blur
- Border: White 15% opacity, 1pt
- Corner radius: 16pt
- Margin: 16pt horizontal
- Padding: 20pt internal
- Content:
  - Timer: 56pt bold, white, monospaced
  - Format: "00:00:00"
  - Vibe name: 15pt regular, silver, in quotes
  - Right side: Red dot (6pt) + friends icon

**Stats Pills Row**
- Layout: Horizontal scroll
- Gap: 8pt
- Margin: 16pt horizontal, 12pt top

**Stat Pill**
- Height: 36pt
- Corner radius: 18pt (pill)
- Background: White 8% + material
- Padding: 12pt horizontal
- Content: Emoji (16pt) + Value (15pt bold) + Label (11pt silver)
- Spacing: 4pt between elements

**Map Background**
- Type: MapKit with dark style
- User location: Blue pulsing dot
- Coverage: Full screen behind content
- Overlay: Subtle dark gradient at top and bottom

**Quick Action Buttons Container**
- Background: #1A1A1E at 90% opacity
- Corner radius: 16pt
- Margin: 16pt horizontal
- Padding: 12pt

**Quick Action Button**
- Layout: Vertical (emoji + label)
- Emoji: 24pt
- Label: 11pt, silver
- Width: 25% each (4 buttons)
- Tap target: Full cell

**Add Drink FAB**
- Width: ~75% of screen width
- Height: 56pt
- Corner radius: 28pt (pill)
- Gradient: Light pink (#FF6B9D) → Magenta (#C850C0)
- Shadow: Pink (#FF2D92) at 50% opacity, radius 20, y: 8
- Content: 🍺 (24pt) + "Add Drink" (17pt semibold white)

**Moon Button (End Night)**
- Size: 56x56pt
- Corner radius: 28pt (circle)
- Background: #1A1A1E
- Border: White 10% opacity, 1pt
- Icon: 🌙 (24pt)
- Position: Right of Add Drink FAB

---

### 5. Custom Tab Bar

#### Visual Hierarchy

```
┌─────────────────────────────────────┐
│  🏠    🔴      🪩       📊    👤   │
│ Feed  Live   Track   Stats Profile │
│        ↑       ↑                    │
│     red dot  disco ball             │
│              raised up              │
└─────────────────────────────────────┘
```

#### Component Specifications

**Container**
- Height: 83pt (49pt content + 34pt safe area)
- Background: ultraThinMaterial + black 50% overlay
- Top border: 1pt gradient (white 10% → transparent)

**Tab Items (4 side tabs)**
- Icon size: 24pt
- Label: 10pt medium
- Spacing: 4pt between icon and label
- Width: Equal distribution (excluding center)
- Active tint: Pink (#FF2D92)
- Inactive tint: Silver (#A0A0A8)

**Tab Icons**
| Tab | SF Symbol | Label |
|-----|-----------|-------|
| Feed | house.fill | "Feed" |
| Live | circle.fill (red) | "Live" |
| Stats | chart.bar.fill | "Stats" |
| Profile | person.fill | "Profile" |

**Center Track Button**
- Size: 64x64pt
- Offset: -12pt above tab bar baseline
- Container: Circle with purple ring glow
- Content when idle:
  - Disco ball emoji: 🪩, 32pt
  - Label: "Track" - 10pt, silver
  - Ring: Purple (#8B5CF6), 2pt stroke
  - Glow: Purple 30% opacity, radius 12
- Content when recording:
  - Red pulsing glow
  - "LIVE" text badge
  - Red (#EF4444) pulse animation

**Live Dot (on Live tab)**
- Size: 8pt diameter
- Color: Red (#EF4444)
- Position: Top-right of icon
- Animation: Pulse (scale 1.0 ↔ 1.2)

---

## Interaction Specifications

### Button Press States

**Primary Button (Gradient)**
```
Rest → Press → Release
Scale: 1.0 → 0.95 → 1.0
Duration: 150ms (spring)
Haptic: Light impact
```

**Secondary Button (Glass)**
```
Rest → Press → Release
Scale: 1.0 → 0.97 → 1.0
Opacity: 1.0 → 0.8 → 1.0
Duration: 100ms
Haptic: Light impact
```

### Tab Bar Selection

```
Tap → Selection
Icon scale: 1.0 → 1.1 → 1.0
Color: Silver → Pink (instant)
Duration: 200ms
Haptic: Selection feedback
```

### Timer Counter

```
Every second:
Transition: numericText()
Duration: 300ms (spring)
```

### Pull to Refresh

```
Pull → Threshold → Release → Loading → Done
Scale: 1.0 → 1.02 → 1.0
Indicator: Circular progress, pink tint
Duration: 300ms
Haptic: Medium impact on threshold
```

---

## Accessibility Specifications

### Color Contrast
- Primary text (white on black): 21:1 ✓
- Secondary text (silver on black): 7.5:1 ✓
- Disabled text (dimmed on black): 3.5:1 ✓

### Touch Targets
- Minimum: 44x44pt (all interactive elements)
- Buttons: 56pt height
- Tab bar items: 44pt minimum width

### VoiceOver Labels
- All buttons have descriptive labels
- Stats announce "X nights out, Y hours total" etc.
- Timer announces current duration

### Reduce Motion
- Pulse animations disabled
- Instant state changes
- No parallax effects

---

## Technical Implementation Notes

### SwiftUI Best Practices

1. **@Observable** for state management (not @ObservableObject)
2. **NavigationStack** (not NavigationView)
3. **Timer callbacks** wrapped in `Task { @MainActor in }`
4. **Services** use `@unchecked Sendable` (not @MainActor)
5. **PhotosPicker** always includes `photoLibrary: .shared()`

### iOS 18+ Hit Testing

```swift
// Correct pattern
Button(action: {}) {
    // content
}
.buttonStyle(.plain)
.contentShape(Rectangle())  // AFTER buttonStyle
```

### Performance Considerations

1. Use `LazyVGrid` for night cards grid
2. Use `AsyncImage` with placeholder for avatars
3. Minimize view re-renders with `@State` isolation
4. Cache profile data to reduce network calls

---

*Document Version: 2.0*
*Last Updated: December 2024*
