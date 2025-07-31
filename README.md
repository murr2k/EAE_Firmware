# EAE Firmware Challenge Submission

[![CI/CD Pipeline](https://github.com/murr2k/EAE_Firmware/actions/workflows/ci.yml/badge.svg)](https://github.com/murr2k/EAE_Firmware/actions/workflows/ci.yml)
[![Tests](https://img.shields.io/github/actions/workflow/status/murr2k/EAE_Firmware/ci.yml?label=tests)](https://github.com/murr2k/EAE_Firmware/actions/workflows/ci.yml)
[![Code Coverage](https://github.com/murr2k/EAE_Firmware/actions/workflows/coverage.yml/badge.svg)](https://github.com/murr2k/EAE_Firmware/actions/workflows/coverage.yml)
[![Release](https://img.shields.io/github/v/release/murr2k/EAE_Firmware)](https://github.com/murr2k/EAE_Firmware/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/murr2k/EAE_Firmware)](https://github.com/murr2k/EAE_Firmware/commits/main)
[![Issues](https://img.shields.io/github/issues/murr2k/EAE_Firmware)](https://github.com/murr2k/EAE_Firmware/issues)
[![C++](https://img.shields.io/badge/C%2B%2B-17-blue.svg)](https://en.cppreference.com/w/cpp/17)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20MSYS2-blue)](README.md)

**Author:** Murray Kopit
**Date:** July 31, 2025

This repository contains the solutions for the EAE Engineering Challenge - Electrical and Controls section, specifically Questions 7 and 7.1.

⚠️ Note to Reviewer: This submission includes more than Section 7 & 7.1, to demonstrate modular, testable design. Please feel free to skip additional features unless of interest. The core answers are in cooling_control.cpp and src/. Everything is open-book, per instructions.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Question 7: Cooling Loop Control Logic](#question-7-cooling-loop-control-logic)
- [Question 7.1: Advanced Firmware Features](#question-71-advanced-firmware-features)
- [Building and Running](#building-and-running)
- [Testing](#testing)
- [CI/CD Pipeline](#cicd-pipeline)
- [Design Decisions](#design-decisions)
- [Contributing](#contributing)
- [ChangeLog](#changelog)

## Overview

This project implements a complete cooling system controller for an electric vehicle inverter and DC-DC converter, featuring advanced control algorithms, safety mechanisms, and a modular architecture suitable for embedded systems.

## Features

### Question 7 Requirements Implemented
1. ✅ Temperature Sensor Input processing
2. ✅ Ignition Switch Input handling
3. ✅ Pump Control logic
4. ✅ Fan Control with variable speed
5. ✅ Safety Functions (low coolant, over-temperature protection)

### Question 7.1 - Eight Advanced Features Implemented
1. ✅ **CANBUS Simulation** - Full send/receive data simulation with message handlers
2. ✅ **PID Loop** - Generic PID controller with anti-windup for fan speed control
3. ✅ **State Machine** - Template-based state machine with guards and transition actions
4. ✅ **Command Line Arguments** - Pass setpoints and configuration via command line
5. ✅ **CMake Build System** - External dependencies managed by CMake (Google Test)
6. ✅ **Linux/MSYS2 Support** - Cross-platform build with shell script launcher
7. ✅ **Google Test Unit Testing** - Comprehensive test suite for all components
8. ✅ **Static Linking** - No external dependencies shipped, all statically linked

## Project Structure

```text
EAE_Firmware/
├── src/                      # Source files
│   ├── main.cpp             # Main application entry point
│   ├── canbus_simulator.cpp # CANBUS communication simulation
│   ├── pid_controller.cpp   # PID control implementation
│   ├── state_machine.cpp    # State machine template
│   └── cooling_system.cpp   # Main cooling system logic
├── include/                 # Header files
│   ├── canbus_simulator.h   # CANBUS interface
│   ├── pid_controller.h     # PID controller class
│   ├── state_machine.h      # Generic state machine template
│   └── cooling_system.h     # Cooling system controller
├── tests/                   # Unit tests
│   ├── test_main.cpp       # Test runner
│   ├── test_pid.cpp        # PID controller tests
│   ├── test_state_machine.cpp # State machine tests
│   └── test_canbus.cpp     # CANBUS simulator tests
├── cooling_control.py      # Question 7 - Python implementation
├── cooling_control.cpp     # Question 7 - C++ standalone implementation
├── CMakeLists.txt         # CMake build configuration
├── build.sh               # Build script for Linux/MSYS2
├── test_cooling_control.py # Python unit tests
├── README.md              # This file
├── CHANGELOG.md           # Version history
├── REVIEWER_QA.md         # Q&A for reviewers
├── TEST_RESULTS.md        # Example test outputs
├── CI_CD_TEST_RESULTS.md  # CI/CD pipeline test results
└── .gitignore            # Git ignore file
```

## Question 7: Cooling Loop Control Logic

The cooling loop control logic is implemented in both Python and C++ for maximum flexibility:

### Python Implementation (`cooling_control.py`)
- Complete implementation with interactive demo
- State machine-based control
- PID controller for fan speed
- Safety monitoring and error handling
- Simulated sensor inputs for testing

### C++ Implementation (`cooling_control.cpp`)
- Standalone C++ implementation
- Thread-safe operation
- Real-time control at 10Hz
- Comprehensive safety checks

### Running the Implementations

Python version:
```bash
python3 cooling_control.py
```

C++ standalone version:
```bash
g++ -std=c++17 cooling_control.cpp -o cooling_control -pthread
./cooling_control
```

## Question 7.1: Advanced Firmware Features

### 1. CANBUS Simulation
- Asynchronous message handling
- Multiple message handlers support
- TX/RX counters for diagnostics
- Simulated temperature sensor messages

### 2. PID Controller
- Generic implementation with configurable parameters
- Anti-windup protection
- Output clamping
- Reset functionality

### 3. State Machine
- Template-based for reusability
- Guard conditions for transitions
- Entry/exit actions for states
- Transition actions support

### 4. Command Line Arguments
```bash
./eae_firmware --help              # Show help
./eae_firmware --setpoint 70.0     # Set temperature setpoint
./eae_firmware --debug             # Enable debug output
./eae_firmware --test              # Run in test mode
```

### 5. CMake Build System
- Automatic Google Test download and integration
- Separate test executable
- Release/Debug build configurations
- Export compile commands for IDEs

### 6. Linux/MSYS2 Support
- POSIX thread support
- Cross-platform CMake configuration
- Shell script for easy building
- Windows compatible via MSYS2

### 7. Unit Testing
- Comprehensive test coverage
- PID controller tests
- State machine transition tests
- CANBUS message handling tests
- Automated test discovery

### 8. Static Linking
- All dependencies built from source
- No runtime library dependencies
- Single executable deployment
- Google Test fetched at build time

## Building and Running

### Prerequisites
- CMake 3.14 or higher
- C++17 compatible compiler (GCC 7+, Clang 5+, MSVC 2017+)
- POSIX threads support
- Git (for Google Test download)
- Python 3.8+ (for Python implementation)
- pytest (optional, for Python tests)

### Build Instructions

Using the build script:
```bash
chmod +x build.sh
./build.sh
```

Manual build:
```bash
mkdir build
cd build
cmake ..
cmake --build . -j$(nproc)
```

### Running the Application

Basic usage:
```bash
./build/eae_firmware
```

With custom temperature setpoint:
```bash
./build/eae_firmware --setpoint 68.0 --debug
```

Test mode with simulated inputs:
```bash
./build/eae_firmware --test --debug
```

## Testing

Run all unit tests:
```bash
./build/eae_tests
```

Run specific test suite:
```bash
./build/eae_tests --gtest_filter=PIDControllerTest.*
```

Run with XML output for CI:
```bash
./build/eae_tests --gtest_output=xml:test_results.xml
```

### Python Testing

Run Python unit tests:
```bash
python -m pytest test_cooling_control.py -v
```

Run the Python implementation demo:
```bash
python3 cooling_control.py
```

## CI/CD Pipeline

This project features a comprehensive CI/CD pipeline using GitHub Actions that ensures code quality and reliability.

### 🔄 Continuous Integration

#### Multi-Platform Testing
- **Operating Systems**: Ubuntu Latest (24.04), Ubuntu 20.04
- **Compilers**: GCC 9/10/11, Clang (defaults to 18)
- **Python Versions**: 3.8, 3.9, 3.10, 3.11

#### Code Quality Checks
- **Static Analysis**: cppcheck, clang-tidy
- **Code Formatting**: clang-format verification
- **Memory Safety**: AddressSanitizer, ThreadSanitizer, Valgrind
- **Security Scanning**: GitHub Super Linter
- **Code Coverage**: gcovr and lcov with HTML reports

#### Automated Testing
- Unit test execution on every push
- Python implementation testing
- Memory leak detection
- Thread safety verification
- Test result artifact upload

### 📦 Continuous Delivery

#### Automated Releases
- Triggers on version tags (v*.*.\*)
- Builds release packages automatically
- Creates GitHub releases with artifacts
- Generates release notes from commits

#### Documentation
- Automated Doxygen generation
- API documentation updates
- Coverage report generation

### 🛡️ Pipeline Features

- **Parallel Execution**: Tests run concurrently for faster feedback
- **Matrix Strategy**: Multiple compiler/OS combinations tested
- **Artifact Management**: Test results and coverage reports preserved
- **Comprehensive Results Collection**: JSON, CSV, and XML formats for analysis
- **Historical Tracking**: Automatic persistence of test results to repository
- **Slack Notifications**: Real-time alerts for both successes and failures
- **Dependency Management**: Automated updates via Dependabot
- **Pull Request Template**: Standardized contribution process

### 📊 Status Monitoring

Check the build status and coverage on the badges at the top of this README or visit:
- [Actions Tab](https://github.com/murr2k/EAE_Firmware/actions) - View all workflow runs
- [Pull Requests](https://github.com/murr2k/EAE_Firmware/pulls) - See PR checks in action

### 🚀 Workflow Files

- [`.github/workflows/ci.yml`](.github/workflows/ci.yml) - Main CI pipeline (updated for Ubuntu 24.04)
- [`.github/workflows/coverage.yml`](.github/workflows/coverage.yml) - Code coverage analysis
- [`.github/workflows/release.yml`](.github/workflows/release.yml) - Automated releases
- [`.github/dependabot.yml`](.github/dependabot.yml) - Dependency updates
- [`.github/pull_request_template.md`](.github/pull_request_template.md) - PR template

## Design Decisions

1. **Modular Architecture**: Each component (CAN, PID, State Machine) is independently testable
2. **Thread Safety**: All shared state uses atomic variables to prevent race conditions
3. **Template-Based State Machine**: Allows reuse for different state/event types
4. **Simulated Hardware**: CANBUS simulation enables testing without physical hardware
5. **Safety First**: Multiple layers of protection including timeouts and emergency states
6. **Real-Time Performance**: 10Hz control loop suitable for thermal systems
7. **CI/CD Integration**: Automated quality assurance from development to deployment

## Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork the Repository**: Create your own fork to work on
2. **Create a Feature Branch**: `git checkout -b feature/amazing-feature`
3. **Write Tests**: Ensure your changes are covered by tests
4. **Run CI Locally**:
   ```bash
   ./build.sh
   ./build/eae_tests
   ```
5. **Submit a Pull Request**: Use the PR template and ensure all checks pass

### Development Workflow

1. The CI pipeline will automatically run when you push to your fork
2. All tests must pass before merging
3. Code coverage should not decrease
4. Follow the existing code style (enforced by clang-format)
5. Update documentation as needed

### Code Quality Standards

- **C++ Standard**: C++17
- **Style Guide**: Enforced by clang-format
- **Static Analysis**: Must pass cppcheck and clang-tidy
- **Memory Safety**: Must pass sanitizer tests
- **Test Coverage**: Aim for >80% coverage

## Current Status

### Build Status
- **C++ Builds**: ✅ All passing (GCC 9/10/11, Clang)
- **Python Tests**: ✅ All passing (Python 3.8-3.11)
- **Static Analysis**: ✅ Passing
- **Code Coverage**: ✅ Working and generating reports
- **Documentation**: ✅ Doxygen generation working

### Known Issues
- **Issue #11**: GitHub Super Linter has some markdown formatting warnings
- **Issue #13**: Sanitizer tests configuration needs adjustment

See [Issues](https://github.com/murr2k/EAE_Firmware/issues) for feature requests and bug reports.

## Additional Documentation

- [REVIEWER_QA.md](REVIEWER_QA.md) - Anticipated Q&A for code reviewers
- [TEST_RESULTS.md](TEST_RESULTS.md) - Example outputs from C++ and Python implementations
- [CI_CD_TEST_RESULTS.md](CI_CD_TEST_RESULTS.md) - Detailed CI/CD pipeline test results
- [WORKFLOW_FAILURE_ANALYSIS.md](WORKFLOW_FAILURE_ANALYSIS.md) - CI/CD troubleshooting guide
- [CI_RESULTS_GUIDE.md](CI_RESULTS_GUIDE.md) - Guide to accessing and analyzing CI/CD results
- [SLACK_SETUP.md](SLACK_SETUP.md) - Instructions for setting up Slack notifications

## ChangeLog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.
