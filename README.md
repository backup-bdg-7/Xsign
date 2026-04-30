# Xsign - iOS App Signing Tool

A powerful iOS application for signing and managing iOS apps, built with SwiftUI and SwiftData.

## Features

- **App Library Management**: Import, organize, and manage your iOS applications
- **Code Signing**: Sign apps with your certificates and provisioning profiles
- **Certificate Management**: Import and manage signing certificates
- **SwiftUI Interface**: Modern, clean user interface built with SwiftUI
- **SwiftData Integration**: Persistent storage with Apple's SwiftData framework

## Project Structure

```
Xsign/
├── App/                    # Application entry point and bridging code
│   ├── XsignApp.swift     # Main app entry
│   └── Bridge/            # Objective-C bridging components
├── Models/                 # Data models (SwiftData)
├── Views/                  # SwiftUI views
│   ├── Library/           # App library views
│   ├── Categories/        # Category management
│   ├── General/           # General settings and views
│   └── Shared/            # Shared UI components
├── Services/              # Business logic and services
├── Shared/                # Shared utilities and theme
└── Resources/             # Assets, animations, and Info.plist
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Dependencies

Managed via Swift Package Manager (see `Package.swift`):

- **ZIPFoundation**: ZIP file handling
- **Lottie**: Animations
- **BitByteData**: Binary data parsing
- **SWCompression**: Compression utilities
- **Swift Crypto**: Cryptographic operations
- **Vapor**: Server components (if needed)
- **Zip**: Additional ZIP utilities

## Getting Started

### Option 1: Using XcodeGen (Recommended)

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project file automatically.

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   # or
   mint install yonaskolb/XcodeGen
   ```

2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

3. Open `Xsign.xcodeproj` in Xcode

### Option 2: Using Swift Package Manager

You can also work with the package directly:

```bash
swift build
swift test
```

## Automated Workflow

This project includes a GitHub Actions workflow that:

1. **Analyzes your code** (SwiftLint, structure analysis)
2. **Generates the Xcode project** using XcodeGen
3. **Uploads the project as a downloadable artifact**
4. **Automatically commits and pushes** the generated project to the repo

### How to Use the Workflow

The workflow runs automatically on:
- Pushes to `main` and `feat/swift-package-setup` branches
- Pull requests to `main`
- Manual trigger (workflow_dispatch)
- Weekly schedule (Mondays at midnight)

#### Downloading the Generated Project

1. Go to the **Actions** tab in your GitHub repository
2. Click on the latest "Analyze & Generate Xcode Project" workflow run
3. Scroll down to the **Artifacts** section
4. Download `Xsign-xcodeproj-<commit-sha>`
5. Extract and open `Xsign.xcodeproj` in Xcode

#### Automatic Push to Repository

- **On main branch**: The generated project is automatically committed and pushed to `main`
- **On PRs or other branches**: A new branch `generated-xcodeproj-<branch-name>` is created with the Xcode project

### Workflow Files

- `.github/workflows/generate-xcodeproj.yml` - Main workflow
- `project.yml` - XcodeGen configuration file
- `.swiftlint.yml` - SwiftLint configuration for code analysis

## Development

### Code Style

This project uses SwiftLint for code style enforcement. The configuration is in `.swiftlint.yml`.

To run SwiftLint locally:
```bash
swiftlint lint
```

### Building and Running

1. Generate the Xcode project (see Getting Started)
2. Open in Xcode
3. Select your target device or simulator
4. Build and run (⌘R)

### Making Changes

1. Modify the source code in the `Xsign/` directory
2. If you change dependencies, update `Package.swift`
3. If you add/remove files, the workflow will regenerate the project automatically
4. For manual project regeneration: `xcodegen generate`

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

The workflow will automatically generate the Xcode project for your PR.

## License

[Add your license here]

## Acknowledgments

- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation
- [SwiftLint](https://github.com/realm/SwiftLint) for code style enforcement
- All the amazing Swift package maintainers
