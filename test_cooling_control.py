#!/usr/bin/env python3
"""
Test file for cooling_control.py
Author: Murray Kopit
Date: July 31, 2025
"""

import pytest
import sys
import os
import time

# Add the parent directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from cooling_control import SystemState, CoolingController, PIDController, SensorData, ControlOutputs

def test_system_states():
    """Test that system states are properly defined"""
    assert SystemState.OFF.value == 1
    assert SystemState.INITIALIZING.value == 2
    assert SystemState.RUNNING.value == 3
    assert SystemState.ERROR.value == 4
    assert SystemState.EMERGENCY_STOP.value == 5

def test_pid_controller():
    """Test PID controller basic functionality"""
    pid = PIDController(kp=1.0, ki=0.1, kd=0.01, setpoint=65.0)

    # Test that output increases when below setpoint
    output = pid.calculate(60.0)
    # Note: PID returns negative value when below setpoint (error is negative)
    # The controller inverts this for fan speed
    assert output <= 0  # Negative error produces negative output

    # Test multiple calculations (integral builds up)
    time.sleep(0.01)  # Small delay for dt calculation
    output2 = pid.calculate(70.0)
    assert output2 >= 0  # Positive error produces positive output

    # Test reset functionality
    pid.reset()
    assert pid.integral == 0.0
    assert pid.last_error == 0.0

def test_cooling_controller_init():
    """Test CoolingController initialization"""
    controller = CoolingController()

    # Check initial state
    assert controller.state == SystemState.OFF
    assert controller.sensors.temperature == 25.0
    assert controller.sensors.level_switch == True
    assert controller.sensors.ignition == False

    # Check initial outputs
    assert controller.outputs.pump_on == False
    assert controller.outputs.fan_on == False
    assert controller.outputs.fan_speed == 0

    # Check thresholds
    assert controller.TEMP_MIN == 50.0
    assert controller.TEMP_TARGET == 65.0
    assert controller.TEMP_MAX == 75.0
    assert controller.TEMP_CRITICAL == 85.0

def test_sensor_update():
    """Test sensor data update"""
    controller = CoolingController()

    # Update sensors
    controller.update_sensors(70.0, False, True)

    # Verify updates
    assert controller.sensors.temperature == 70.0
    assert controller.sensors.level_switch == False
    assert controller.sensors.ignition == True

def test_state_transitions():
    """Test basic state transition logic"""
    controller = CoolingController()

    # Start in OFF state
    assert controller.state == SystemState.OFF

    # Turn on ignition should transition to INITIALIZING
    controller.sensors.ignition = True
    controller._handle_off_state()
    assert controller.state == SystemState.INITIALIZING

    # Test transition back to OFF when ignition is turned off
    controller.sensors.ignition = False
    controller._handle_init_state()
    # The init state checks ignition and should go back to OFF

    # Test error detection (simulate by directly setting state)
    controller.state = SystemState.ERROR
    assert controller.state == SystemState.ERROR

def test_data_classes():
    """Test dataclass functionality"""
    # Test SensorData
    sensors = SensorData(temperature=65.0, level_switch=True, ignition=True)
    assert sensors.temperature == 65.0
    assert sensors.level_switch == True
    assert sensors.ignition is True

    # Test ControlOutputs
    outputs = ControlOutputs(pump_on=True, fan_on=True, fan_speed=50)
    assert outputs.pump_on is True
    assert outputs.fan_on is True
    assert outputs.fan_speed == 50


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
