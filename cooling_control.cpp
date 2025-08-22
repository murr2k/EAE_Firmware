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
 * EAE Cooling Loop Control Logic - C++ Implementation
 * Author: Murray Kopit
 * Date: July 31, 2025
 *
 * Controls coolant temperature for Inverter and DC-DC converter
 */

#include <iostream>
#include <thread>
#include <chrono>
#include <atomic>
#include <cmath>
#include <iomanip>

enum class SystemState {
    OFF,
    INITIALIZING,
    RUNNING,
    ERROR,
    EMERGENCY_STOP
};

struct SensorData {
    float temperature;     // Celsius
    bool levelSwitch;      // True = OK, False = Low
    bool ignition;         // True = ON, False = OFF
};

struct ControlOutputs {
    bool pumpOn;
    bool fanOn;
    int fanSpeed;          // 0-100%
};

class PIDController {
private:
    float kp, ki, kd;
    float setpoint;
    float integral;
    float lastError;
    std::chrono::steady_clock::time_point lastTime;

public:
    PIDController(float p, float i, float d, float sp)
        : kp(p), ki(i), kd(d), setpoint(sp), integral(0.0f), lastError(0.0f) {
        lastTime = std::chrono::steady_clock::now();
    }

    int calculate(float currentValue) {
        auto now = std::chrono::steady_clock::now();
        float dt = std::chrono::duration<float>(now - lastTime).count();

        float error = currentValue - setpoint;

        // Proportional
        float pTerm = kp * error;

        // Integral with anti-windup
        integral += error * dt;
        if (integral > 50.0f) integral = 50.0f;
        if (integral < -50.0f) integral = -50.0f;
        float iTerm = ki * integral;

        // Derivative
        float dTerm = 0.0f;
        if (dt > 0) {
            dTerm = kd * (error - lastError) / dt;
        }

        // Update state
        lastError = error;
        lastTime = now;

        // Calculate output
        float output = pTerm + iTerm + dTerm;

        // Clamp to 0-100
        if (output < 0) output = 0;
        if (output > 100) output = 100;

        return static_cast<int>(output);
    }

    void reset() {
        integral = 0.0f;
        lastError = 0.0f;
        lastTime = std::chrono::steady_clock::now();
    }
};

class CoolingController {
private:
    // Temperature thresholds (Celsius)
    static constexpr float TEMP_MIN = 50.0f;
    static constexpr float TEMP_TARGET = 65.0f;
    static constexpr float TEMP_MAX = 75.0f;
    static constexpr float TEMP_CRITICAL = 85.0f;

    // Fan control thresholds
    static constexpr float FAN_START_TEMP = 60.0f;
    static constexpr float FAN_MAX_TEMP = 80.0f;
    static constexpr float FAN_HYSTERESIS = 5.0f;

    // Timing constants
    static constexpr float PUMP_INIT_TIME = 2.0f;      // seconds
    static constexpr float LOW_LEVEL_TIMEOUT = 3.0f;    // seconds
    static constexpr float OVER_TEMP_TIMEOUT = 10.0f;   // seconds

    // System state
    SystemState state;
    SensorData sensors;
    ControlOutputs outputs;

    // PID controller
    PIDController fanPID;

    // Timing
    std::chrono::steady_clock::time_point pumpStartTime;
    std::chrono::steady_clock::time_point lowLevelTime;
    std::chrono::steady_clock::time_point overTempTime;
    bool lowLevelTimerActive;
    bool overTempTimerActive;

    // Thread control
    std::atomic<bool> running;
    std::thread controlThread;

    void controlLoop() {
        // Use steady_clock for deterministic timing
        using clock = std::chrono::steady_clock;
        auto next = clock::now();
        const auto period = std::chrono::milliseconds(100);  // 10Hz = 100ms period

        while (running) {
            switch (state) {
                case SystemState::OFF:
                    handleOffState();
                    break;
                case SystemState::INITIALIZING:
                    handleInitState();
                    break;
                case SystemState::RUNNING:
                    handleRunningState();
                    break;
                case SystemState::ERROR:
                    handleErrorState();
                    break;
                case SystemState::EMERGENCY_STOP:
                    handleEmergencyState();
                    break;
            }

            // Calculate next wake time and sleep until then
            // This ensures consistent 100ms periods regardless of processing time
            next += period;
            std::this_thread::sleep_until(next);
        }
    }

