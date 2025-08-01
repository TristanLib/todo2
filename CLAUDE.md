# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚀 Quick Start - Current Development Status

**IMPORTANT**: This project is currently implementing user retention features using incremental development approach.

### Current Status (2025-08-01)
- **Development Method**: Incremental development - complete one functional module per interaction
- **Completed**: Increment 1 (StreakManager) + Increment 2 (StreakCardView UI)
- **Next Task**: Increment 3 - Basic Achievement System UI
- **Status**: ✅ Ready to continue development

### Key Files for Current Development
- `docs/current-development-status.md` - Complete current status
- `docs/next-increment-plan.md` - Detailed plan for Increment 3
- `TodoList/TodoList/Services/StreakManager.swift` - Core streak tracking logic
- `TodoList/TodoList/Views/Components/StreakCardView.swift` - Streak UI component

## Project Overview

TaskMate is an iOS todo-list application built with SwiftUI and Swift 6, targeting iOS devices. It features task management, focus mode with timers, local notifications, and audio capabilities for productivity enhancement. Currently implementing user retention features through gamification elements.

## Build and Development Commands

### Building the App
```bash
# Open the project in Xcode
open TodoList/TodoList.xcodeproj

# Build from command line (requires xcodebuild)
xcodebuild -project TodoList/TodoList.xcodeproj -scheme TodoList -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

### Running Tests
```bash
# Run unit tests
xcodebuild test -project TodoList/TodoList.xcodeproj -scheme TodoList -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Code Style and Linting
This project follows standard Swift/SwiftUI conventions. No specific linting tools are configured.

## Architecture Overview

### Core Data Stack
- **PersistenceController**: Manages Core Data stack initialization
- **CoreDataManager**: Singleton service for Core Data operations (CRUD for tasks)
- **CDTask/CDSubtask**: Core Data entities for persistence
- **Task/Subtask**: SwiftUI model structs that mirror Core Data entities

### Key Managers and Services (Original + New)
- **TaskStore**: Primary task management service, bridges between SwiftUI views and Core Data
- **CategoryManager**: Handles custom user-defined task categories
- **FocusTimerManager**: Manages focus/break timer sessions
- **NotificationManager**: Handles local notifications and reminders
- **SoundManager**: Manages audio playback for focus sessions
- **AppSettings**: Centralized app configuration and user preferences
- **StreakManager** 🆕: Manages consecutive usage days tracking and milestones
- **AchievementManager** 🔄: Achievement badge system (in development)

### Data Flow Pattern
1. Views interact with `@EnvironmentObject` stores (TaskStore, AppSettings, etc.)
2. TaskStore delegates persistence operations to CoreDataManager
3. CoreDataManager performs CRUD operations on Core Data entities
4. Changes propagate back through `@Published` properties to update UI
5. **New**: User actions trigger StreakManager.markTodayAsActive() for retention tracking

### Navigation Structure
- **TabView**: 5-tab navigation (Home, Tasks, Add Task, Focus, Settings)
- **ContentView**: Root container managing tab state and modal presentations
- **Specialized Views**: HomeView (with StreakCardView), TaskListView, FocusView, SettingsView

### User Retention Features (New)
- **Streak Tracking**: Consecutive usage days with 24-hour grace period
- **Milestone System**: 3, 7, 30, 100-day milestones with rewards
- **Visual Progress**: StreakCardView in HomeView showing current streak and progress
- **Achievement System**: Badge collection (in development)
- **Gamification**: Points, levels, daily challenges (planned)

### Localization
- Supports English and Chinese (zh-Hans)
- Uses `NSLocalizedString` throughout the codebase
- String files: `en.lproj/Localizable.strings` and `zh-Hans.lproj/Localizable.strings`

### Key Features
- **Task Management**: Create, edit, delete, complete tasks with categories, priorities, subtasks
- **Focus Mode**: Pomodoro-style timer with break intervals and audio feedback
- **Local Notifications**: Task reminders and focus session alerts
- **Data Backup/Restore**: Export/import functionality via DataManager
- **Custom Categories**: User-defined task categories beyond default ones
- **Theme Support**: Light/dark/system themes with custom accent colors
- **Streak System** 🆕: Consecutive usage tracking with visual progress and milestones
- **Achievement System** 🔄: Badge collection and unlock system (in development)

### Important Notes
- Uses UserDefaults migration to Core Data (handled automatically on first launch)
- Background audio support configured for focus mode sounds
- Notification permissions requested at app launch if notifications are enabled
- Application badge reflects incomplete task count (unless focus mode is active)
- **Streak data**: Stored in UserDefaults with JSON encoding for persistence
- **Debug access**: Settings → Debug Features → Streak Debug (Debug mode only)

## Development Guidelines for Retention Features

### When working on user retention features:
1. **Follow incremental approach**: Complete one functional module per interaction
2. **Prioritize UI visibility**: Users should immediately see the value of new features
3. **Maintain consistency**: Follow existing design language and animation patterns
4. **Test immediately**: Verify functionality works as expected before moving to next increment
5. **Update documentation**: Keep current-development-status.md updated with progress

### Testing the streak system:
- Use StreakDebugView for testing various scenarios
- Complete tasks or focus sessions to trigger streak updates
- Check console logs with 🔥 prefix for streak-related operations
- Verify StreakCardView updates in HomeView after user actions