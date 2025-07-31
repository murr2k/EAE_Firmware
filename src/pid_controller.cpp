/*
 * EAE Firmware - PID Controller
 * Author: Murray Kopit
 * Date: July 31, 2025
 * 
 * Generic PID controller implementation with anti-windup.
 */

#include "pid_controller.h"

PIDController::PIDController(const Parameters& params)
    : params_(params), integral_(0.0), lastError_(0.0), derivative_(0.0), firstRun_(true) {
}

double PIDController::calculate(double processValue) {
    auto now = std::chrono::steady_clock::now();
    
    double error = params_.setpoint - processValue;
    
    // Calculate time delta
    double dt = 0.1;  // Default to 100ms
    if (!firstRun_) {
        dt = std::chrono::duration<double>(now - lastTime_).count();
    }
    
    // Proportional term
    double pTerm = params_.kp * error;
    
    // Integral term with anti-windup
    integral_ += error * dt;
    integral_ = std::clamp(integral_, params_.integralMin, params_.integralMax);
    double iTerm = params_.ki * integral_;
    
    // Derivative term
    if (!firstRun_ && dt > 0) {
        derivative_ = (error - lastError_) / dt;
    }
    double dTerm = params_.kd * derivative_;
    
    // Calculate output
    double output = pTerm + iTerm + dTerm;
    output = std::clamp(output, params_.outputMin, params_.outputMax);
    
    // Update state
    lastError_ = error;
    lastTime_ = now;
    firstRun_ = false;
    
    return output;
}

void PIDController::reset() {
    integral_ = 0.0;
    lastError_ = 0.0;
    derivative_ = 0.0;
    firstRun_ = true;
}

void PIDController::setSetpoint(double setpoint) {
    params_.setpoint = setpoint;
}

void PIDController::setParameters(const Parameters& params) {
    params_ = params;
}