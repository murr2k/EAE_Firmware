/*
 * EAE Firmware - State Machine Tests
 * Author: Murray Kopit
 * Date: July 31, 2025
 */

#include <gtest/gtest.h>
#include "state_machine.h"

enum class TestState {
    IDLE,
    RUNNING,
    ERROR
};

enum class TestEvent {
    START,
    STOP,
    FAULT,
    RESET
};

class StateMachineTest : public ::testing::Test {
protected:
    void SetUp() override {
        sm = std::make_unique<StateMachine<TestState, TestEvent>>(TestState::IDLE);
        
        // Setup states
        sm->addState(TestState::IDLE, 
            [this]() { enterCalled[TestState::IDLE] = true; },
            [this]() { exitCalled[TestState::IDLE] = true; }
        );
        
        sm->addState(TestState::RUNNING,
            [this]() { enterCalled[TestState::RUNNING] = true; },
            [this]() { exitCalled[TestState::RUNNING] = true; }
        );
        
        sm->addState(TestState::ERROR,
            [this]() { enterCalled[TestState::ERROR] = true; },
            [this]() { exitCalled[TestState::ERROR] = true; }
        );
    }
    
    std::unique_ptr<StateMachine<TestState, TestEvent>> sm;
    std::map<TestState, bool> enterCalled;
    std::map<TestState, bool> exitCalled;
};

TEST_F(StateMachineTest, InitialState) {
    EXPECT_EQ(sm->getCurrentState(), TestState::IDLE);
}

TEST_F(StateMachineTest, SimpleTransition) {
    sm->addTransition({TestState::IDLE, TestEvent::START, TestState::RUNNING});
    
    bool result = sm->processEvent(TestEvent::START);
    
    EXPECT_TRUE(result);
    EXPECT_EQ(sm->getCurrentState(), TestState::RUNNING);
    EXPECT_TRUE(exitCalled[TestState::IDLE]);
    EXPECT_TRUE(enterCalled[TestState::RUNNING]);
}

TEST_F(StateMachineTest, InvalidTransition) {
    sm->addTransition({TestState::IDLE, TestEvent::START, TestState::RUNNING});
    
    // Try to process STOP event from IDLE (no transition defined)
    bool result = sm->processEvent(TestEvent::STOP);
    
    EXPECT_FALSE(result);
    EXPECT_EQ(sm->getCurrentState(), TestState::IDLE);
}

TEST_F(StateMachineTest, GuardCondition) {
    bool allowTransition = false;
    
    sm->addTransition({
        TestState::IDLE, 
        TestEvent::START, 
        TestState::RUNNING,
        [&allowTransition](TestEvent) { return allowTransition; }
    });
    
    // Guard returns false
    bool result = sm->processEvent(TestEvent::START);
    EXPECT_FALSE(result);
    EXPECT_EQ(sm->getCurrentState(), TestState::IDLE);
    
    // Guard returns true
    allowTransition = true;
    result = sm->processEvent(TestEvent::START);
    EXPECT_TRUE(result);
    EXPECT_EQ(sm->getCurrentState(), TestState::RUNNING);
}

TEST_F(StateMachineTest, TransitionAction) {
    bool actionExecuted = false;
    
    sm->addTransition({
        TestState::IDLE,
        TestEvent::START,
        TestState::RUNNING,
        nullptr,
        [&actionExecuted]() { actionExecuted = true; }
    });
    
    sm->processEvent(TestEvent::START);
    
    EXPECT_TRUE(actionExecuted);
}

TEST_F(StateMachineTest, MultipleTransitions) {
    sm->addTransition({TestState::IDLE, TestEvent::START, TestState::RUNNING});
    sm->addTransition({TestState::RUNNING, TestEvent::STOP, TestState::IDLE});
    sm->addTransition({TestState::RUNNING, TestEvent::FAULT, TestState::ERROR});
    sm->addTransition({TestState::ERROR, TestEvent::RESET, TestState::IDLE});
    
    // IDLE -> RUNNING
    EXPECT_TRUE(sm->processEvent(TestEvent::START));
    EXPECT_EQ(sm->getCurrentState(), TestState::RUNNING);
    
    // RUNNING -> ERROR
    EXPECT_TRUE(sm->processEvent(TestEvent::FAULT));
    EXPECT_EQ(sm->getCurrentState(), TestState::ERROR);
    
    // ERROR -> IDLE
    EXPECT_TRUE(sm->processEvent(TestEvent::RESET));
    EXPECT_EQ(sm->getCurrentState(), TestState::IDLE);
}