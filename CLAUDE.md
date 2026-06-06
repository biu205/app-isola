# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**isola** is an iOS journaling app centered around an island metaphor. Users tap a message-in-a-bottle to answer daily questions and record their mood, then review entries on a diary calendar ("backpack").

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
│   └── System/         # App-wide logic (theme, question manager)
└── Model/              # SwiftData models + legacy Codable struct
```

## Architecture

### App Entry Point
`Content/page/ContentView.swift` — contains the real `@main struct YourApp` that initialises Firebase and hosts the `ModelContainer`. `Content/isola_testApp.swift` is an older duplicate entry point that is **not** the active `@main`.

### Tab Structure (`ContentView`)
| Tab | View | Purpose |
|-----|------|---------|
| 首頁 | `HomeView` | Animated island scene; tap bottle to journal |
| 背包 | `Backpack` | Calendar diary list |
| 急救箱 | `MoodReportView` (`First_aid_Kit.swift`) | Mood report |
| 月報 | `HRV` | Monthly report |

### Data Flow
1. **Firebase → SwiftData** (`DailyQuestionManager`): On app launch, checks `app_config/questions_info.questionVersion` against a local version stored in `UserDefaults`. If outdated, downloads all docs from `Question_data` collection and upserts into SwiftData `JournalQuestion` records.
2. **Daily selection**: `loadOrRefreshDailyQuestions` picks one `.daily` and one `.introspection` question per day using a weighted-random algorithm (`pickSmartRandom`) that favours questions not shown recently. Selections persist via `UserDefaults`.
3. **Journal entry**: `QuestionView` is a two-step sheet — step 0: mood slider → step 1: text entry → saves `DiaryEntry` into SwiftData.

### Key Types
- `JournalQuestion` — SwiftData `@Model`; synced from Firestore; holds `categoryRawValue` (use `.category` computed property for type safety)
- `DiaryEntry` — SwiftData `@Model`; user-authored entries with mood index (0–4) and text
- `DailyQuestionManager` — `@Observable` class; manages Firebase sync and daily question selection; call `initializeDailyQuestions(modelContext:)` from `.task` on `HomeView`
- `AppLockManager` — `@Observable` singleton; 4-digit PIN (SHA256 in UserDefaults), Face ID/Touch ID, security-question recovery
- `AppTheme` — enum (`.light`, `.dark`, `.system`); system mode auto-switches dark at 19:00; stored as `Int` via `@AppStorage("appearanceMode")`

### Theming
`HomePageTheme.swift` owns `AppTheme` and `homeNightOverlayOpacity(at:)`. `SeaSceneView` (inside `HomeView.swift`) uses this to blend between day/night background images in a 60fps `Canvas` animation.

### App Lock overlay
`ContentView` wraps everything in a `ZStack` and overlays `AppLockUnlockView` when `AppLockManager.shared.isLocked == true`. The lock engages on init if a PIN is set.

## Patterns

- Use `@Observable` (not `ObservableObject`) for all manager/view-model classes.
- Persist user preferences with `@AppStorage`; use the key constants already established (e.g. `"appearanceMode"`, `"isola_LocalQuestionVersion"`).
- `Color(hex:)` helper is defined at the bottom of `Backpack.swift` — reuse it rather than redefine.
- All haptics go through `UIImpactFeedbackGenerator` called directly in button actions (no wrapper).
