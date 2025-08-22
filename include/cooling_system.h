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
 * EAE Firmware - Cooling System Header
 * Author: Murray Kopit
 * Date: July 31, 2025
 */

#ifndef COOLING_SYSTEM_H
#define COOLING_SYSTEM_H

#include "state_machine.h"
#include "pid_controller.h"
#include "canbus_simulator.h"
#include <atomic>
#include <thread>

enum class SystemState {
    OFF,
    INITIALIZING,
    RUNNING,
    ERROR,
    EMERGENCY_STOP
};

enum class SystemEvent {
    IGNITION_ON,
    IGNITION_OFF,
    INIT_COMPLETE,
    LOW_COOLANT,
    OVER_TEMP,
    CRITICAL_TEMP,
    ERROR_CLEARED,
    TEMP_NORMAL
};

class CoolingSystem {
public:
    struct Config {
        double tempMin = 50.0;
        double tempTarget = 65.0;
        double tempMax = 75.0;
        double tempCritical = 85.0;
        double fanStartTemp = 60.0;

        // CAN IDs
        uint32_t tempSensorId = 0x100;
        uint32_t levelSensorId = 0x101;
        uint32_t ignitionId = 0x102;
        uint32_t pumpControlId = 0x200;
        uint32_t fanControlId = 0x201;
    };

    CoolingSystem(const Config& config);
    ~CoolingSystem();

    void start();
    void stop();

    // Command line interface
    void setTemperatureSetpoint(double setpoint);
    void enableDebugMode(bool enable);

    SystemState getState() const { return stateMachine_.getCurrentState(); }
    double getCurrentTemp() const { return currentTemp_; }
    int getFanSpeed() const { return fanSpeed_; }
    bool isPumpOn() const { return pumpOn_; }

private:
    void controlLoop();
    void setupStateMachine();
    void setupCANHandlers();
    void handleTemperature(double temp);
    void updateOutputs();

    Config config_;
    StateMachine<SystemState, SystemEvent> stateMachine_;
    PIDController fanPID_;
    std::unique_ptr<CANBusSimulator> canbus_;

    std::atomic<bool> running_;
    std::thread controlThread_;

    // System state
    std::atomic<double> currentTemp_;
    std::atomic<bool> levelOk_;
    std::atomic<bool> ignition_;
    std::atomic<bool> pumpOn_;
    std::atomic<bool> fanOn_;
    std::atomic<int> fanSpeed_;

    // Debug mode
    std::atomic<bool> debugMode_;
};

#endif // COOLING_SYSTEM_H
