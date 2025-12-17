# NIGHTOUT iOS App - Development Guidelines

> **CRITICAL**: This document prevents App Store rejections. Follow ALL patterns exactly.
> Last updated: December 2024 (iOS 26.1 / Swift 6.2 / Supabase SDK 2.5.1)

---

# COMPREHENSIVE REBUILD PLAN

## Vision Statement
**"Strava for going out"** - NIGHTOUT is the ultimate social party tracking app where you start your night like starting a run in Strava, track your adventures with friends in real-time, capture moments with dual-camera photos, log drinks with beautiful skeuomorphic emojis, see friends live on the map, and share your epic night summaries to your feed.

---

## UI REFERENCE SCREENSHOTS ANALYSIS

### OLDNIGHOUTUI_CLAUDE/ (10 screens - Target Design)

| File | Screen | Key Elements |
|------|--------|--------------|
| `IMG_7939` | **Sign Up** | NIGHTOUT logo with moon icon, dark gradient background, email/username/password fields, purple gradient "Create Account" button, "Continue as Guest" link |
| `IMG_7940` | **Feed** | Header with profile pic + "Feed" title, cards showing user avatar, username, timestamp, night title, stat row (duration, distance, drinks, photos), emoji reaction buttons, bottom tab bar |
| `IMG_7941` | **Live Map** | Full-screen dark map, red "LIVE" indicator, user location pin, purple gradient "Share My Location" button, tab bar with Feed/Live/Record/Stats/Profile |
| `IMG_7942` | **Start Your Night** | Moon icon header "Start Your Night", vibe name input, visibility toggle (Friends/Public/Off), "Who's with you?" friend selector, purple gradient "Let's Go!" button |
| `IMG_7943` | **Active Tracking** | Timer (00:00:01), map background, stats row (drinks/photos/mood/distance), quick action buttons, pink gradient "Add Drink" FAB |
| `IMG_7944` | **Night Complete** | Checkmark header "NIGHT COMPLETE", date/time, stats grid (duration/distance/drinks/photos/venues/mood), "Share to Story" button, Save/Post to Feed actions |
| `IMG_7945` | **Share Your Night** | Cancel/title, night name input, caption field, tag friends, import from camera roll, visibility selector, purple "Post to Feed" button |
| `IMG_7946` | **Stats** | "Stats" header, all-time stats grid (Nights/Hours/Distance/Drinks/Photos/Venues), monthly activity chart, achievements section |
| `IMG_7947` | **Profile** | Avatar, username, bio, stats row (Nights/Following/Friends), "Edit Profile" button, "YOUR NIGHTS" grid of past nights |
| `IMG_7948` | **Settings** | Email, Change Password, Privacy Settings, Blocked Users, Location Sharing, Help & FAQ, Contact Us, app version, Delete Account (red), Sign Out |

### BEERBUDDY_CLAUDE/ (5 screens - Design Inspiration)

| File | Screen | Genius Design Elements to Adopt |
|------|--------|--------------------------------|
| `bb_35b22a6d` | **My Drinking Map** | Stats overlay cards on map, user avatars as map pins with drink counts, floating beer emoji + add button FAB |
| `bb_9303e499` | **Dual Camera** | BeReal-style dual camera capture, selfie preview in corner, flashlight/capture/flip/gallery buttons |
| `bb_1173e7a1` | **Mindful Statistics** | Dry days tracker with emoji faces, line graph comparing friends, "Track Your Drinking Awareness" card |
| `bb_945e6b8b` | **Profile** | SKEUOMORPHIC DRINK EMOJIS in horizontal scroll, photo grid, stats (Checkins/Friends/Rank), "Add your best friends" CTA |
| `bb_633c97a8` | **Friends** | Search bar, "Invite friends"/"Create Group" blue buttons, shareable link, friend suggestions with mutual friends |

### STRAVA_CLAUDE/ (6 screens - UX Flow Reference)

| File | Screen | UX Patterns to Adopt |
|------|--------|---------------------|
| `strava0` | **Pre-Activity** | "GPS SIGNAL ACQUIRED" banner, activity type selector icons, large orange START button |
| `strava1` | **Recording Stats** | Large timer display, split avg pace, distance with bar chart, minimal UI |
| `strava2` | **Paused** | "STOPPED" banner, RESUME/FINISH buttons, map with route, stats below |
| `strava3` | **Save Activity** | Title input, description with @mentions, activity type selector, map preview + "Add Photos/Video", "How did it feel?" prompt |
| `strava4` | **Visibility** | "Who can view" dropdown, "Hidden Details", "Mute Activity" toggle, "Discard Activity" danger action |
| `strava5` | **Activity Feed** | Activity card with user, timestamp, title, stats row, route map, kudos/comments/share icons |

