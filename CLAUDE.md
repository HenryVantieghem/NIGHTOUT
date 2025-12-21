# NIGHTOUT - "Strava for Going Out"

iOS 17+ | SwiftUI + SwiftData | Supabase backend | Holographic Nightclub design

## Quick Build
```bash
xcodebuild -scheme NIGHTOUT -configuration Debug build
xcodebuild test -scheme NIGHTOUT -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Architecture

### Core Architecture Patterns

**Hybrid Persistence Model:**
- **SwiftData** for local-first storage (all @Model classes)
- **Supabase** for cloud sync and collaboration features
- **SyncService** coordinates bidirectional sync between SwiftData and Supabase

**State Management:**
- `@Observable` macro for view models (NOT @ObservableObject)
- `SessionManager.shared` as single source of truth for auth state
- Environment injection for shared services

**Service Layer:**
All backend operations go through dedicated service classes in `Services/`:
- `NightService`, `UserService`, `DrinkService`, etc.
- Each service accesses `SupabaseManager.shared.client` for API calls
- Services are `@unchecked Sendable` singletons

### Key Architectural Flows

**App Launch & Auth:**
1. `NIGHTOUTApp.body` → `.task { await sessionManager.restoreSession() }`
2. `RootView` reads `sessionManager.canAccessApp` and routes to:
   - `SignInView` if not authenticated/guest
   - `OnboardingView` → `ProfileSetupView` → `MainTabView` if authenticated

**Night Tracking Flow:**
1. User starts night via `StartNightView`
2. `ActiveTrackingView` coordinates:
   - `NightLocationTracker` for background location tracking
   - Real-time venue/drink/photo/mood logging
   - Live updates visible to friends via `LiveView`
3. `EndNightView` finalizes and syncs to Supabase
4. Night appears in feed via `HomeView` → `NightCardView`

**Supabase Integration:**
- Configuration in `Supabase.swift` via `Secrets.plist` (NOT in repo)
- `SupabaseManager.shared.client` provides configured client
- Codable models in `Models/Codable/` map Supabase tables to Swift types
- `SupabaseNight`, `SupabaseProfile`, etc. convert to/from SwiftData models

### Data Model Relationships

**SwiftData @Model Cascade:**
```
User
  └─> Night (cascade delete)
       ├─> Drink (cascade)
       ├─> Venue (cascade)
       ├─> Media (cascade)
       ├─> MoodEntry (cascade)
       ├─> LocationPoint (cascade)
       ├─> LiveUpdate (cascade)
       ├─> Comment (cascade)
       └─> Song (cascade)
```

**Critical Patterns:**
- All models use `@Attribute(.unique) var id: UUID`
- Relationships use `@Relationship(deleteRule: .cascade)`
- Supabase sync happens via `SupabaseNight` → `Night` conversion in `NightService`

## Design System

**UltraDesignSystem.swift** - "Holographic Nightclub" aesthetic:
- Dark backgrounds (`UltraColors.void`, `.abyss`, `.midnight`)
- Neon holographic accents (`plasmaPin`, `cyberViolet`, `laserBlue`, `neonMint`)
- All text uses SF Rounded font
- 8pt grid spacing system (`UltraSpacing.xs` through `.xxxl`)
- Responsive sizing via `DeviceSize.current.scale`

**Key Components:**
- `HolographicCard` - Glass morphism with animated rainbow border
- `UltraButton` - 3D buttons with shimmer effects
- `CinematicNightCard` - Feed card with live indicators
- `AuroraBackground` - Animated gradient background

## Critical Implementation Rules

### Swift 6 Concurrency
- Use `@Observable` for all view models (NOT `@ObservableObject`/`@Published`)
- Mark async functions with `@MainActor` when updating UI state
- All Codable structs used in RPC must be `Sendable`
- Use `.task { }` modifier for async operations (NOT `.onAppear { Task { } }`)

### Supabase Patterns
```swift
// ✅ CORRECT - Use Supabase Swift SDK 2.x syntax
let nights: [SupabaseNight] = try await client
    .from("nights")
    .select()
    .eq("user_id", value: userId)
    .execute()
    .value

