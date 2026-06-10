# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**isola** is an iOS journaling app centered around an island metaphor. Users tap a message-in-a-bottle to answer daily questions and record their mood, then review entries on a diary calendar ("backpack"). A HealthKit dashboard (in progress) surfaces biometric scores derived from Apple Watch data.

- **Platform**: iOS 17+
- **Language**: Swift 6 (strict concurrency)
- **UI**: SwiftUI
- **Local persistence**: SwiftData
- **Remote data**: Firebase Firestore (question bank sync)
- **Dependencies**: `firebase-ios-sdk` 12.14 (Firestore only) via SPM

## Building

This is an Xcode project — open `isola_test.xcodeproj`. There is no CLI build script.

If XcodeBuildMCP is available, use:
- Build: `mcp__xcodebuildmcp__build_sim_name_proj`
- Test: `mcp__xcodebuildmcp__test_sim_name_proj`
- Clean: `mcp__xcodebuildmcp__clean`

## Source Layout

```
isola_test/
├── Content/
│   ├── page/           # All SwiftUI views (one file per screen)
│   └── System/         # App-wide managers and services
└── Model/              # SwiftData models, plain structs, enums
```

## Architecture

### App Entry Point
`Content/page/ContentView.swift` — contains the real `@main struct YourApp` that initialises Firebase and hosts the `ModelContainer`. `Content/isola_testApp.swift` is an older duplicate entry point that is **not** the active `@main`.

### Tab Structure (`ContentView`)
| Tab | View | Purpose |
|-----|------|---------|
| 首頁 | `HomeView` | Animated island scene; tap bottle to journal |
| 背包 | `Backpack` | Calendar diary list |
| 健康 | `HealthHomeView` | HealthKit biometric dashboard |
| 月報 | `MoodReportView` (`First_aid_Kit.swift`) | Mood report |

### Journaling Data Flow
1. **Firebase → SwiftData** (`DailyQuestionManager`): On app launch, checks `app_config/questions_info.questionVersion` against a local version stored in `UserDefaults`. If outdated, downloads all docs from `Question_data` collection and upserts into SwiftData `JournalQuestion` records.
2. **Daily selection**: `loadOrRefreshDailyQuestions` picks one `.daily` and one `.introspection` question per day using a weighted-random algorithm (`pickSmartRandom`) that favours questions not shown recently. Selections persist via `UserDefaults`.
3. **Journal entry**: `QuestionView` (`.daily`) and `IntrospectionView` (`.introspection`) are parallel two-step sheets — step 0: mood slider → step 1: text entry → saves `DiaryEntry` into SwiftData. `FreeNoteView` is a free-form entry sheet with photo attachment support (no question prompt). All three share `ActiveSheet` binding from `HomeView`.
4. **AI weekly summary**: `AIDiaryView` is a paginated page-flip review of the week's entries, using `DiaryPageItem` structs (hardcoded sample data currently).
5. **AI chat diary** (`DuQChatView`): A chat interface with "度Q" (an island character). `DuQChatViewModel` drives the conversation via `GeminiService`, then generates a diary entry + infers mood once the chat ends. Saved as a `DiaryEntry` with `type = "duqChat"`. Launched from `HomeView` via a separate `@State var showDuQChat: Bool` (not part of `ActiveSheet`).

### Gemini AI Subsystem

| File | Role |
|------|------|
| `System/GeminiService.swift` | `actor`; calls Gemini REST API; reads key from `Secrets.plist` (key: `GEMINI_API_KEY`) |
| `page/DuQChatView.swift` | Chat UI + `DuQChatViewModel` (@Observable @MainActor); manages `ChatPhase` state machine |

`GeminiService` is stateless — create one instance per use site. `Secrets.plist` must exist in the app bundle (not committed); without it the service throws `GeminiError.apiKeyNotConfigured`.

`HealthDashboardViewModel` also uses `GeminiService` to generate a short Chinese health tip after each data fetch (`generateAISuggestion()`). The tip is cached in `UserDefaults` using keys `healthAISlot` (a `"yyyy-MM-dd-{morning|afternoon|evening|night}"` string) and `healthAIText`. The cache is reused for the same time-slot; a new Gemini call is made only when the slot changes.

### HealthKit Subsystem

The Health feature is a self-contained stack:

| Layer | File | Role |
|-------|------|------|
| Service | `System/HealthKitService.swift` | Raw HealthKit queries (samples, daily stats, sleep) |
| Scoring | `System/HealthScoringEngine.swift` | Pure functions; no state; takes raw values → 0–100 sub-scores |
| ViewModel | `System/HealthDashboardViewModel.swift` | `@Observable @MainActor`; owns 7-day display data + 28-day baselines; exposes `categoryScores` and `overallScore` |
| Models | `Model/HealthModels.swift` | `HealthSample`, `SleepSession`, `MetricType` (enum with display metadata), `FormulaInfo` |
| Models | `Model/ScoringModels.swift` | `GradeLevel`, `HealthCategoryType`, `CategoryScore`, `OverallScore` |
| Views | `page/HealthHomeView.swift` | Top-level health view: overall score card + category cards |
| Views | `page/DashboardView.swift` | Alternative layout: stress banner + metric grid |
| Views | `page/CategoryDetailView.swift`, `MetricDetailView.swift` | Drill-down views |
| Views | `page/MetricCardView.swift`, `MiniChartView.swift`, etc. | Reusable cards and chart components |