---

## DESIGN SYSTEM ENHANCEMENTS

### Typography: SF Pro Rounded (Already Implemented)
The app already uses SF Pro Rounded throughout - this is the playful, fun font that makes the app feel friendly and approachable.

### Color Palette (Current - Keep)
```swift
// Core Party Palette
neonPink: #FF2D92      // Primary accent - party energy
partyPurple: #A855F7   // Secondary accent - nightlife vibes
electricBlue: #3B82F6  // Tertiary accent - cool contrast
liveRed: #EF4444       // Live/recording status
successGreen: #22C55E  // Success states
goldenHour: #F59E0B    // Achievements/highlights
```

### Skeuomorphic Drink Emojis (NEW - From BeerBuddy)
Add high-quality 3D-style drink emojis for the drink logging experience:
```swift
enum DrinkEmoji {
    static let beer = "🍺"
    static let cocktail = "🍸"
    static let wine = "🍷"
    static let champagne = "🥂"
    static let shot = "🥃"
    static let tropical = "🍹"
    static let martini = "🍸"
    static let sake = "🍶"
    static let apple = "🍏"  // Cider/mocktail
    static let coffee = "☕"  // Non-alcoholic
    static let water = "💧"  // Staying hydrated
}
```

### Microinteractions (NEW - Emotional Design)
Based on research, implement these <500ms microinteractions:
1. **Heart burst** on like - confetti animation like Twitter
2. **Cheers clink** on drink add - glasses clinking with haptic
3. **Fireworks** on night complete - celebration particles
4. **Pulse glow** on live status - breathing neon effect
5. **Bounce** on button press - spring animation
6. **Shimmer** on achievements - gold sparkle sweep

---

## COMPLETE FEATURE BREAKDOWN

### Phase 1: Authentication & Onboarding

#### 1.1 Splash Screen
- Animated NIGHTOUT logo with moon
- Particle effects (stars/sparkles)
- Smooth transition to auth

#### 1.2 Sign Up / Sign In
- Email + password auth (Supabase)
- Social auth (Apple, Google)
- "Continue as Guest" option
- Beautiful gradient CTAs
- Form validation with inline errors

#### 1.3 Onboarding Permissions Flow
```
Screen 1: Welcome
  "Welcome to NIGHTOUT"
  "Track your nights out with friends"
  [Get Started]

Screen 2: Location Permission
  Map illustration with friends pins
  "See friends on the map"
  "We use your location to show you on the live map"
  [Enable Location] [Not Now]

Screen 3: Camera Permission
  Dual camera illustration
  "Capture the moments"
  "Take photos and videos during your night"
  [Enable Camera] [Not Now]

Screen 4: Photo Library
  Photo gallery illustration
  "Add from your gallery"
  "Import photos to your night timeline"
  [Enable Photos] [Not Now]

Screen 5: Notifications
  Bell illustration
  "Stay connected"
  "Get notified when friends start nights"
  [Enable Notifications] [Not Now]

Screen 6: Profile Setup
  Avatar picker (camera/gallery)
  Username input
  Bio input (optional)
  [Complete Setup]
```

### Phase 2: Main Tab Navigation

#### Tab Bar Structure
```
1. Feed (🏠) - Social feed of friends' nights
2. Live (📍) - Real-time map of live friends
3. Record (🔴) - Start/active night tracking (center, prominent)
4. Stats (📊) - Personal statistics & achievements
5. Profile (👤) - User profile & settings
```

### Phase 3: Feed (Home)

#### 3.1 Feed View
- Pull to refresh
- Night cards showing:
  - User avatar + username + timestamp
  - Night title + vibe emoji
  - Stats row: duration | distance | drinks | photos
  - Cover photo/video (if any)
  - Route map preview
  - Reaction buttons (❤️ 🔥 🎉 😂 🍻)
  - Like count + comment count
  - Tag friends who were there

#### 3.2 Night Detail View
- Full night summary
- Timeline of events (drinks, photos, venues, songs)
- Interactive map with route
- Photo/video gallery
- Comments section
- Share options

### Phase 4: Live Map

