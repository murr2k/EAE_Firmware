# Changelog

**Maintained by:** Murray Kopit  
**Last Updated:** July 31, 2025

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-31

### Added
- Initial release of EAE Firmware Challenge solutions
- Question 7: Cooling loop control logic implementation
  - Python implementation with interactive demo mode
  - Standalone C++ implementation
  - Temperature-based pump and fan control
  - PID controller for fan speed regulation
  - Safety monitoring for coolant level and over-temperature conditions
  - State machine for system management (OFF, INITIALIZING, RUNNING, ERROR, EMERGENCY_STOP)
- Question 7.1: Advanced firmware features
  - CANBUS simulator with asynchronous message handling
  - Generic PID controller with anti-windup protection
  - Template-based state machine with guards and actions
  - Command line argument parsing (--setpoint, --debug, --test, --help)
  - CMake build system with automated dependency management
  - Cross-platform support (Linux/MSYS2)
  - Comprehensive unit tests using Google Test
  - Static linking for easy deployment
- Project infrastructure
  - Complete CMake configuration
  - Build script for easy compilation
  - Comprehensive documentation
  - Git repository initialization
  - GitHub remote configuration

### Technical Details
- C++17 standard compliance
- Thread-safe operation using atomic variables
- Real-time control loop at 10Hz
- Modular architecture for maintainability
- Full test coverage for critical components

### Dependencies
- CMake 3.14+
- Google Test (automatically downloaded)
- POSIX threads
- C++17 compiler

### Known Issues
- CANBUS simulation generates random temperature values for demonstration
- No actual hardware interface implementation (simulation only)

## [Unreleased]

### Planned Features
- Real CANBUS hardware interface
- Configuration file support
- Data logging capabilities
- Web-based monitoring interface
- Extended diagnostic information
- Multiple cooling zone support

---

## Version History

- **v1.0.0** (2025-01-31) - Initial release with full challenge implementation
  - Complete solutions for Questions 7 and 7.1
  - All 8 advanced features implemented
  - Full documentation and testing

## Commit Guidelines

This project follows conventional commit messages:
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `test:` Test additions or modifications
- `refactor:` Code refactoring
- `style:` Code style changes
- `chore:` Build process or auxiliary tool changes

## Release Process

1. Update version in CMakeLists.txt
2. Update CHANGELOG.md with release notes
3. Create git tag: `git tag -a v1.0.0 -m "Release version 1.0.0"`
4. Push tags: `git push origin --tags`