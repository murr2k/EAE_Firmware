/*
 * EAE Firmware - PID Controller Tests
 * Author: Murray Kopit
 * Date: July 31, 2025
 */

#include <gtest/gtest.h>
#include "pid_controller.h"

class PIDControllerTest : public ::testing::Test {
protected:
    void SetUp() override {
        params = {
            1.0,   // kp
            0.1,   // ki
            0.01,  // kd
            50.0,  // setpoint
            0.0,   // outputMin
            100.0, // outputMax
            -100.0, // integralMin
            100.0   // integralMax
        };
    }
    
    PIDController::Parameters params;
};

TEST_F(PIDControllerTest, InitialState) {
    PIDController pid(params);
    
    EXPECT_EQ(pid.getError(), 0.0);
    EXPECT_EQ(pid.getIntegral(), 0.0);
    EXPECT_EQ(pid.getDerivative(), 0.0);
}

TEST_F(PIDControllerTest, ProportionalControl) {
    params.ki = 0.0;  // Disable integral
    params.kd = 0.0;  // Disable derivative
    PIDController pid(params);
    
    double output = pid.calculate(40.0);  // 10 below setpoint
    EXPECT_EQ(output, 10.0);  // kp * error = 1.0 * 10.0
}

TEST_F(PIDControllerTest, OutputClamping) {
    params.kp = 10.0;  // High gain to trigger clamping
    PIDController pid(params);
    
    double output = pid.calculate(0.0);  // 50 below setpoint
    EXPECT_EQ(output, 100.0);  // Clamped to max
    
    output = pid.calculate(100.0);  // 50 above setpoint
    EXPECT_EQ(output, 0.0);  // Clamped to min
}

TEST_F(PIDControllerTest, Reset) {
    PIDController pid(params);
    
    // Run a few cycles to build up state
    pid.calculate(40.0);
    pid.calculate(45.0);
    pid.calculate(48.0);
    
    EXPECT_NE(pid.getIntegral(), 0.0);
    
    pid.reset();
    
    EXPECT_EQ(pid.getError(), 0.0);
    EXPECT_EQ(pid.getIntegral(), 0.0);
    EXPECT_EQ(pid.getDerivative(), 0.0);
}

TEST_F(PIDControllerTest, SetpointChange) {
    PIDController pid(params);
    
    double output1 = pid.calculate(50.0);  // At setpoint
    EXPECT_NEAR(output1, 0.0, 1e-6);
    
    pid.setSetpoint(60.0);
    double output2 = pid.calculate(50.0);  // Now 10 below new setpoint
    EXPECT_GT(output2, 0.0);
}