#### 4.1 Live Friends Map
- Full-screen dark-themed map
- Friend avatars as pins (with drink count badges)
- "LIVE" pulse indicator for active friends
- Current venue name overlay
- "Share My Location" toggle
- Privacy controls (Friends/Public/Off)
- Quick tap to view friend's live night

#### 4.2 Friend Location Card
- Slide-up card showing:
  - Friend's avatar + name
  - Current venue
  - Night duration so far
  - Drink count
  - "Send Cheers" reaction button
  - "Join Night" option

### Phase 5: Night Tracking (Core Feature)

#### 5.1 Start Your Night
- "Start Your Night" header with moon icon
- Vibe name input (optional)
  - Placeholder: "Saturday night vibes..."
- Live visibility toggle:
  - Friends (default)
  - Public
  - Off (stealth mode)
- "Who's with you?" friend selector
  - Search friends
  - Quick select recent friends
- GPS status indicator
- Purple gradient "Let's Go!" button

#### 5.2 Active Tracking View
- Large timer display (00:00:00)
- Mini map showing current location + route
- Stats dashboard:
  - 🍺 Drinks: 0
  - 📸 Photos: 0
  - 😊 Mood: Great
  - 📍 Distance: 0.0 mi
- Quick action buttons:
  - Add Drink (primary FAB)
  - Take Photo/Video
  - Add Venue
  - Log Song
  - Update Mood
- "End Night" button (with confirmation)

#### 5.3 Add Drink Sheet
- Skeuomorphic emoji grid:
  - 🍺 Beer
  - 🍸 Cocktail
  - 🍷 Wine
  - 🥂 Champagne
  - 🥃 Shot
  - 🍹 Tropical
  - Custom drink option
- Quick +1 for same drink type
- Drink count animation
- Haptic feedback (cheers clink)

#### 5.4 Dual Camera Capture (BeReal-style)
- Main camera view (back camera)
- Small selfie preview (front camera)
- Capture both simultaneously
- Flash toggle
- Flip cameras
- Import from gallery option
- Caption input
- Location tag

#### 5.5 Add Venue
- Map with current location
- Nearby places search (using MKLocalSearch)
- Manual entry option
- Venue type icons
- "Arrived at [Venue]" event

#### 5.6 Log Song (Music Integration)
- "What's playing?" prompt
- Apple Music integration (MusicKit)
- Manual entry (title + artist)
- Album artwork display
- Creates timeline event

#### 5.7 Mood Check-in
- "How are you feeling?" prompt
- Emoji scale (1-5):
  - 😴 Tired
  - 😐 Okay
  - 😊 Good
  - 😄 Great
  - 🤩 Amazing
- Creates mood timeline event

### Phase 6: Night Complete & Sharing

#### 6.1 End Night Flow
- Confirmation dialog
- "NIGHT COMPLETE" celebration screen
- Confetti/fireworks animation
- Summary stats display:
  - Duration
  - Distance traveled
  - Drinks logged
  - Photos taken
  - Venues visited
  - Songs logged
  - Peak mood

#### 6.2 Share Your Night
- Night title input
- Caption/description with @mentions
- Tag friends who were there
- Select cover photo/video
- Import additional media
- Visibility selector:
  - Public (everyone)
  - Friends Only
  - Only Me
- "Share to Story" (Instagram/Snapchat style)
- "Post to Feed" button
- "Save Without Posting" option

### Phase 7: Statistics & Achievements

#### 7.1 Stats View
- All-time stats grid:
  - 🌙 Total Nights
  - ⏱️ Total Hours
  - 📍 Total Distance
  - 🍺 Total Drinks
  - 📸 Total Photos
  - 🏠 Venues Visited
- Monthly activity chart
- Weekly comparison
- Personal records:
  - Longest night
  - Most drinks
  - Furthest traveled

#### 7.2 Achievements System
```swift
enum Achievement {
    // Milestone achievements
    case firstNight           // "First Night Out" 🌟
    case nightOwl            // "10 Nights" 🦉
    case partyAnimal         // "50 Nights" 🎉
    case legend              // "100 Nights" 👑

    // Social achievements
    case socialButterfly     // "Added 10 Friends" 🦋
    case squadGoals          // "Night with 5+ friends" 👥
    case popular             // "100 Likes received" ❤️

    // Activity achievements
    case photographer        // "100 Photos taken" 📸
    case barHopper          // "5 Venues in one night" 🏃
    case marathon           // "8+ hour night" ⏰
    case globetrotter       // "10+ miles in one night" 🌍

    // Special achievements
    case earlyBird          // "Started before 6pm" 🐦
    case nightCrawler       // "Still going at 4am" 🌃
    case designated         // "0 drinks logged" 🚗
}
```

