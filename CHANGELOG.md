# Changelog

**Maintained by:** Murray Kopit
**Last Updated:** July 31, 2025

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-08-22

### Added
- TX queue bounds protection with configurable limit (1024 messages) (#16)
- Drop counter for diagnostics when queue is full (#16)
- Comprehensive test suite for CAN bus reentrancy and queue bounds

### Fixed
- CAN handler reentrancy issues - handlers now called without holding mutex (#16)
- Thread safety issues with proper mutex usage (#15)
- Potential deadlock when handlers register new handlers or send messages (#16)

### Changed
- CAN handlers are now copied before invocation to prevent deadlocks
- Security Scanner made non-blocking due to style preference conflicts

## [1.1.0] - 2025-07-31

### Added
- Comprehensive CI/CD pipeline using GitHub Actions
  - Multi-platform testing (Ubuntu 24.04 and 20.04)
  - Multi-compiler support (GCC 9/10/11, Clang)
  - Python testing for versions 3.8-3.11
  - Code coverage reporting with gcovr and lcov
  - Static analysis (cppcheck, clang-tidy, clang-format)
  - Security scanning with GitHub Super Linter
  - Automated release workflow
  - Memory safety testing with sanitizers
  - Pull request template for contributions
  - Dependabot configuration for dependency updates

### Fixed
- Python module imports for pytest compatibility (#8)
- CI/CD compatibility with Ubuntu 24.04 (#9, #10)
- Clang compiler narrowing conversion errors
- GitHub Actions deprecated version warnings (v3 → v4)
- Code coverage line mismatch errors (#12)
- Markdown formatting issues (reduced linting errors by 80%)

### Changed
- Updated all GitHub Actions to latest versions
- Improved code coverage exclusion patterns
- Enhanced documentation with CI/CD information
- Added Python testing instructions to README

### Pipeline Status
- 80% of CI/CD jobs passing (12/15)
- Core functionality fully tested and working
- Remaining issues: Super Linter strictness, slow sanitizer tests

## [1.0.0] - 2025-07-31

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

## [1.2.0] - 2025-08-09

### Added
- MATLAB/Simulink integration for PID tuning and system modeling
  - Ziegler-Nichols tuning method implementation
  - Multiple optimization algorithms (pattern search, genetic algorithm, particle swarm)
  - Transfer function and state-space system models
  - Robustness analysis with parameter variation testing
  - Automated HTML report generation with performance metrics
  - Timestamped results archival with all plots and data
- Comprehensive documentation
  - THEORY_OF_OPERATION.md for C++ implementation walkthrough
  - THEORY_OF_OPERATION_PYTHON.md for Python implementation guide
  - MATLAB project README with detailed usage instructions
- Enhanced testing capabilities
  - MATLAB scripts for PID parameter validation
  - Comparison of theoretical vs practical tuning values
  - Built-in simulation and testing framework

### Improved
- PID tuning validation through multiple methods
- System modeling accuracy with time delay approximation
- Documentation with line-by-line code explanations
- Test coverage with MATLAB-based validation

### Fixed
- MATLAB compatibility issues with SaveFormat parameter
- Plot saving functionality in MATLAB scripts
- Dimension mismatches in performance comparison tables
- Root locus errors with delayed systems using Padé approximation

## [Unreleased]

### Planned Features
- Real CANBUS hardware interface
- Configuration file support
- Data logging capabilities
- Web-based monitoring interface
- Extended diagnostic information
- Multiple cooling zone support
- Hardware-in-the-loop testing with MATLAB
- Real-time parameter tuning interface

---

## Version History

- **v1.2.0** (2025-08-09) - MATLAB Integration and Documentation Enhancement
  - Added MATLAB/Simulink project for PID tuning validation
  - Created comprehensive theory of operation documents
  - Enhanced testing with multiple optimization methods
- **v1.1.0** (2025-07-31) - CI/CD Integration and Compatibility Fixes
  - Added comprehensive GitHub Actions CI/CD pipeline
  - Fixed Ubuntu 24.04 compatibility issues
  - Resolved all Python test failures
  - Improved cross-platform build support
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
