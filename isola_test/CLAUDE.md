# Project: [isola]

## Quick Reference
- **Platform**: iOS 17+ / macOS 14+
- **Language**: Swift 6.0+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with @Observable
- **Minimum Deployment**: iOS 17.0
- **Package Manager**: Swift Package Manager

## XcodeBuildMCP Integration
**IMPORTANT**: This project uses XcodeBuildMCP for all Xcode operations.
- Build: `mcp__xcodebuildmcp__build_sim_name_proj`
- Test: `mcp__xcodebuildmcp__test_sim_name_proj`
- Clean: `mcp__xcodebuildmcp__clean`

## Project Structure
```
MyApp/
├── App/                    # App entry point, App delegate
├── Features/               # Feature modules
│   ├── [FeatureName]/
│   │   ├── Views/          # SwiftUI views
│   │   ├── ViewModels/     # @Observable classes
│   │   └── Models/         # Data models
├── Core/                   # Shared utilities
│   ├── Extensions/
│   ├── Services/
│   └── Networking/
├── Resources/              # Assets, Localizations
└── Tests/
```
## Core Rules
- Use @Observable, async/await, @Environment
- NavigationStack with type-safe routing (see /skill/routing)
- Typed errors: enum AppError: LocalizedError
- No force unwrap (!), deprecated APIs, or massive views
- Minimum 80% coverage for business logic

## Planning New Features
1. Read PRD from `docs/PRD.md`
2. Spec in `docs/specs/[feature-name].md`
3. Use ultrathink for architecture
4. Use Plan Mode for strategy
5. Implement with tests (see /skill/swift-testing)

## DO NOT
- Write UITests during scaffolding
- Use UIKit when SwiftUI suffices
- Create views >100 lines
- Ignore Swift 6 concurrency warnings