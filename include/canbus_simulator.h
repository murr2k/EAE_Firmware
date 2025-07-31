/*
 * EAE Firmware - CANBUS Simulator Header
 * Author: Murray Kopit
 * Date: July 31, 2025
 */

#ifndef CANBUS_SIMULATOR_H
#define CANBUS_SIMULATOR_H

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
    
    CANBusSimulator(uint32_t nodeId);
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

#endif // CANBUS_SIMULATOR_H