// ❌ WRONG - Old v1 syntax
client.database.from("nights") // 'database' property doesn't exist
```

### Navigation
- Use `NavigationStack` with `NavigationPath` (NOT `NavigationView`)
- Use `.navigationDestination(for:)` (NOT `NavigationLink(destination:)`)
- Define navigation routes as enums when needed

### Location Tracking
- `NightLocationTracker` handles background location updates
- Always check `CLLocationManager.authorizationStatus` before requesting permissions
- Location points stored in `LocationPoint` model, encoded as polyline in `Night.routePolyline`

## Common Patterns

### Creating a Night
```swift
let night = Night(
    userId: sessionManager.userId!,
    isActive: true,
    startTime: Date()
)
modelContext.insert(night)
try? await NightService.shared.createNight(night: night.toSupabaseNight())
```

### Fetching from Supabase
```swift
// All service methods return Codable types, not @Model types
let supabaseNights = try await NightService.shared.getFeed(userId: userId)
// Convert to SwiftData if needed for local persistence
```

### Handling Auth State
```swift
// Check auth before Supabase operations
guard sessionManager.isAuthenticated else {
    throw ServiceError.unauthorized
}

// Guest mode check for restricted features
if sessionManager.requiresAuthentication(for: .syncToCloud) {
    // Show sign-in prompt
}
```

## Configuration Files

**Secrets.plist** (NOT in repo, required for Supabase):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
    <key>SupabaseURL</key>
    <string>https://your-project.supabase.co</string>
    <key>SupabaseKey</key>
    <string>your-anon-key</string>
</dict>
</plist>
```

**Required Info.plist Keys:**
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSMicrophoneUsageDescription`

## Directory Structure

```
NIGHTOUT/
├── Features/           # Feature-based UI organization
│   ├── Auth/          # SignInView, SignUpView
│   ├── Home/          # HomeView, NightCardView, NightDetailView
│   ├── Tracking/      # StartNightView, ActiveTrackingView, EndNightView
│   ├── Live/          # LiveView (friends' live updates)
│   ├── Friends/       # FriendsView, AddFriendView
│   ├── Profile/       # ProfileView, EditProfileView
│   ├── Stats/         # StatsView (analytics)
│   └── Settings/      # SettingsView
├── Services/          # Backend integration layer
│   ├── Supabase.swift           # Client configuration
│   ├── SessionManager.swift     # Auth state manager
│   ├── NightService.swift       # Night CRUD operations
│   ├── SyncService.swift        # SwiftData ↔ Supabase sync
│   ├── LocationService.swift    # Location tracking
│   └── [Feature]Service.swift   # Other domain services
├── Models/            # SwiftData @Model definitions
│   ├── Night.swift, User.swift, Drink.swift, etc.
│   └── Codable/      # Supabase-compatible Codable types
│       ├── SupabaseNight.swift
│       └── Supabase[Model].swift
└── Design/           # Design system
    ├── UltraDesignSystem.swift  # Colors, typography, components
    └── SkeuomorphicComponents.swift
```

## Testing Strategy

Unit tests in `NIGHTOUTTests/` should test:
- Service layer logic (mock Supabase responses)
- Model conversion (SwiftData ↔ Codable)
- Business logic in view models

UI tests in `NIGHTOUTUITests/` should test:
- Critical user flows (start night → track → end → view feed)
- Auth flows (sign in/up/out)

## Known Constraints

- Minimum iOS 17.0 deployment (NOT 26.1 despite Xcode version)
- Supabase SDK 2.5.1+ required
- Demo mode seeds mock data via `DemoSeeder.shared.seedIfNeeded()`
- Guest mode allows local-only usage without auth
