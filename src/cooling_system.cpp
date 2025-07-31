/*
 * EAE Firmware - Cooling System Controller
 * Author: Murray Kopit
 * Date: July 31, 2025
 * 
 * Main cooling system control logic with state machine and PID control.
 */

#include "cooling_system.h"
#include <iostream>
#include <iomanip>

CoolingSystem::CoolingSystem(const Config& config)
    : config_(config),
      stateMachine_(SystemState::OFF),
      fanPID_(PIDController::Parameters{
          2.5, 0.5, 0.1, config.tempTarget,
          0.0, 100.0, -50.0, 50.0
      }),
      running_(false),
      currentTemp_(25.0),
      levelOk_(true),
      ignition_(false),
      pumpOn_(false),
      fanOn_(false),
      fanSpeed_(0),
      debugMode_(false) {
    
    canbus_ = std::make_unique<CANBusSimulator>(0x01);
    setupStateMachine();
    setupCANHandlers();
}

CoolingSystem::~CoolingSystem() {
    stop();
}

void CoolingSystem::start() {
    if (running_) return;
    
    running_ = true;
    canbus_->start();
    controlThread_ = std::thread(&CoolingSystem::controlLoop, this);
    
    if (debugMode_) {
        std::cout << "Cooling system started" << std::endl;
    }
}

void CoolingSystem::stop() {
    if (!running_) return;
    
    running_ = false;
    if (controlThread_.joinable()) {
        controlThread_.join();
    }
    canbus_->stop();
    
    if (debugMode_) {
        std::cout << "Cooling system stopped" << std::endl;
    }
}

void CoolingSystem::setTemperatureSetpoint(double setpoint) {
    config_.tempTarget = setpoint;
    fanPID_.setSetpoint(setpoint);
    
    if (debugMode_) {
        std::cout << "Temperature setpoint changed to: " << setpoint << "°C" << std::endl;
    }
}

void CoolingSystem::enableDebugMode(bool enable) {
    debugMode_ = enable;
}

void CoolingSystem::setupStateMachine() {
    // Define state handlers
    stateMachine_.addState(SystemState::OFF, 
        [this]() {
            pumpOn_ = false;
            fanOn_ = false;
            fanSpeed_ = 0;
            updateOutputs();
            if (debugMode_) std::cout << "State: OFF" << std::endl;
        },
        nullptr
    );
    
    stateMachine_.addState(SystemState::INITIALIZING,
        [this]() {
            if (debugMode_) std::cout << "State: INITIALIZING" << std::endl;
            pumpOn_ = true;
            updateOutputs();
            
            // Simulate init complete after 2 seconds
            std::thread([this]() {
                std::this_thread::sleep_for(std::chrono::seconds(2));
                if (running_ && stateMachine_.getCurrentState() == SystemState::INITIALIZING) {
                    stateMachine_.processEvent(SystemEvent::INIT_COMPLETE);
                }
            }).detach();
        },
        nullptr
    );
    
    stateMachine_.addState(SystemState::RUNNING,
        [this]() {
            if (debugMode_) std::cout << "State: RUNNING" << std::endl;
        },
        nullptr
    );
    
    stateMachine_.addState(SystemState::ERROR,
        [this]() {
            if (debugMode_) std::cout << "State: ERROR" << std::endl;
            pumpOn_ = false;
            fanOn_ = false;
            fanSpeed_ = 0;
            updateOutputs();
        },
        nullptr
    );
    
    stateMachine_.addState(SystemState::EMERGENCY_STOP,
        [this]() {
            if (debugMode_) std::cout << "State: EMERGENCY_STOP" << std::endl;
            pumpOn_ = false;
            fanOn_ = true;
            fanSpeed_ = 100;
            updateOutputs();
        },
        nullptr
    );
    
    // Define transitions
    stateMachine_.addTransition({
        SystemState::OFF, SystemEvent::IGNITION_ON, SystemState::INITIALIZING,
        [this](SystemEvent) { return levelOk_.load(); },
        nullptr
    });
    
    stateMachine_.addTransition({
        SystemState::INITIALIZING, SystemEvent::INIT_COMPLETE, SystemState::RUNNING,
        nullptr, nullptr
    });
    
    stateMachine_.addTransition({
        SystemState::RUNNING, SystemEvent::IGNITION_OFF, SystemState::OFF,
        nullptr, nullptr
    });
    
    stateMachine_.addTransition({
        SystemState::RUNNING, SystemEvent::LOW_COOLANT, SystemState::ERROR,
        nullptr, nullptr
    });
    
    stateMachine_.addTransition({
        SystemState::RUNNING, SystemEvent::CRITICAL_TEMP, SystemState::EMERGENCY_STOP,
        nullptr, nullptr
    });
    
    stateMachine_.addTransition({
        SystemState::ERROR, SystemEvent::ERROR_CLEARED, SystemState::INITIALIZING,
        [this](SystemEvent) { return ignition_.load(); },
        nullptr
    });
    
    stateMachine_.addTransition({
        SystemState::EMERGENCY_STOP, SystemEvent::TEMP_NORMAL, SystemState::ERROR,
        nullptr, nullptr
    });
}