    void handleOffState() {
        outputs.pumpOn = false;
        outputs.fanOn = false;
        outputs.fanSpeed = 0;

        if (sensors.ignition) {
            std::cout << "Ignition ON - Starting initialization" << std::endl;
            state = SystemState::INITIALIZING;
        }
    }

    void handleInitState() {
        // Check coolant level
        if (!sensors.levelSwitch) {
            std::cout << "ERROR: Low coolant level detected" << std::endl;
            state = SystemState::ERROR;
            return;
        }

        // Start pump
        if (!outputs.pumpOn) {
            outputs.pumpOn = true;
            pumpStartTime = std::chrono::steady_clock::now();
        }

        // Wait for circulation
        auto elapsed = std::chrono::steady_clock::now() - pumpStartTime;
        if (std::chrono::duration<float>(elapsed).count() > PUMP_INIT_TIME) {
            std::cout << "Initialization complete - System running" << std::endl;
            state = SystemState::RUNNING;
        }
    }

    void handleRunningState() {
        if (!sensors.ignition) {
            std::cout << "Ignition OFF - Shutting down" << std::endl;
            state = SystemState::OFF;
            return;
        }

        // Perform safety checks
        if (!performSafetyChecks()) {
            return;
        }

        // Temperature control
        controlTemperature();
    }

    void handleErrorState() {
        outputs.pumpOn = false;
        outputs.fanOn = false;
        outputs.fanSpeed = 0;

        // Check if error cleared
        if (sensors.levelSwitch && sensors.temperature < TEMP_MAX) {
            if (sensors.ignition) {
                std::cout << "Error cleared - Restarting system" << std::endl;
                state = SystemState::INITIALIZING;
            } else {
                state = SystemState::OFF;
            }
        }
    }

    void handleEmergencyState() {
        // Emergency cooling - run fan at max even with pump off
        outputs.pumpOn = false;
        outputs.fanOn = true;
        outputs.fanSpeed = 100;

        if (sensors.temperature < TEMP_MAX) {
            std::cout << "Temperature reduced - Attempting recovery" << std::endl;
            state = SystemState::ERROR;
        }
    }

    bool performSafetyChecks() {
        // Check coolant level
        if (!sensors.levelSwitch) {
            if (!lowLevelTimerActive) {
                lowLevelTime = std::chrono::steady_clock::now();
                lowLevelTimerActive = true;
            } else {
                auto elapsed = std::chrono::steady_clock::now() - lowLevelTime;
                if (std::chrono::duration<float>(elapsed).count() > LOW_LEVEL_TIMEOUT) {
                    std::cout << "ERROR: Coolant level low for >"
                             << LOW_LEVEL_TIMEOUT << " seconds" << std::endl;
                    state = SystemState::ERROR;
                    return false;
                }
            }
        } else {
            lowLevelTimerActive = false;
        }

        // Check critical temperature
        if (sensors.temperature > TEMP_CRITICAL) {
            std::cout << "CRITICAL: Temperature " << sensors.temperature
                     << "°C exceeds limit" << std::endl;
            state = SystemState::EMERGENCY_STOP;
            return false;
        }

        // Check over-temperature
        if (sensors.temperature > TEMP_MAX) {
            if (!overTempTimerActive) {
                overTempTime = std::chrono::steady_clock::now();
                overTempTimerActive = true;
            } else {
                auto elapsed = std::chrono::steady_clock::now() - overTempTime;
                if (std::chrono::duration<float>(elapsed).count() > OVER_TEMP_TIMEOUT) {
                    std::cout << "ERROR: Over-temperature for >"
                             << OVER_TEMP_TIMEOUT << " seconds" << std::endl;
                    state = SystemState::ERROR;
                    return false;
                }
            }
        } else {
            overTempTimerActive = false;
        }

        return true;
    }

