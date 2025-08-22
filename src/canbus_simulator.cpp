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
 * EAE Firmware - CANBUS Simulator
 * Author: Murray Kopit
 * Date: July 31, 2025
 *
 * Simulates CANBUS communication for testing without hardware.
 */

#include "include/canbus_simulator.h"
#include <iostream>
#include <random>

CANBusSimulator::CANBusSimulator(uint32_t nodeId)
    : nodeId_(nodeId), running_(false), txCount_(0), rxCount_(0) {
}

CANBusSimulator::~CANBusSimulator() {
    stop();
}

void CANBusSimulator::start() {
    if (running_) return;

    running_ = true;
    rxThread_ = std::thread(&CANBusSimulator::receiveThread, this);
    txThread_ = std::thread(&CANBusSimulator::transmitThread, this);
}

void CANBusSimulator::stop() {
    if (!running_) return;

    running_ = false;
    txCv_.notify_all();

    if (rxThread_.joinable()) rxThread_.join();
    if (txThread_.joinable()) txThread_.join();
}

bool CANBusSimulator::sendMessage(uint32_t id, const uint8_t* data, uint8_t length) {
    if (!running_ || length > 8) return false;

    CANMessage msg;
    msg.id = id;
    msg.length = length;
    msg.timestamp = std::chrono::steady_clock::now();
    std::copy(data, data + length, msg.data);

    {
        std::lock_guard<std::mutex> lock(txMutex_);
        txQueue_.push(msg);
    }
    txCv_.notify_one();

    return true;
}

void CANBusSimulator::registerHandler(uint32_t id, MessageHandler handler) {
    std::lock_guard<std::mutex> lock(handlerMutex_);
    handlers_[id] = handler;
}

void CANBusSimulator::receiveThread() {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> msgDist(100, 500);  // Random message interval

    while (running_) {
        // Simulate receiving messages at random intervals
        std::this_thread::sleep_for(std::chrono::milliseconds(msgDist(gen)));

        // For simulation, we'll generate some test messages
        if (running_) {
            // Simulate temperature sensor message
            CANMessage tempMsg;
            tempMsg.id = 0x100;
            tempMsg.length = 2;
            // Temperature in 0.1°C units
            uint16_t temp = 650 + (rand() % 50);  // 65.0 - 70.0°C
            tempMsg.data[0] = temp >> 8;
            tempMsg.data[1] = temp & 0xFF;
            tempMsg.timestamp = std::chrono::steady_clock::now();

            {
                std::lock_guard<std::mutex> lock(handlerMutex_);
                auto it = handlers_.find(tempMsg.id);
                if (it != handlers_.end()) {
                    it->second(tempMsg);
                    rxCount_++;
                }
            }
        }
    }
}

void CANBusSimulator::transmitThread() {
    while (running_) {
        std::unique_lock<std::mutex> lock(txMutex_);
        txCv_.wait(lock, [this] { return !txQueue_.empty() || !running_; });

        while (!txQueue_.empty() && running_) {
            CANMessage msg = txQueue_.front();
            txQueue_.pop();
            lock.unlock();

            // Simulate transmission delay
            std::this_thread::sleep_for(std::chrono::microseconds(100));

            // In a real system, this would send to hardware
            // For simulation, we'll just count it
            txCount_++;

            lock.lock();
        }
    }
}