### Phase 8: Profile & Social

#### 8.1 Profile View
- Avatar (tap to change)
- Username + display name
- Bio
- Stats row: Nights | Following | Friends
- "Edit Profile" button
- "YOUR NIGHTS" grid (Instagram-style)
- Night cards with date overlay

#### 8.2 Edit Profile
- Avatar picker (camera/gallery)
- Display name input
- Username input (with availability check)
- Bio textarea
- Link social accounts

#### 8.3 Other User Profile
- Same layout as own profile
- "Add Friend" / "Following" button
- "Send Message" button
- View their public nights

#### 8.4 Friends Management
- Search bar
- "Invite Friends" button (share link)
- "Create Group" button
- Friend suggestions (mutual friends)
- Pending requests section
- Friends list with online status

### Phase 9: Settings

#### 9.1 Settings View
```
ACCOUNT
- Email
- Change Password
- Linked Accounts

PRIVACY
- Privacy Settings
- Blocked Users
- Location Sharing

PREFERENCES
- Appearance (Dark/Light/System)
- Notifications
- Units (Miles/Kilometers)

SUPPORT
- Help & FAQ
- Contact Us
- Report a Bug
- Rate NIGHTOUT ⭐

ABOUT
- App Version
- Licenses

DANGER ZONE
- Delete Account (red)
- Sign Out
```

---

## SUPABASE SCHEMA (Current - 21 Tables)

### Core Tables
| Table | Rows | Purpose |
|-------|------|---------|
| `profiles` | 19 | User profiles linked to auth.users |
| `nights` | 41 | Night tracking sessions |
| `drinks` | 34 | Drink logs per night |
| `venues` | 22 | Venue check-ins per night |
| `media` | 0 | Photos/videos per night |
| `location_points` | 0 | GPS breadcrumbs for route |
| `live_updates` | 5 | Real-time timeline events |
| `songs` | 16 | Music logs per night |
| `mood_entries` | 8 | Mood check-ins per night |

### Social Tables
| Table | Rows | Purpose |
|-------|------|---------|
| `friendships` | 10 | Friend relationships |
| `friend_locations` | 0 | Real-time friend positions |
| `location_sharing_settings` | 2 | Privacy preferences |
| `location_sharing_friends` | 0 | Per-friend sharing rules |
| `night_friends` | 0 | Friends tagged in nights |

### Engagement Tables
| Table | Rows | Purpose |
|-------|------|---------|
| `night_likes` | 28 | Likes on nights |
| `comments` | 9 | Comments on nights |
| `reactions` | 11 | Emoji reactions |
| `achievements` | 5 | Unlocked achievements |

### Moderation Tables
| Table | Rows | Purpose |
|-------|------|---------|
| `blocked_users` | 0 | User blocks |
| `content_reports` | 0 | Content reports |

### Schema Enhancements Needed
```sql
-- Add notification_tokens table for push notifications
CREATE TABLE notification_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform TEXT CHECK (platform IN ('ios', 'android')),
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, token)
);

-- Add groups table for friend groups
CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES profiles(id),
    name TEXT NOT NULL,
    emoji TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(group_id, user_id)
);
```

---

## GENIUS FEATURE IDEAS (Beyond Base App)

### 1. "Cheers" Real-Time Reactions
When you see a friend is live, send them an instant "Cheers! 🍻" reaction that pops up on their screen with a toast notification and haptic bump.

### 2. Night Streaks
Track consecutive weekends going out - "You're on a 5-weekend streak!"

### 3. Venue Leaderboards
See which friends have visited a venue the most - "Most visits to [Bar Name]: @john (12)"

### 4. Drink Passport
Collect different drink types like a passport - unlock badges for variety.

### 5. Squad Stats
Create friend groups and see combined stats - "The Weekend Warriors have logged 150 nights together!"

### 6. Time Capsule
On the 1-year anniversary of a night, get a notification with memories.

### 7. Split the Bill Calculator
After logging drinks, calculate who owes what with a built-in calculator.

### 8. Morning After Mode
A gentler UI theme for the next day with hydration reminders and night recap.

