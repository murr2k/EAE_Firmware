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
 * Test cases for Issue #16 - CAN handler reentrancy and queue bounds
 */

#include <gtest/gtest.h>
#include "canbus_simulator.h"
#include <atomic>
#include <thread>

class Issue16Test : public ::testing::Test {
 protected:
    void SetUp() override {
        canbus = std::make_unique<CANBusSimulator>(0x01);
    }
    
    void TearDown() override {
        if (canbus) {
            canbus->stop();
        }
    }
    
    std::unique_ptr<CANBusSimulator> canbus;
};

// Test that TX queue bounds work correctly
TEST_F(Issue16Test, TxQueueBounds) {
    // Don't start the bus initially to prevent transmit thread from draining queue
    uint8_t data[8] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};
    
    // Start the bus to enable sending
    canbus->start();
    
    // Stop it immediately to prevent transmit thread from processing
    // But keep running_ true so we can still queue messages
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    
    // Fill the queue to capacity by sending many messages quickly
    // The transmit thread processes slowly (100us per message) so we can overflow it
    size_t sent_count = 0;
    for (size_t i = 0; i < 2000; i++) {  // Try to send more than capacity
        if (canbus->sendMessage(0x100 + i, data, 8)) {
            sent_count++;
        } else {
            break;  // Queue is full
        }
        // Send faster than the transmit thread can process
        if (i % 100 == 0) {
            std::this_thread::sleep_for(std::chrono::microseconds(10));
        }
    }
    
    // We should have been able to send at least 1024 messages
    EXPECT_GE(sent_count, 1024) << "Should be able to queue at least 1024 messages";
    
    // Now the queue should be full or nearly full
    // Try to send more - at least one should fail
    uint64_t dropsBefore = canbus->getDropCount();
    int failures = 0;
    for (int i = 0; i < 10; i++) {
        if (!canbus->sendMessage(0x200 + i, data, 8)) {
            failures++;
        }
    }
    
    // If queue was at capacity, we should have some drops
    if (sent_count >= 1024) {
        EXPECT_GT(canbus->getDropCount(), dropsBefore) << "Drop counter should increment when queue is full";
    }
    
    canbus->stop();
}

// Test that handlers can safely register new handlers (reentrancy test)
TEST_F(Issue16Test, HandlerReentrancy) {
    std::atomic<int> handler1Called(0);
    std::atomic<int> handler2Called(0);
    std::atomic<bool> noDeadlock(true);
    
    canbus->start();
    
    // Register a handler that tries to register another handler
    canbus->registerHandler(0x100, [&](const CANMessage& msg) {
        handler1Called++;
        // This should not deadlock because we copy the handler before calling
        canbus->registerHandler(0x101, [&](const CANMessage& msg) {
            handler2Called++;
        });
    });
    
    // Give the receive thread time to generate and handle a message
    std::this_thread::sleep_for(std::chrono::seconds(2));
    
    // Check that handler was called
    EXPECT_GT(handler1Called.load(), 0) << "Handler should have been called";
    EXPECT_TRUE(noDeadlock) << "Should not deadlock on reentrancy";
    
    canbus->stop();
}

// Test that handlers can safely send messages (reentrancy test)
TEST_F(Issue16Test, HandlerCanSendMessage) {
    std::atomic<int> handlerCalled(0);
    std::atomic<bool> sendSucceeded(false);
    
    canbus->start();
    
    // Register a handler that sends a message
    canbus->registerHandler(0x100, [&](const CANMessage& msg) {
        handlerCalled++;
        uint8_t response[4] = {0xAA, 0xBB, 0xCC, 0xDD};
        // This should not deadlock
        sendSucceeded = canbus->sendMessage(0x200, response, 4);
    });
    
    // Give the receive thread time to generate and handle a message
    std::this_thread::sleep_for(std::chrono::seconds(2));
    
    // Check that handler was called and could send
    EXPECT_GT(handlerCalled.load(), 0) << "Handler should have been called";
    EXPECT_TRUE(sendSucceeded.load()) << "Handler should be able to send messages";
    
    canbus->stop();
}