void CoolingSystem::setupCANHandlers() {
    // Temperature sensor handler
    canbus_->registerHandler(config_.tempSensorId, [this](const CANMessage& msg) {
        if (msg.length >= 2) {
            uint16_t tempRaw = (msg.data[0] << 8) | msg.data[1];
            double temp = tempRaw / 10.0;
            handleTemperature(temp);
        }
    });
    
    // Level sensor handler
    canbus_->registerHandler(config_.levelSensorId, [this](const CANMessage& msg) {
        if (msg.length >= 1) {
            bool newLevel = msg.data[0] != 0;
            if (newLevel != levelOk_) {
                levelOk_ = newLevel;
                if (!levelOk_ && stateMachine_.getCurrentState() == SystemState::RUNNING) {
                    stateMachine_.processEvent(SystemEvent::LOW_COOLANT);
                }
            }
        }
    });
    
    // Ignition handler
    canbus_->registerHandler(config_.ignitionId, [this](const CANMessage& msg) {
        if (msg.length >= 1) {
            bool newIgnition = msg.data[0] != 0;
            if (newIgnition != ignition_) {
                ignition_ = newIgnition;
                if (ignition_) {
                    stateMachine_.processEvent(SystemEvent::IGNITION_ON);
                } else {
                    stateMachine_.processEvent(SystemEvent::IGNITION_OFF);
                }
            }
        }
    });
}

void CoolingSystem::handleTemperature(double temp) {
    currentTemp_ = temp;
    
    auto state = stateMachine_.getCurrentState();
    
    // Check for critical conditions
    if (temp > config_.tempCritical && state == SystemState::RUNNING) {
        stateMachine_.processEvent(SystemEvent::CRITICAL_TEMP);
    } else if (temp < config_.tempMax && state == SystemState::EMERGENCY_STOP) {
        stateMachine_.processEvent(SystemEvent::TEMP_NORMAL);
    }
    
    // Temperature control in running state
    if (state == SystemState::RUNNING) {
        if (temp > config_.fanStartTemp) {
            fanOn_ = true;
            fanSpeed_ = static_cast<int>(fanPID_.calculate(temp));
        } else if (temp < (config_.fanStartTemp - 5.0)) {
            fanOn_ = false;
            fanSpeed_ = 0;
            fanPID_.reset();
        }
        updateOutputs();
    }
}

void CoolingSystem::updateOutputs() {
    // Send pump control
    uint8_t pumpData[1] = { pumpOn_ ? 1 : 0 };
    canbus_->sendMessage(config_.pumpControlId, pumpData, 1);
    
    // Send fan control
    uint8_t fanData[2] = { fanOn_ ? 1 : 0, static_cast<uint8_t>(fanSpeed_) };
    canbus_->sendMessage(config_.fanControlId, fanData, 2);
}

void CoolingSystem::controlLoop() {
    while (running_) {
        // Main control runs at 10Hz
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        
        if (debugMode_) {
            std::cout << std::fixed << std::setprecision(1);
            std::cout << "Temp: " << currentTemp_.load() << "°C, "
                      << "Pump: " << (pumpOn_ ? "ON" : "OFF") << ", "
                      << "Fan: " << (fanOn_ ? "ON" : "OFF") << ", "
                      << "Speed: " << fanSpeed_.load() << "%, "
                      << "CAN TX: " << canbus_->getTxCount() 
                      << " RX: " << canbus_->getRxCount() << std::endl;
        }
    }
}