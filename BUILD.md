# LociApp - Build & Deployment Guide

## Build Requirements

- **Xcode**: 16.0+ (for iOS 18 support)
- **iOS**: 18.0+ minimum target
- **Swift**: 5.10+
- **Platform**: iPhone (primary), Apple Watch (optional)

## Local Development Setup

### 1. Clone and Open Project
```bash
git clone [repository-url]
cd LociApp
open LociApp.xcodeproj
```

### 2. Build Configuration
- Select iPhone 15 Pro simulator or physical device
- Build configuration: Debug for development, Release for distribution
- Signing: Use automatic signing with your Apple Developer account

### 3. Run Tests
```bash
# Run unit tests
cmd+U in Xcode
# Or via command line:
xcodebuild test -scheme LociApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Build Workflow

### Development Build
1. Select target device/simulator
2. Build and run (cmd+R)
3. Test functionality manually
4. Run unit tests (cmd+U)
5. Commit changes

### Release Build
1. Update version number in project settings
2. Set build configuration to Release
3. Run all tests and ensure they pass
4. Build for archive (cmd+shift+B)
5. Test on physical device
6. Create archive for App Store submission

## Version Management

Use semantic versioning: `MAJOR.MINOR.PATCH`
- **MAJOR**: Breaking changes
- **MINOR**: New features
- **PATCH**: Bug fixes

Update version in:
- `LociApp/Info.plist` (CFBundleShortVersionString)
- Build number (CFBundleVersion)

## Deployment Checklist

### Before Submission
- [ ] All unit tests pass
- [ ] App builds without warnings
- [ ] Tested on multiple devices/simulators
- [ ] No debug code or console prints
- [ ] App icon and launch screen configured
- [ ] Privacy permissions configured
- [ ] App Store metadata prepared

### App Store Submission
1. Archive the app (Product → Archive)
2. Validate the archive
3. Upload to App Store Connect
4. Submit for review
5. Monitor review status

## Common Issues

### Build Errors
- **SwiftData issues**: Ensure iOS 18+ deployment target
- **Signing errors**: Check Apple Developer account and certificates
- **Missing frameworks**: Verify all dependencies are linked

### Testing Issues
- **Simulator crashes**: Reset simulator and rebuild
- **Device testing**: Ensure device is unlocked and trusted
- **JSON import**: Test with sample JSON files

## Emergency Procedures

### Rollback
- Revert to last known good commit
- Rebuild and test
- Redeploy if necessary

### Hotfix
- Create hotfix branch from main
- Make minimal fix
- Test thoroughly
- Deploy via emergency release