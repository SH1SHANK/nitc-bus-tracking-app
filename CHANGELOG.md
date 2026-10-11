# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Hardened CI, dependency automation, environment templates, and release foundations
- Overhauled campus map cartography with simplified building representations
- Redesigned authentication flows with improved UX and verification processes
- Enhanced home screen with better transit stop management and empty state handling
- Updated various UI components to align with Attendrix design system
- Improved onboarding flow with 11 interactive steps
- Added comprehensive unit and smoke tests for key features
- Refactored map state provider and related components
- Updated Flutter dependencies and Flutter SDK constraints
- Improved error handling and loading states across the application
- Added proper validation and user feedback in authentication flows

## [v0.1.0] - 2026-10-11

### Added
- Initial version of Tracklet 0.1.0 release
- Complete authentication system with email/password, Google sign-in, and verification flows
- Redesigned home screen with improved transit stop management
- Enhanced onboarding experience with 11 interactive steps
- Added comprehensive test suite covering authentication, home, and map features
- Updated design system tokens and typography to align with Attendrix standards

### Changed
- Updated Flutter version constraints and dependencies
- Refactored data layer with improved repository patterns
- Enhanced location services with better accuracy and error handling
- Improved notification service with more reliable delivery
- Updated storage service to handle file operations more efficiently
- Modified transit repository to support better data management
- Enhanced profile management with better user data handling
- Updated map state provider with improved state management
- Refactored onboarding provider and related components
- Updated various UI components for better accessibility and responsiveness
- Improved error handling and user feedback throughout the application
- Updated version from 1.0.0+1 to 0.1.0+1

### Fixed
- Resolved authentication flow issues in login and sign-up processes
- Fixed map display issues on different device viewports
- Corrected permission handling in onboarding flow
- Fixed state management issues in home provider
- Resolved various UI/UX inconsistencies

### Deprecated
- None

### Removed
- None

### Changed with Upgrade Notes
- Version updated from 1.0.0+1 to 0.1.0+1 (major version change for semantic versioning alignment)
- Authentication flows now use Supabase integration instead of mock implementations
- Transit data now sourced from Supabase instead of local mock data
- Map display simplified to focus on core campus buildings only
- Onboarding flow now requires completion before accessing main features