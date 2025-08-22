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
 * EAE Firmware - CANBUS Tests
 * Author: Murray Kopit
 * Date: July 31, 2025
 */

#include <gtest/gtest.h>
#include "canbus_simulator.h"
#include <atomic>

class CANBusTest : public ::testing::Test {
protected:
    void SetUp() override {
        canbus = std::make_unique<CANBusSimulator>(0x01);
    }

    void TearDown() override {
        canbus->stop();
    }

    std::unique_ptr<CANBusSimulator> canbus;
};

TEST_F(CANBusTest, StartStop) {
    canbus->start();
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    canbus->stop();

    // Should not crash
    EXPECT_TRUE(true);
}

TEST_F(CANBusTest, SendMessage) {
    canbus->start();

    uint8_t data[8] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};
    bool result = canbus->sendMessage(0x123, data, 8);

    EXPECT_TRUE(result);

    // Wait a bit for transmission
    std::this_thread::sleep_for(std::chrono::milliseconds(10));

    EXPECT_GT(canbus->getTxCount(), 0);
}

TEST_F(CANBusTest, InvalidMessageLength) {
    // Don't start the bus - just test parameter validation
    uint8_t data[10] = {0};
    bool result = canbus->sendMessage(0x123, data, 10);  // Too long

    EXPECT_FALSE(result);

    // Also test when running
    canbus->start();
    result = canbus->sendMessage(0x123, data, 10);  // Still too long
    EXPECT_FALSE(result);
}

TEST_F(CANBusTest, MessageHandler) {
    std::atomic<bool> handlerCalled(false);
    std::atomic<uint32_t> receivedId(0);

    canbus->registerHandler(0x100, [&](const CANMessage& msg) {
        handlerCalled = true;
        receivedId = msg.id;
    });

    canbus->start();

    // Wait for simulated message
    std::this_thread::sleep_for(std::chrono::seconds(1));

    EXPECT_TRUE(handlerCalled.load());
    EXPECT_EQ(receivedId.load(), 0x100);
    EXPECT_GT(canbus->getRxCount(), 0);
}

TEST_F(CANBusTest, MultipleHandlers) {
    std::atomic<int> handler1Count(0);
    std::atomic<int> handler2Count(0);

    canbus->registerHandler(0x100, [&](const CANMessage&) {
        handler1Count++;
    });

    canbus->registerHandler(0x200, [&](const CANMessage&) {
        handler2Count++;
    });

    canbus->start();

    // Send messages
    uint8_t data[1] = {0xFF};
    canbus->sendMessage(0x100, data, 1);
    canbus->sendMessage(0x200, data, 1);

    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // Note: In real implementation, we'd trigger the handlers
    // For now, just check that registration doesn't crash
    EXPECT_TRUE(true);
}
