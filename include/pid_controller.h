/*
 * EAE Firmware - PID Controller Header
 * Author: Murray Kopit
 * Date: July 31, 2025
 */

#ifndef PID_CONTROLLER_H
#define PID_CONTROLLER_H

#include <chrono>
#include <algorithm>

class PIDController {
public:
    struct Parameters {
        double kp;
        double ki;
        double kd;
        double setpoint;
        double outputMin;
        double outputMax;
        double integralMin;
        double integralMax;
    };
    
    explicit PIDController(const Parameters& params);
    
    double calculate(double processValue);
    void reset();
    void setSetpoint(double setpoint);
    void setParameters(const Parameters& params);
    
    double getError() const { return lastError_; }
    double getIntegral() const { return integral_; }
    double getDerivative() const { return derivative_; }
    
private:
    Parameters params_;
    double integral_;
    double lastError_;
    double derivative_;
    std::chrono::steady_clock::time_point lastTime_;
    bool firstRun_;
};

#endif // PID_CONTROLLER_H