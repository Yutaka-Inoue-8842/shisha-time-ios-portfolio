# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build & Run
- **Xcode Build**: Open `ShishaTime.xcworkspace` (NOT the .xcodeproj) and use standard Xcode build (⌘+R)
- **Swift Package Tests**: Use `swift test` from the Package directory for running Swift Package Manager tests

### Testing
- **Unit Tests**: Tests are located in `Package/Tests/` with separate test suites:
  - `SettingFeatureTests/` - UI feature tests (AddCategoryFeatureTests, CategoryListFeatureTests, etc.)
  - `CharcoalTimerFeatureTests/` - Timer functionality tests
  - `DocumentFeatureTests/` - Document management tests
  - `AppFeatureTests/` and `AppTabFeatureTests/` - App-level tests
- **Run Tests**: Use Xcode's test navigator or `swift test` from Package directory
- **Single Test**: In Xcode, use the diamond icon next to individual test methods

### Backend (AWS Amplify)
- **Deploy Backend**: `npx ampx pipeline-deploy --branch $AWS_BRANCH --app-id $AWS_APP_ID`
- **Install Dependencies**: `npm ci` (backend) or `npm install` (development)

## Architecture Overview

### Project Structure
This is a **modular Swift Package Manager project** with the main iOS app (`ShishaTime/`) consuming libraries from `Package/Sources/`:

```
Package/Sources/
├── AppFeature/           # Root app coordinator using TCA
├── AppTabFeature/        # Tab navigation coordinator  
├── CharcoalTimerFeature/ # Timer functionality for charcoal preparation
├── DocumentFeature/      # Note-taking and session documentation
├── SettingFeature/       # Configuration screens (categories, tables, templates)
├── Domain/               # Business logic, entities, use cases, repositories
├── Common/               # Shared UI components and utilities
└── Extension/            # Swift standard library extensions
```

### Key Architectural Patterns

**TCA (The Composable Architecture)**:
- All features use TCA's `@Reducer` pattern with `State`, `Action`, and `body` implementing the reducer logic
- Features are composed hierarchically: `AppFeature` → `AppTabFeature` → individual feature reducers
- State management follows unidirectional data flow with immutable state updates

**Domain-Driven Design**:
- Core entities: `Category`, `Document`, `Table`, `Template`, `Timer` (all using AWS Amplify's GraphQL models)
- Use cases encapsulate business logic: `CategoryUseCase`, `DocumentUseCase`, etc.
- Repositories abstract data access with dependency injection for testing

**Dependency Injection**:
- Uses TCA's `@Dependency` system for injecting repositories and use cases
- Live implementations using `DependencyKey` and `TestDependencyKey` protocols
- Preview values provided for SwiftUI previews

### Data Layer
- **AWS Amplify**: GraphQL API with auto-generated models, authentication, and real-time sync
- **Models**: Amplify-generated models with `@unchecked Sendable` for Swift 6 concurrency
- **Repositories**: Abstract data access (e.g., `CategoryRepository`, `DocumentRepository`)
- **Global Partitioning**: All entities use `globalPartition` field for data isolation

### UI Patterns
- **SwiftUI**: Modern declarative UI with iOS 17+ minimum deployment
- **Feature-based Organization**: Each feature has its own View/Feature pair (e.g., `AddCategoryView`/`AddCategoryFeature`)
- **Shared Components**: Reusable UI in `Common/Component/` (buttons, text fields, rich text editor)
- **Navigation**: Hierarchical navigation using TCA's navigation tools

### Error Handling
- Centralized error handling via `ErrorHandler` dependency
- Custom validation errors: `CategoryValidationError`, `TimerValidationError`
- User-friendly error presentation through TCA's alert system

## Development Notes

### Swift Package Manager
- Package dependencies managed in `Package/Package.swift`
- Main dependencies: TCA 1.21.1 (exact), Amplify Swift 2.48.0 (exact)
- Modular design allows independent testing and development of features

### Testing Strategy
- Unit tests focus on use cases and business logic
- TCA testing patterns for reducer testing
- Mock repositories for isolated testing
- Test coverage in critical domains like data validation and business rules

### AWS Amplify Integration
- Backend configuration in `amplify/` directory with TypeScript CDK
- GraphQL schema and auth rules in `amplify/data/resource.ts`
- Frontend configuration in `amplify_outputs.json`

### Code Conventions
- Japanese comments and documentation (this is a Japanese project)
- Swift 6 strict concurrency enabled
- TCA patterns consistently applied across all features
- Clean Architecture principles with clear separation of concerns