### 9. Playlist Generator
Export all songs logged during a night to Apple Music/Spotify playlist.

### 10. AR Bar Finder
Point camera at street to see nearby bars with friend activity overlays.

---

## IMPLEMENTATION ROADMAP

### Wave 1: Core Foundation (Week 1-2)
1. Design system polish (emojis, microinteractions)
2. Auth flow complete (sign up, sign in, password reset)
3. Onboarding permissions flow
4. Profile setup flow
5. Main tab navigation structure

### Wave 2: Night Tracking (Week 3-4)
1. Start night configuration
2. Active tracking view with timer
3. Add drink sheet with skeuomorphic emojis
4. Dual camera capture
5. Add venue with location search
6. Night complete celebration
7. Share your night flow

### Wave 3: Social & Feed (Week 5-6)
1. Feed view with night cards
2. Night detail view
3. Like/reaction system
4. Comments
5. Friend management
6. Other user profiles

### Wave 4: Live Map (Week 7)
1. Live map view
2. Friend location pins
3. Location sharing controls
4. Real-time updates (Supabase realtime)
5. "Send Cheers" feature

### Wave 5: Stats & Polish (Week 8)
1. Statistics dashboard
2. Achievement system
3. Settings completion
4. Performance optimization
5. Bug fixes & testing

---

## EMOTIONAL DESIGN PRINCIPLES