`HealthDashboardViewModel` is passed via `.environment(vm)` — create one instance at the navigation root and propagate down. Scoring uses z-scores against 28-day baselines (`Baseline.zScore`); falls back to population defaults when baseline has < 7 samples. Hard caps: SpO₂ < 93% or RHR > 110 bpm clamps total score to ≤ 54.

### Key Types (Journaling)
- `JournalQuestion` — SwiftData `@Model`; synced from Firestore; use `.category` computed property (not raw `categoryRawValue`)
- `DiaryEntry` — SwiftData `@Model`; `type` is one of `"daily"` / `"introspection"` / `"freeNote"` / `"duqChat"`; `moodIndex` is `nil` for freeNote entries; has a cascade-delete `mediaItems: [DiaryMedia]` relationship
- `DiaryMedia` — SwiftData `@Model`; stores photo/video thumbnail `Data`; inverse relationship to `DiaryEntry`
- `DailyQuestionManager` — `@Observable`; call `initializeDailyQuestions(modelContext:)` from `.task` on `HomeView`
- `AppLockManager` — `@Observable` singleton; 4-digit PIN (SHA256 in UserDefaults), Face ID/Touch ID, security-question recovery
- `AppTheme` — enum (`.light`, `.dark`, `.system`); system mode auto-switches dark at 19:00; stored as `Int` via `@AppStorage("appearanceMode")`
- `Accessory` — plain struct in `Clothes.swift`; defines unlockable island accessories with `unlockThreshold` (entry count). `accessoryData` is the global array.
- `SettingView` — presented as a sheet from `HomeView` (not a tab). Navigates via `NavigationLink` to `NotificationSettingView` and `AppLockSettingView`.

### Theming
`HomePageTheme.swift` owns `AppTheme` and `homeNightOverlayOpacity(at:)`. `SeaSceneView` (inside `HomeView.swift`) uses this to blend between day/night background images in a 60fps `Canvas` animation.

Each view individually reads `@AppStorage("appearanceMode")` and computes `isDark` locally — there is no shared theme environment. The `.system` case treats hour ≥ 19 as dark. The two canonical background colours are `Color(hex: "#151D2B")` (dark) and `Color(hex: "#FDFBF0")` (light).

### App Lock Overlay
`ContentView` wraps everything in a `ZStack` and overlays `AppLockUnlockView` when `AppLockManager.shared.isLocked == true`. The lock engages on init if a PIN is set.

### Notification System

`System/NotificationManager.swift` — `final class`, `@unchecked Sendable` singleton (`NotificationManager.shared`).

- **Journal reminders**: `scheduleJournalReminders(answeredToday:)` batches 30 calendar-day `UNCalendarNotificationTrigger` requests with IDs `journal_YYYY-MM-DD`. Call this whenever the toggle/time changes and on app launch. Call `cancelTodayJournalReminder()` after the user saves a journal entry.
- **Sleep notifications**: `sendSleepNotificationIfNeeded()` fires a one-shot notification when sleep data arrives; throttled to once per day via `UserDefaults` key `notif_sleep_last_sent_date`.
- All notification `@AppStorage` keys are static constants on `NotificationManager` (e.g. `journalEnabledKey`, `journalHourKey`) — bind to them in views to stay in sync.
- `bottleAnsweredDate` (`@AppStorage`) stores today's date string (`"yyyy-MM-dd"`) to track whether the user has already journaled today; used to skip the journal notification for the current day.

### Widget Extension

`IsolaWidget/` is a separate WidgetKit extension target. `IsolaWidgetBundle` declares `IsolaHealthWidget` as its widget. The extension has HealthKit entitlement. There are no App Groups configured yet, so the widget cannot read the main app's `UserDefaults` or `SwiftData` store — add App Groups to both targets' entitlements before sharing data.

`IsolaWidgetControl.swift` is auto-generated boilerplate (timer toggle placeholder) — not a real feature.

## Patterns

- Use `@Observable` (not `ObservableObject`) for all manager/view-model classes.
- Persist user preferences with `@AppStorage`; use the key constants already established (e.g. `"appearanceMode"`, `"isola_LocalQuestionVersion"`, `"userName"`).
- `Color(hex:)` helper is defined at the bottom of `Backpack.swift` — reuse it rather than redefine.
- All haptics go through `UIImpactFeedbackGenerator` called directly in button actions (no wrapper).
- HealthKit views consume `HealthDashboardViewModel` via `@Environment` — never create it inside a leaf view.
