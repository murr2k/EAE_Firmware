/*
 * EAE Firmware - State Machine Header
 * Author: Murray Kopit
 * Date: July 31, 2025
 */

#ifndef STATE_MACHINE_H
#define STATE_MACHINE_H

#include <functional>
#include <unordered_map>
#include <string>
#include <memory>
#include <map>

template<typename StateType, typename EventType>
class StateMachine {
public:
    using StateHandler = std::function<void()>;
    using TransitionHandler = std::function<bool(EventType)>;
    using TransitionAction = std::function<void()>;
    
    struct Transition {
        StateType fromState;
        EventType event;
        StateType toState;
        TransitionHandler guard;
        TransitionAction action;
    };
    
    StateMachine(StateType initialState) : currentState_(initialState) {}
    
    void addState(StateType state, StateHandler onEnter, StateHandler onExit) {
        states_[state] = {onEnter, onExit};
    }
    
    void addTransition(const Transition& transition) {
        auto key = std::make_pair(transition.fromState, transition.event);
        transitions_[key] = transition;
    }
    
    bool processEvent(EventType event) {
        auto key = std::make_pair(currentState_, event);
        auto it = transitions_.find(key);
        
        if (it == transitions_.end()) {
            return false;
        }
        
        const auto& transition = it->second;
        
        // Check guard condition
        if (transition.guard && !transition.guard(event)) {
            return false;
        }
        
        // Exit current state
        auto stateIt = states_.find(currentState_);
        if (stateIt != states_.end() && stateIt->second.onExit) {
            stateIt->second.onExit();
        }
        
        // Execute transition action
        if (transition.action) {
            transition.action();
        }
        
        // Enter new state
        currentState_ = transition.toState;
        stateIt = states_.find(currentState_);
        if (stateIt != states_.end() && stateIt->second.onEnter) {
            stateIt->second.onEnter();
        }
        
        return true;
    }
    
    StateType getCurrentState() const { return currentState_; }
    
private:
    struct StateHandlers {
        StateHandler onEnter;
        StateHandler onExit;
    };
    
    StateType currentState_;
    std::unordered_map<StateType, StateHandlers> states_;
    std::map<std::pair<StateType, EventType>, Transition> transitions_;
};

#endif // STATE_MACHINE_H