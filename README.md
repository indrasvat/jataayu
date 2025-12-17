# Jools

iOS client for [Google's Jules](https://jules.google.com) coding agent.

## Requirements

- macOS Sequoia or later
- Xcode 26.0+
- iOS 26.0+ deployment target
- [Homebrew](https://brew.sh)

## Quick Start

```bash
# Clone the repository
git clone git@github.com:indrasvat/jools.git
cd jools

# Run bootstrap (installs dependencies, hooks, generates project)
./scripts/bootstrap

# Open in Xcode
make xcode
```

## Development Setup

### First Time Setup

The bootstrap script handles everything automatically:

```bash
./scripts/bootstrap
```

This will:
1. Check for required tools (Xcode, Homebrew)
2. Install dependencies (SwiftLint, XcodeGen, Lefthook)
3. Install git hooks for pre-push CI checks
4. Resolve Swift package dependencies
5. Generate the Xcode project

### Manual Setup

If you prefer manual setup:

```bash
# Install dependencies
brew install swiftlint xcodegen lefthook

# Install git hooks
lefthook install

# Generate Xcode project
xcodegen generate

# Open project
open Jools.xcodeproj
```

## Available Commands

Run `make help` to see all available commands:

```
make setup          Full project setup (deps + hooks + generate)
make build          Build for simulator (debug)
make test           Run all tests
make lint           Run SwiftLint
make ci             Run full CI pipeline
make xcode          Open project in Xcode
```

## Project Structure

```
jools/
├── Jools/                    # iOS app source
│   ├── App/                  # App entry point, dependency injection
│   ├── Core/                 # Shared infrastructure
│   │   ├── DesignSystem/     # Colors, typography, spacing
│   │   ├── Navigation/       # App coordinator, root view
│   │   └── Persistence/      # SwiftData entities
│   └── Features/             # Feature modules
│       ├── Onboarding/       # API key entry
│       ├── Dashboard/        # Sources & sessions list
│       ├── Chat/             # Session chat interface
│       └── Settings/         # App settings
├── JoolsKit/                 # Core Swift package
│   └── Sources/JoolsKit/
│       ├── API/              # Network client, endpoints
│       ├── Auth/             # Keychain manager
│       ├── Models/           # DTOs
│       └── Polling/          # Adaptive polling service
├── JoolsTests/               # App unit tests
├── scripts/                  # Development scripts
│   └── bootstrap             # First-time setup script
├── docs/                     # Documentation
├── project.yml               # XcodeGen project spec
├── lefthook.yml              # Git hooks configuration
└── Makefile                  # Build automation
```

## Git Hooks

This project uses [Lefthook](https://github.com/evilmartians/lefthook) for git hooks:

- **pre-push**: Runs full CI pipeline (`make ci`) before every push

The hooks are automatically installed when you run `./scripts/bootstrap` or `make setup`.

## CI Pipeline

The CI pipeline (`make ci`) runs:
1. SwiftLint (code quality)
2. JoolsKit build & tests
3. iOS app build
4. iOS app tests

This runs automatically on every push via the pre-push hook.

## Architecture

- **MVVM+C**: Model-View-ViewModel with Coordinator pattern
- **SwiftUI**: Declarative UI framework
- **SwiftData**: Local persistence
- **Async/Await**: Modern concurrency with actors
- **Swift 6**: Strict concurrency checking enabled

## License

Private repository. All rights reserved.