Based on research from [Stan Vision](https://www.stan.vision/journal/micro-interactions-2025-in-web-design), [Influential Software](https://www.influentialsoftware.com/designing-for-delight-microinteractions-and-animation-in-2025/), and [HCI.org](https://www.hci.org.uk/article/the-impact-of-microinteractions-on-user-experience-designing-for-delight/):

### 1. Microinteractions (<500ms)
- Every button tap should have immediate visual + haptic feedback
- Loading states must be animated (not static spinners)
- Success states should celebrate (confetti, sparkles)

### 2. Personality Through Motion
- Use spring animations for playful feel
- Bounce effects on important actions
- Breathing/pulse effects for live elements

### 3. Emotional Rewards
- Celebration screens for milestones
- Sound effects for achievements (opt-in)
- Shareable achievement cards

### 4. Delightful Surprises
- Easter eggs for power users
- Random encouraging messages
- Seasonal themes (NYE, Halloween, etc.)

### 5. Text + Emoji Integration
- Use emojis liberally but purposefully
- Emoji selection should feel tactile (larger hit targets)
- Consider animated emoji for special moments

---

## PROJECT CONFIGURATION

### Xcode Project Settings
- **iOS Deployment Target**: 26.1
- **Swift Language Version**: 6.2 (all targets)
- **Minimum Xcode Version**: Xcode 16.4+

The Swift Language Version is set in `project.pbxproj` for all 6 build configurations:
- NIGHTOUT (Debug/Release)
- NIGHTOUTTests (Debug/Release)
- NIGHTOUTUITests (Debug/Release)

---

## CRITICAL: NavigationStack Rules

### NEVER Nest NavigationStacks

```swift
// WRONG - Double nesting causes freezes, swipe-back failures
TabView {
    NavigationStack {      // Parent NavigationStack
        HomeView()         // HomeView ALSO has NavigationStack = BROKEN
    }
}

// CORRECT - Each tab view manages its own NavigationStack
TabView {
    HomeView()             // HomeView has NavigationStack inside
        .tag(0)
}
```

### MainTabView Pattern (Current Architecture)
- Home, Live, Stats, Profile views have their OWN NavigationStack
- Tracking tab needs NavigationStack wrapper (StartNightView/ActiveTrackingView don't have one)
- Sheets presented with `.sheet()` can have their own NavigationStack (sheets have separate context)

### Deep Links & Navigation Debugging
If navigation freezes or swipe-back doesn't work:
1. Check for nested NavigationStack
2. Verify `@Environment(\.dismiss)` is not used with NavigationLink
3. Test on physical device (simulator may not show all issues)

---

## CRITICAL: Swift 6 Concurrency Patterns

### Services: Use @unchecked Sendable (NOT @MainActor)

```swift
// WRONG - @MainActor on service causes deadlocks with network calls
@MainActor
class MediaService {
    func uploadPhoto() async { ... }  // DEADLOCK - network on main thread
}

// CORRECT - @unchecked Sendable allows network calls off main thread
final class MediaService: @unchecked Sendable {
    static let shared = MediaService()
    func uploadPhoto() async { ... }  // Works correctly
}
```

### All Services in this app use `@unchecked Sendable`:
- NightService, MediaService, UserService, FriendshipService
- ModerationService, ReactionService, AchievementService
- SyncService, AuthService, MusicService, DemoSeeder

### UI Updates from Services
```swift
// CORRECT - UI updates go through MainActor
Task {
    let result = try await SomeService.shared.fetchData()
    await MainActor.run {
        self.data = result  // UI update on main thread
    }
}
```

### Deprecated Patterns (DO NOT USE)
- `@ObservableObject` / `@Published` -> Use `@Observable` macro
- `DispatchQueue.main.async` -> Use `await MainActor.run { }`
- `Combine` for state -> Use async/await

---

## CRITICAL: PhotosPicker Configuration

```swift
// WRONG - Missing photoLibrary parameter
PhotosPicker(selection: $item, matching: .images) { ... }

// CORRECT - Always specify photoLibrary
PhotosPicker(selection: $item, matching: .images, photoLibrary: .shared()) { ... }
```

### Photo Loading Pattern
```swift
.onChange(of: selectedPhoto) { _, newItem in
    Task {
        // Load as Data (not Image.self - that's buggy)
        let data = try? await newItem?.loadTransferable(type: Data.self)
        if let data, let image = UIImage(data: data) {
            await MainActor.run {
                avatarImage = image
            }
        }
    }
}
```

---

## iOS 18+ Hit-Testing Requirements

### Critical Pattern: Button contentShape Placement

In iOS 18+, `.contentShape()` must be applied **AFTER** `.buttonStyle()` on the Button itself, not on the label content inside the button.

```swift
// WRONG - contentShape on label (works in iOS 17, FAILS in iOS 18+)
Button(action: { ... }) {
    HStack {
        // content
    }
    .contentShape(Rectangle())  // This doesn't propagate hit testing!
}
.buttonStyle(.plain)

// CORRECT - contentShape on Button AFTER buttonStyle
Button(action: { ... }) {
    HStack {
        // content
    }
}
.buttonStyle(.plain)
.contentShape(Rectangle())  // Applied to Button itself
```

### Critical Pattern: onTapGesture with contentShape

When using `.onTapGesture`, always add `.contentShape()` **BEFORE** the gesture:

```swift
// WRONG - tap gesture without contentShape
SomeView()
    .onTapGesture { action() }

// CORRECT - contentShape BEFORE onTapGesture
SomeView()
    .contentShape(Rectangle())  // Must be here!
    .onTapGesture { action() }
```

### Apple HIG Touch Targets

All interactive elements must have minimum 44x44pt touch targets:

```swift
Button(action: { ... }) {
    Content()
        .frame(minWidth: 44, minHeight: 44)
}
.buttonStyle(.plain)
.contentShape(Rectangle())
```

---

## Architecture Overview

### State Management
- Uses `@Observable` macro (Swift 5.9+) - DO NOT use deprecated `@ObservableObject`
- State is managed through singleton services with async/await patterns

### Navigation
- Uses `NavigationStack` throughout - DO NOT use deprecated `NavigationView`
- Sheet presentations with `.presentationDetents()` for modern half-sheet behavior

### Concurrency
- Modern async/await patterns - DO NOT use `DispatchQueue.main.async`
- Use `Task { @MainActor in }` for UI updates from background tasks

### Backend
- Supabase Swift SDK 2.5.1
- Real-time subscriptions for live features
- SwiftData for local caching

## File Structure

```
NIGHTOUT/
├── Design/
│   ├── DesignSystem.swift      # Colors, typography, spacing
│   ├── GlassComponents.swift   # Reusable glass-style components
│   ├── EnhancedGlass.swift     # Advanced glass effects
│   ├── DrinkEmojis.swift       # Skeuomorphic drink emoji components
│   └── Microinteractions.swift # Animation and haptic helpers
├── Features/
│   ├── Auth/                   # Authentication views
│   ├── Onboarding/             # Permission flows
│   ├── Home/                   # Feed and social features
│   ├── Tracking/               # Night tracking features
│   ├── Map/                    # Live map features
│   ├── Profile/                # User profile features
│   ├── Stats/                  # Statistics and achievements
│   ├── Settings/               # App settings
│   ├── Friends/                # Friend management
│   └── Summary/                # Night summary/posting
├── Models/                     # SwiftData models
├── Services/                   # Backend services
└── Utils/                      # Helpers and extensions
```

---

## Timer Callbacks and MainActor (Swift 6)

Timer callbacks execute on a background thread and CANNOT directly mutate `@State` properties.

```swift
// WRONG - Timer callback directly modifies @State
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    self.counter += 1  // ERROR: Cannot mutate @State from non-MainActor
}

// CORRECT - Wrap mutations in Task { @MainActor in }
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    Task { @MainActor in
        self.counter += 1
    }
}
```

---

## PhotosPicker Label Closures (Swift 6)

PhotosPicker's label closure may execute in a non-isolated context. Accessing `@State` properties directly causes warnings.

```swift
// WARNING - @State property in PhotosPicker label
PhotosPicker(selection: $item, photoLibrary: .shared()) {
    LabelView(image: avatarImage)  // Warning: MainActor-isolated property
}

// CORRECT - Capture value before closure
let currentImage = avatarImage
PhotosPicker(selection: $item, photoLibrary: .shared()) {
    LabelView(image: currentImage)
}
```

---

## Supabase Configuration

### RLS (Row Level Security)
All 21 tables have RLS enabled. If queries return empty when data exists:
1. Check RLS policies match the authenticated user
2. Use `.select()` before `.eq()` filters
3. Check `auth.uid()` in policies matches `user_id` column

### Silent Failures
Supabase returns HTTP 200 with empty array for RLS failures (not 403). Debug with:
```swift
let response: [MyType] = try await supabase
    .from("table")
    .select()
    .eq("user_id", value: userId)
    .execute()
    .value
print("Count: \(response.count)")  // If 0 but data exists = RLS issue
```

---

## Pre-Commit Checklist

### Navigation & Architecture
- [ ] NO nested NavigationStack (check MainTabView + child views)
- [ ] Sheets have their own NavigationStack if needed
- [ ] `@Environment(\.dismiss)` not used with NavigationLink

### iOS 18+ Hit-Testing
- [ ] All buttons have `.contentShape()` AFTER `.buttonStyle()`
- [ ] All `.onTapGesture` preceded by `.contentShape(Rectangle())`
- [ ] All interactive elements have minimum 44x44pt touch targets

### Swift 6 Concurrency
- [ ] Services use `@unchecked Sendable` (not `@MainActor`)
- [ ] No `@ObservableObject` / `@Published` (use `@Observable`)
- [ ] No `DispatchQueue.main.async` (use `MainActor.run`)

### PhotosPicker
- [ ] All PhotosPicker have `photoLibrary: .shared()`
- [ ] Load as `Data.self` not `Image.self`

### Build & Test
- [ ] Build succeeds with zero warnings
- [ ] Test on physical device (simulator may hide issues)
- [ ] Test ALL interactive elements respond to taps

---

## UI Reference Screenshots

Claude-readable reference screenshots (max 1200px, JPEG Q72, metadata stripped) are located in `SCREENSHOTS.md/`:

### OLDNIGHOUTUI_CLAUDE/ (10 images)
Previous NIGHTOUT app UI for reference - design patterns and navigation flows.
- `IMG_7939` - Sign Up screen
- `IMG_7940` - Feed screen
- `IMG_7941` - Live Map screen
- `IMG_7942` - Start Your Night screen
- `IMG_7943` - Active Tracking screen
- `IMG_7944` - Night Complete screen
- `IMG_7945` - Share Your Night screen
- `IMG_7946` - Stats screen
- `IMG_7947` - Profile screen
- `IMG_7948` - Settings screen

### BEERBUDDY_CLAUDE/ (5 images)
BeerBuddy app reference - similar social tracking concept.
- `bb_35b22a6d` - My Drinking Map (stats overlay, user pins)
- `bb_9303e499` - Dual Camera capture (BeReal-style)
- `bb_1173e7a1` - Mindful Statistics (dry days, graphs)
- `bb_945e6b8b` - Profile (skeuomorphic drink emojis, photo grid)
- `bb_633c97a8` - Friends management

### STRAVA_CLAUDE/ (6 images)
Strava iOS reference - activity tracking UI patterns for inspiration.
- `strava0` - Pre-activity (GPS status, START button)
- `strava1` - Recording stats view
- `strava2` - Paused with RESUME/FINISH
- `strava3` - Save Activity form
- `strava4` - Visibility settings
- `strava5` - Activity feed card
