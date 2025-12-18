# NIGHTOUT Design System v2.0
## Pixel-Perfect Specification Guide

> Extracted from reference screenshots with exact measurements, colors, and typography.

---

## Table of Contents
1. [Color Palette](#color-palette)
2. [Typography](#typography)
3. [Spacing System](#spacing-system)
4. [Corner Radius](#corner-radius)
5. [Glass Effects](#glass-effects)
6. [Shadows & Glows](#shadows--glows)
7. [Components](#components)
8. [Animations](#animations)
9. [Icons & Emojis](#icons--emojis)

---

## Color Palette

### Primary Colors

| Color Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| **Deep Black** | `#000000` | `0, 0, 0` | Primary background |
| **Void Black** | `#0A0A0C` | `10, 10, 12` | Card backgrounds |
| **Surface Dark** | `#1A1A1E` | `26, 26, 30` | Elevated surfaces, input fields |
| **Surface Medium** | `#2A2A30` | `42, 42, 48` | Borders, dividers |

### Text Colors

| Color Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| **Chrome White** | `#FFFFFF` | `255, 255, 255` | Primary text, titles |
| **Silver** | `#A0A0A8` | `160, 160, 168` | Secondary text, labels |
| **Dimmed** | `#606068` | `96, 96, 104` | Placeholder text, disabled |
| **Muted** | `#404048` | `64, 64, 72` | Very subtle text |

### Accent Colors

| Color Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| **Party Purple** | `#8B5CF6` | `139, 92, 246` | Primary accent, buttons |
| **Neon Pink** | `#FF2D92` | `255, 45, 146` | Highlights, active states |
| **Electric Blue** | `#3B82F6` | `59, 130, 246` | Links, info states |
| **Live Red** | `#EF4444` | `239, 68, 68` | Recording, live indicators |
| **Success Green** | `#22C55E` | `34, 197, 94` | Success states |
| **Golden Hour** | `#F59E0B` | `245, 158, 11` | Achievements, highlights |
| **Yellow Accent** | `#FACC15` | `250, 204, 21` | Stars, badges |

### Gradient Definitions

```swift
// Primary CTA Gradient (Pink to Purple)
LinearGradient(
    colors: [
        Color(hex: "#FF2D92"),  // Neon Pink
        Color(hex: "#8B5CF6")   // Party Purple
    ],
    startPoint: .leading,
    endPoint: .trailing
)

// Add Drink Button Gradient
LinearGradient(
    colors: [
        Color(hex: "#FF6B9D"),  // Light Pink
        Color(hex: "#C850C0")   // Magenta
    ],
    startPoint: .leading,
    endPoint: .trailing
)

// Purple Glow Ring (Disco Ball)
RadialGradient(
    colors: [
        Color(hex: "#8B5CF6").opacity(0.6),
        Color(hex: "#8B5CF6").opacity(0.0)
    ],
    center: .center,
    startRadius: 50,
    endRadius: 80
)

// Background Vignette
RadialGradient(
    colors: [
        Color(hex: "#1A0A20"),  // Dark purple tint
        Color(hex: "#000000")
    ],
    center: .top,
    startRadius: 0,
    endRadius: 600
)
```

---

## Typography

### Font Family
**SF Pro Rounded** - Used throughout for a friendly, approachable feel.

### Type Scale

| Style | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|--------|-------------|----------------|-------|
| **Timer Display** | 56pt | Bold | 1.0 | -1pt | Active tracking timer |
| **Large Title** | 34pt | Bold | 1.1 | 0 | Screen titles |
| **Title 1** | 28pt | Bold | 1.15 | 0 | Section headers |
| **Title 2** | 22pt | Bold | 1.2 | 0 | Card titles |
| **Title 3** | 20pt | Semibold | 1.25 | 0 | Subsection headers |
| **Headline** | 17pt | Semibold | 1.3 | 0 | Button text, important labels |
| **Body** | 17pt | Regular | 1.4 | 0 | Body text |
| **Subheadline** | 15pt | Regular | 1.35 | 0 | Supporting text |
| **Footnote** | 13pt | Regular | 1.4 | 0 | Small labels |
| **Caption 1** | 12pt | Medium | 1.3 | 0.2pt | Section headers, badges |
| **Caption 2** | 11pt | Regular | 1.3 | 0 | Timestamps, metadata |
| **Stat Number** | 36pt | Bold | 1.0 | -0.5pt | Statistics display |
| **Stat Label** | 11pt | Medium | 1.3 | 0.5pt | Stats labels (uppercase) |

### Swift Implementation

```swift
enum NightOutTypography {
    // Display
    static let timerDisplay = Font.system(size: 56, weight: .bold, design: .rounded)

    // Titles
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)

    // Body
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)

    // Small
    static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)

    // Special
    static let statNumber = Font.system(size: 36, weight: .bold, design: .rounded)
    static let statLabel = Font.system(size: 11, weight: .medium, design: .rounded)
}
```

---

## Spacing System

### Base Unit: 4pt

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4pt | Tight spacing, icon gaps |
| `sm` | 8pt | Small gaps, inline spacing |
| `md` | 12pt | Default element spacing |
| `lg` | 16pt | Section spacing |
| `xl` | 20pt | Large section gaps |
| `xxl` | 24pt | Major section dividers |
| `xxxl` | 32pt | Screen sections |
| `huge` | 48pt | Hero spacing |

### Screen Margins

| Context | Value |
|---------|-------|
| Horizontal padding | 16pt |
| Vertical padding | 20pt |
| Card internal padding | 16pt |
| Safe area bottom | 34pt (with tab bar) |

---

## Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4pt | Small badges |
| `sm` | 8pt | Small buttons, tags |
| `md` | 12pt | Input fields, small cards |
| `lg` | 16pt | Cards, buttons |
| `xl` | 20pt | Large cards |
| `xxl` | 24pt | Modal sheets |
| `pill` | 9999pt | Pills, full rounded |
| `circle` | 50% | Avatars, circular buttons |

### Component-Specific Radius

| Component | Radius |
|-----------|--------|
| Input fields | 12pt |
| Primary buttons | 16pt |
| Stat cards | 16pt |
| Tab bar | 0pt (rectangular) |
| Avatar | 50% (circle) |
| Night card | 16pt |
| Stat pill | 20pt |

---

## Glass Effects

### Glass Card (Stats, Profile Cards)

```swift
// Background
Color(hex: "#1A1A1E")  // Solid dark, not transparent

// Border
Color.white.opacity(0.08)  // 1pt width

// No blur - solid dark cards work better than glass blur
```

### Glass Input Field

```swift
// Background
Color(hex: "#1A1A1E")

// Border
Color.white.opacity(0.1)  // 1pt width, subtle

// Placeholder
Color(hex: "#606068")

// Icon tint
Color(hex: "#A0A0A8")
```

### Timer Card (Active Tracking)

```swift
// Background
Color.white.opacity(0.08)
    .background(.ultraThinMaterial)

// Border
Color.white.opacity(0.15)  // 1pt

// Corner radius
16pt
```

---

## Shadows & Glows

### Button Glow

```swift
// Primary button (pink/purple gradient)
.shadow(color: Color(hex: "#8B5CF6").opacity(0.4), radius: 16, y: 4)

// Add Drink button (pink)
.shadow(color: Color(hex: "#FF2D92").opacity(0.5), radius: 20, y: 8)
```

### Live Indicator Glow

```swift
// Pulsing red glow
.shadow(color: Color(hex: "#EF4444").opacity(0.6), radius: isPulsing ? 12 : 6)
```

### Disco Ball Glow

```swift
// Purple ring around logo
Circle()
    .stroke(
        LinearGradient(
            colors: [
                Color(hex: "#8B5CF6").opacity(0.8),
                Color(hex: "#8B5CF6").opacity(0.3)
            ],
            startPoint: .top,
            endPoint: .bottom
        ),
        lineWidth: 3
    )
    .shadow(color: Color(hex: "#8B5CF6").opacity(0.5), radius: 20)
```

---

## Components

### 1. Sign Up Screen Components

#### Logo Section
```
- Disco ball: 80pt diameter
- Purple glow ring: 3pt stroke, extends 10pt beyond ball
- Title "NIGHTOUT": 34pt bold, white
- Spacing below logo: 32pt
```

#### Sign In/Sign Up Toggle
```
- Container: pill shape, dark background (#1A1A1E)
- Padding: 4pt
- Each option:
  - Width: 50%
  - Height: 40pt
  - Selected: lighter background (#2A2A30), white text
  - Unselected: transparent, gray text
- Corner radius: pill (20pt)
```

#### Input Fields
```
- Height: 56pt
- Corner radius: 12pt
- Background: #1A1A1E
- Border: 1pt, white 10% opacity
- Icon: left aligned, 24pt from edge
- Placeholder: #606068
- Text: white, 17pt
- Internal padding: 16pt horizontal
```

#### Primary Button (Create Account)
```
- Height: 56pt
- Corner radius: 16pt
- Gradient: pink (#FF6B9D) to purple (#8B5CF6)
- Text: white, 17pt semibold
- Shadow: purple 40% opacity, radius 16, y 4
- Emoji suffix: 24pt party popper
```

### 2. Profile Screen Components

#### Avatar Section
```
- Avatar size: 100pt
- Camera badge: 28pt diameter, purple (#8B5CF6) background
- Camera badge offset: bottom-right of avatar
- Username: 22pt bold, white
- Bio: 15pt regular, silver
```

#### Stats Row
```
- Three columns, equal width
- Number: 22pt bold, white
- Label: 11pt medium, silver, uppercase
- Vertical spacing: 4pt
```

#### Edit Profile Button
```
- Height: 40pt
- Corner radius: 20pt (pill)
- Background: #2A2A30
- Text: 15pt medium, white
- Pencil emoji prefix
```

#### Your Nights Section
```
- Header: "YOUR NIGHTS" - 12pt medium, silver, uppercase
- "See All" link: 12pt medium, purple
- Grid: 2 columns, 12pt gap
```

#### Night Card (Grid Item)
```
- Aspect ratio: 1:1 (square)
- Corner radius: 16pt
- Background: #1A1A1E
- Content:
  - Disco ball emoji: centered, 32pt
  - Duration: below emoji, 15pt, white
  - Title: bottom-left, 15pt semibold, white
  - Date: below title, 11pt, silver
```

### 3. Stats Screen Components

#### Section Header
```
- Text: "ALL TIME" - 12pt medium, silver, uppercase
- Bottom margin: 12pt
```

#### Stat Card (2x3 Grid)
```
- Corner radius: 16pt
- Background: #1A1A1E
- Padding: 16pt
- Content centered:
  - Emoji: 28pt, top
  - Value: 36pt bold, white, middle
  - Label: 11pt medium, silver, bottom
- Grid gap: 12pt
```

#### Stat Card Emojis
| Stat | Emoji |
|------|-------|
| Nights | 🌙 |
| Total Time | ⏱️ |
| Distance | 🏃 |
| Drinks | 🍺 |
| Songs | 🎵 |
| Photos | 📸 |

#### Activity Chart Card
```
- Full width
- Corner radius: 16pt
- Background: #1A1A1E
- Height: 120pt minimum
- Centered icon when empty: 📊 32pt
- Label: "Activity Chart" - 15pt, silver
```

### 4. Active Tracking Screen Components

#### Recording Indicator (Top Left)
```
- Red circle: 8pt diameter
- "I" indicator: red, 12pt
- Container: pill shape, red 15% background
- Padding: 8pt horizontal, 4pt vertical
```

#### Timer Card
```
- Background: glass effect (white 8% + ultraThinMaterial)
- Corner radius: 16pt
- Timer: 56pt bold, white, monospaced digits
- Format: "00:00:00" (HH:MM:SS)
- Vibe name: 15pt, silver, in quotes
- Friends indicator: red dot + silhouette icon, right side
```

#### Stats Pills Row
```
- Horizontal scroll
- Pill shape, corner radius 20pt
- Background: white 8% + material
- Content: emoji + value + label
- Spacing: 8pt between pills
```

| Pill | Emoji | Format |
|------|-------|--------|
| Distance | 🏃 | "0.0 mi" |
| Drinks | 🍺 | "0 drinks" |
| Photos | 📸 | "0 pics" |
| Spots | 📍 | "0 spots" |

#### Quick Action Buttons
```
- Container: dark card (#1A1A1E), rounded corners 16pt
- Layout: horizontal, 4 items
- Each item:
  - Emoji icon: 24pt
  - Label: 11pt, silver
  - Vertical stack, centered
```

| Action | Emoji |
|--------|-------|
| Photo | 📸🔥 (with sparkle) |
| Song | 🎵 |
| Vibe | ✨ |
| Spot | 📍 |

#### Add Drink FAB
```
- Width: ~80% of screen
- Height: 56pt
- Corner radius: 28pt (pill)
- Gradient: light pink to magenta
- Icon: 🍺 beer mug, 24pt
- Text: "Add Drink" - 17pt semibold, white
- Shadow: pink 50%, radius 20, y 8
```

#### Moon Button (End Night)
```
- Size: 56pt diameter
- Background: #1A1A1E
- Icon: 🌙 moon, 24pt
- Border: white 10% opacity
```

### 5. Custom Tab Bar

#### Container
```
- Background: ultraThinMaterial + dark overlay
- Top border: 1pt, white 10% opacity gradient fade
- Height: 83pt (49pt content + 34pt safe area)
- Padding: horizontal 12pt
```

#### Tab Items (5 total)
```
- Icon size: 24pt
- Label size: 10pt
- Spacing between icon and label: 4pt
- Active color: varies by tab (pink for selected)
- Inactive color: silver (#A0A0A8)
```

| Tab | Icon | Label | Active Tint |
|-----|------|-------|-------------|
| Feed | 🏠 | "Feed" | Pink |
| Live | 🔴 | "Live" | Red |
| Track | 🪩 (center) | "Track" | N/A |
| Stats | 📊 | "Stats" | Pink |
| Profile | 👤 | "Profile" | Pink |

#### Center Track Button
```
- Size: 64pt diameter
- Offset: -12pt above tab bar
- Background:
  - Inactive: purple ring with disco ball
  - Active: red pulsing glow
- When recording: "LIVE" label, red text
```

---

## Animations

### Timing Functions

| Name | Curve | Duration | Usage |
|------|-------|----------|-------|
| Quick | easeOut | 150ms | Button feedback |
| Standard | easeInOut | 250ms | State changes |
| Smooth | easeInOut | 350ms | Page transitions |
| Bouncy | spring(0.4, 0.6) | N/A | Fun interactions |
| Snappy | spring(0.25, 0.7) | N/A | Tap responses |

### Specific Animations

#### Pulse (Live Indicator)
```swift
Animation.easeInOut(duration: 1.0)
    .repeatForever(autoreverses: true)
// Scale: 1.0 <-> 1.2
// Opacity: 1.0 <-> 0.7
```

#### Button Press
```swift
Animation.spring(response: 0.25, dampingFraction: 0.7)
// Scale: 1.0 -> 0.95 -> 1.0
```

#### Counter Transition
```swift
.contentTransition(.numericText())
.animation(.spring(response: 0.3, dampingFraction: 0.8), value: count)
```

---

## Icons & Emojis

### System Icons (SF Symbols)

| Usage | Icon Name | Weight |
|-------|-----------|--------|
| Home tab | house.fill | Regular |
| Live tab | circle.fill | Regular |
| Stats tab | chart.bar.fill | Regular |
| Profile tab | person.fill | Regular |
| Settings | gearshape | Regular |
| Camera | camera.fill | Regular |
| Close | xmark | Semibold |
| Chevron | chevron.right | Semibold |
| Location | location.fill | Regular |
| Edit | pencil | Regular |

### Emoji Usage

| Context | Emoji | Size |
|---------|-------|------|
| Logo | 🪩 | 80pt |
| Night card | 🪩 | 32pt |
| Stats - Nights | 🌙 | 28pt |
| Stats - Time | ⏱️ | 28pt |
| Stats - Distance | 🏃 | 28pt |
| Stats - Drinks | 🍺 | 28pt |
| Stats - Songs | 🎵 | 28pt |
| Stats - Photos | 📸 | 28pt |
| Input - Email | 📧 | 20pt |
| Input - Username | @ | 20pt (text) |
| Input - Password | 🔒 | 20pt |
| Button - Create | 🎉 | 20pt |
| Button - Edit | ✏️ | 16pt |
| Add Drink | 🍺 | 24pt |
| Moon/End | 🌙 | 24pt |

---

## Implementation Checklist

### Design Tokens
- [ ] Update NightOutColors with exact hex values
- [ ] Update NightOutTypography with exact sizes
- [ ] Update NightOutSpacing with exact values
- [ ] Update NightOutRadius with exact values

### Components
- [ ] Create DiscoBalLogo component
- [ ] Create GlassInputField component
- [ ] Create PrimaryGradientButton component
- [ ] Create StatCard component
- [ ] Create NightGridCard component
- [ ] Create StatsRoll component
- [ ] Create QuickActionPill component
- [ ] Create AddDrinkFAB component
- [ ] Create CustomTabBar component

### Screens
- [ ] SignUpView - Full redesign
- [ ] ProfileView - Full redesign
- [ ] StatsView - Full redesign
- [ ] ActiveTrackingView - Full redesign
- [ ] MainTabView - Tab bar update

---

*Last updated: December 2024*
*Version: 2.0*
