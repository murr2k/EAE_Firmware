# EAE Firmware Challenge Submission

**Author:** Murray Kopit  
**Date:** July 31, 2025

This repository contains the solutions for the EAE Engineering Challenge - Electrical and Controls section, specifically Questions 7 and 7.1.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Question 7: Cooling Loop Control Logic](#question-7-cooling-loop-control-logic)
- [Question 7.1: Advanced Firmware Features](#question-71-advanced-firmware-features)
- [Building and Running](#building-and-running)
- [Testing](#testing)
- [Design Decisions](#design-decisions)
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

```
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
├── README.md              # This file
├── CHANGELOG.md           # Version history
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

## Design Decisions

1. **Modular Architecture**: Each component (CAN, PID, State Machine) is independently testable
2. **Thread Safety**: All shared state uses atomic variables to prevent race conditions
3. **Template-Based State Machine**: Allows reuse for different state/event types
4. **Simulated Hardware**: CANBUS simulation enables testing without physical hardware
5. **Safety First**: Multiple layers of protection including timeouts and emergency states
6. **Real-Time Performance**: 10Hz control loop suitable for thermal systems

## ChangeLog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.