    void controlTemperature() {
        float temp = sensors.temperature;

        // Pump always on when running
        outputs.pumpOn = true;

        // Fan control with hysteresis
        if (temp > FAN_START_TEMP) {
            outputs.fanOn = true;
            outputs.fanSpeed = fanPID.calculate(temp);
        } else if (temp < (FAN_START_TEMP - FAN_HYSTERESIS)) {
            outputs.fanOn = false;
            outputs.fanSpeed = 0;
            fanPID.reset();
        }
    }

public:
    CoolingController()
        : state(SystemState::OFF),
          fanPID(2.5f, 0.5f, 0.1f, TEMP_TARGET),
          lowLevelTimerActive(false),
          overTempTimerActive(false),
          running(false) {
        sensors = {25.0f, true, false};
        outputs = {false, false, 0};
    }

    void start() {
        running = true;
        controlThread = std::thread(&CoolingController::controlLoop, this);
        std::cout << "Cooling control system started" << std::endl;
    }

    void stop() {
        running = false;
        if (controlThread.joinable()) {
            controlThread.join();
        }
        shutdownSystem();
        std::cout << "Cooling control system stopped" << std::endl;
    }

    void updateSensors(float temperature, bool levelSwitch, bool ignition) {
        sensors.temperature = temperature;
        sensors.levelSwitch = levelSwitch;
        sensors.ignition = ignition;
    }

    void getStatus() const {
        std::cout << std::fixed << std::setprecision(1);
        std::cout << "Temp: " << sensors.temperature << "°C, "
                  << "Pump: " << (outputs.pumpOn ? "ON" : "OFF") << ", "
                  << "Fan: " << (outputs.fanOn ? "ON" : "OFF") << ", "
                  << "Fan Speed: " << outputs.fanSpeed << "%" << std::endl;
    }

private:
    void shutdownSystem() {
        outputs.pumpOn = false;
        outputs.fanOn = false;
        outputs.fanSpeed = 0;
        state = SystemState::OFF;
    }
};

// Demo program
int main() {
    std::cout << "=== EAE Cooling Control System Demo ===" << std::endl;
    std::cout << "Simulating system operation..." << std::endl << std::endl;

    CoolingController controller;
    controller.start();

    try {
        // Simulate ignition on
        std::cout << "\n[t=0s] Turning ignition ON" << std::endl;
        controller.updateSensors(25.0f, true, true);
        std::this_thread::sleep_for(std::chrono::seconds(3));

        // Simulate temperature rise
        std::cout << "\n[t=3s] Temperature rising..." << std::endl;
        for (int temp = 25; temp <= 70; temp += 5) {
            controller.updateSensors(static_cast<float>(temp), true, true);
            controller.getStatus();
            std::this_thread::sleep_for(std::chrono::seconds(1));
        }

        // Steady state
        std::cout << "\n[t=12s] Steady state operation" << std::endl;
        controller.updateSensors(68.0f, true, true);
        controller.getStatus();
        std::this_thread::sleep_for(std::chrono::seconds(3));

        // Low coolant
        std::cout << "\n[t=15s] Simulating low coolant level" << std::endl;
        controller.updateSensors(68.0f, false, true);
        std::this_thread::sleep_for(std::chrono::seconds(5));

        // Restore coolant
        std::cout << "\n[t=20s] Coolant level restored" << std::endl;
        controller.updateSensors(65.0f, true, true);
        std::this_thread::sleep_for(std::chrono::seconds(2));

        // Over-temperature
        std::cout << "\n[t=22s] Simulating over-temperature condition" << std::endl;
        controller.updateSensors(88.0f, true, true);
        controller.getStatus();
        std::this_thread::sleep_for(std::chrono::seconds(2));

        // Cool down
        std::cout << "\n[t=24s] Cooling down" << std::endl;
        controller.updateSensors(70.0f, true, true);
        controller.getStatus();
        std::this_thread::sleep_for(std::chrono::seconds(2));

        // Ignition off
        std::cout << "\n[t=26s] Turning ignition OFF" << std::endl;
        controller.updateSensors(65.0f, true, false);
        std::this_thread::sleep_for(std::chrono::seconds(2));

    } catch (...) {
        std::cerr << "Error in demo" << std::endl;
    }

    controller.stop();
    std::cout << "\n=== Demo Complete ===" << std::endl;

    return 0;
}
