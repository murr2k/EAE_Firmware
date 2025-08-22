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
 * EAE Firmware - CANBUS Simulator Header
 * Author: Murray Kopit
 * Date: July 31, 2025
 */

#ifndef INCLUDE_CANBUS_SIMULATOR_H_
#define INCLUDE_CANBUS_SIMULATOR_H_

#include <cstdint>
#include <vector>
#include <functional>
#include <thread>
#include <atomic>
#include <mutex>
#include <condition_variable>
#include <queue>
#include <chrono>
#include <map>

struct CANMessage {
    uint32_t id;
    uint8_t data[8];
    uint8_t length;
    std::chrono::steady_clock::time_point timestamp;
};

class CANBusSimulator {
 public:
    using MessageHandler = std::function<void(const CANMessage&)>;

    explicit CANBusSimulator(uint32_t nodeId);
    ~CANBusSimulator();

    void start();
    void stop();

    bool sendMessage(uint32_t id, const uint8_t* data, uint8_t length);
    void registerHandler(uint32_t id, MessageHandler handler);

    // Diagnostic functions
    uint64_t getTxCount() const { return txCount_; }
    uint64_t getRxCount() const { return rxCount_; }

 private:
    void receiveThread();
    void transmitThread();

    uint32_t nodeId_;
    std::atomic<bool> running_;

    std::thread rxThread_;
    std::thread txThread_;

    std::queue<CANMessage> txQueue_;
    std::mutex txMutex_;
    std::condition_variable txCv_;

    std::map<uint32_t, MessageHandler> handlers_;
    std::mutex handlerMutex_;

    std::atomic<uint64_t> txCount_;
    std::atomic<uint64_t> rxCount_;
};

#endif  // INCLUDE_CANBUS_SIMULATOR_H_
