# EAE Firmware CMake Configuration
# Author: Murray Kopit
# Date: July 31, 2025

cmake_minimum_required(VERSION 3.14)
project(EAE_Firmware VERSION 1.1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Dependencies
find_package(Threads REQUIRED)

# Google Test
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/release-1.12.1.zip
)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# Source files
set(SOURCES
    src/main.cpp
    src/canbus_simulator.cpp
    src/pid_controller.cpp
    src/state_machine.cpp
    src/cooling_system.cpp
)

# Include directories
include_directories(include)

# Main executable
add_executable(eae_firmware ${SOURCES})
target_link_libraries(eae_firmware Threads::Threads)

# Test executable
enable_testing()
add_executable(eae_tests
    tests/test_main.cpp
    tests/test_pid.cpp
    tests/test_state_machine.cpp
    tests/test_canbus.cpp
    src/canbus_simulator.cpp
    src/pid_controller.cpp
    src/state_machine.cpp
    src/cooling_system.cpp
)
target_link_libraries(eae_tests gtest gmock Threads::Threads)
add_test(NAME eae_tests COMMAND eae_tests)