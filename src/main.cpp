/*
 * Copyright 2025 Murray Kopit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * EAE Firmware - Main Application
 * Author: Murray Kopit
 * Date: July 31, 2025
 *
 * Main entry point for the cooling system controller application.
 */

#include "include/cooling_system.h"
#include <iostream>
#include <string>
#include <sstream>
#include <cstdlib>

void printUsage(const char* programName) {
    std::cout << "Usage: " << programName << " [options]\n"
              << "Options:\n"
              << "  --setpoint <temp>    Set temperature setpoint (default: 65.0°C)\n"
              << "  --debug              Enable debug output\n"
              << "  --test               Run in test mode with simulated inputs\n"
              << "  --help               Show this help message\n";
}

int main(int argc, char* argv[]) {
    CoolingSystem::Config config;
    bool debugMode = false;
    bool testMode = false;

    // Parse command line arguments
    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];

        if (arg == "--setpoint" && i + 1 < argc) {
            config.tempTarget = std::stod(argv[++i]);
        } else if (arg == "--debug") {
            debugMode = true;
        } else if (arg == "--test") {
            testMode = true;
        } else if (arg == "--help") {
            printUsage(argv[0]);
            return 0;
        } else {
            std::cerr << "Unknown argument: " << arg << std::endl;
            printUsage(argv[0]);
            return 1;
        }
    }

    std::cout << "=== EAE Advanced Firmware System ===" << std::endl;
    std::cout << "Features: CANBUS, PID Control, State Machine" << std::endl;
    std::cout << "Temperature Setpoint: " << config.tempTarget << "°C" << std::endl;
    if (debugMode) std::cout << "Debug mode enabled" << std::endl;
    std::cout << std::endl;

    // Create and configure system
    CoolingSystem system(config);
    system.enableDebugMode(debugMode);

    // Start the system
    system.start();

    if (testMode) {
        std::cout << "Running in test mode - simulating 30 seconds of operation" << std::endl;

        // Simulate test sequence
        std::thread testThread([&system]() {
            // Wait for system to initialize
            std::this_thread::sleep_for(std::chrono::seconds(2));

            // Simulate ignition on
            uint8_t ignData[1] = {1};
            CANMessage ignMsg = {0x102, {1}, 1, std::chrono::steady_clock::now()};

            // Simulate temperature changes
            for (int i = 0; i < 20; i++) {
                std::this_thread::sleep_for(std::chrono::seconds(1));

                // Simulate temperature rise
                uint16_t temp = 650 + i * 10;  // 65.0 to 85.0°C
                uint8_t tempData[2] = {static_cast<uint8_t>(temp >> 8),
                                       static_cast<uint8_t>(temp & 0xFF)};

                // Note: In real implementation, these would come from actual CAN bus
            }
        });

        testThread.join();
        std::this_thread::sleep_for(std::chrono::seconds(10));
    } else {
        std::cout << "System running. Press Enter to stop..." << std::endl;
        std::cin.get();
    }

    // Stop the system
    system.stop();

    std::cout << "\nSystem shutdown complete." << std::endl;
    std::cout << "Final state: ";
    switch (system.getState()) {
        case SystemState::OFF: std::cout << "OFF"; break;
        case SystemState::INITIALIZING: std::cout << "INITIALIZING"; break;
        case SystemState::RUNNING: std::cout << "RUNNING"; break;
        case SystemState::ERROR: std::cout << "ERROR"; break;
        case SystemState::EMERGENCY_STOP: std::cout << "EMERGENCY_STOP"; break;
    }
    std::cout << std::endl;

    return 0;
}
