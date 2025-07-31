#!/usr/bin/env python3
"""
EAE Cooling Loop Control Logic
Author: Murray Kopit
Date: July 31, 2025

Controls coolant temperature for Inverter and DC-DC converter
"""

import time
import threading
from enum import Enum, auto
from dataclasses import dataclass
from typing import Optional

class SystemState(Enum):
    OFF = auto()
    INITIALIZING = auto()
    RUNNING = auto()
    ERROR = auto()
    EMERGENCY_STOP = auto()

@dataclass
class SensorData:
    temperature: float
    level_switch: bool
    ignition: bool

@dataclass
class ControlOutputs:
    pump_on: bool
    fan_on: bool
    fan_speed: int  # 0-100%

class CoolingController:
    def __init__(self):
        # Temperature thresholds (Celsius)
        self.TEMP_MIN = 50.0
        self.TEMP_TARGET = 65.0
        self.TEMP_MAX = 75.0
        self.TEMP_CRITICAL = 85.0
        
        # Fan control thresholds
        self.FAN_START_TEMP = 60.0
        self.FAN_MAX_TEMP = 80.0
        
        # System state
        self.state = SystemState.OFF
        self.sensors = SensorData(25.0, True, False)
        self.outputs = ControlOutputs(False, False, 0)
        
        # PID controller for fan speed
        self.pid = PIDController(kp=2.5, ki=0.5, kd=0.1, setpoint=self.TEMP_TARGET)
        
        # Safety timers
        self.pump_start_time = None
        self.low_level_time = None
        self.over_temp_time = None
        
        # Thread control
        self.running = False
        self.control_thread = None
        
    def start(self):
        """Start the control system"""
        self.running = True
        self.control_thread = threading.Thread(target=self._control_loop)
        self.control_thread.start()
        print("Cooling control system started")
        
    def stop(self):
        """Stop the control system"""
        self.running = False
        if self.control_thread:
            self.control_thread.join()
        self._shutdown_system()
        print("Cooling control system stopped")
        
    def update_sensors(self, temperature: float, level_switch: bool, ignition: bool):
        """Update sensor readings"""
        self.sensors.temperature = temperature
        self.sensors.level_switch = level_switch
        self.sensors.ignition = ignition
        
    def _control_loop(self):
        """Main control loop running at 10Hz"""
        while self.running:
            # State machine logic
            if self.state == SystemState.OFF:
                self._handle_off_state()
            elif self.state == SystemState.INITIALIZING:
                self._handle_init_state()
            elif self.state == SystemState.RUNNING:
                self._handle_running_state()
            elif self.state == SystemState.ERROR:
                self._handle_error_state()
            elif self.state == SystemState.EMERGENCY_STOP:
                self._handle_emergency_state()
                
            # Sleep for 100ms (10Hz update rate)
            time.sleep(0.1)
            
    def _handle_off_state(self):
        """Handle system in OFF state"""
        self.outputs.pump_on = False
        self.outputs.fan_on = False
        self.outputs.fan_speed = 0
        
        if self.sensors.ignition:
            print("Ignition ON - Starting initialization")
            self.state = SystemState.INITIALIZING
            
    def _handle_init_state(self):
        """Handle system initialization"""
        # Check coolant level
        if not self.sensors.level_switch:
            print("ERROR: Low coolant level detected")
            self.state = SystemState.ERROR
            return
            
        # Start pump
        self.outputs.pump_on = True
        self.pump_start_time = time.time()
        
        # Wait for circulation (2 seconds)
        if time.time() - self.pump_start_time > 2.0:
            print("Initialization complete - System running")
            self.state = SystemState.RUNNING
            
    def _handle_running_state(self):
        """Handle normal running state"""
        if not self.sensors.ignition:
            print("Ignition OFF - Shutting down")
            self.state = SystemState.OFF
            return
            
        # Safety checks
        if not self._perform_safety_checks():
            return
            
        # Temperature control
        self._control_temperature()
        
    def _handle_error_state(self):
        """Handle error conditions"""
        # Shut down pump and fan
        self.outputs.pump_on = False
        self.outputs.fan_on = False
        self.outputs.fan_speed = 0
        
        # Check if error condition cleared
        if self.sensors.level_switch and self.sensors.temperature < self.TEMP_MAX:
            if self.sensors.ignition:
                print("Error cleared - Restarting system")
                self.state = SystemState.INITIALIZING
            else:
                self.state = SystemState.OFF
                
    def _handle_emergency_state(self):
        """Handle emergency shutdown"""
        # Run fan at max speed even with pump off
        self.outputs.pump_on = False
        self.outputs.fan_on = True
        self.outputs.fan_speed = 100
        
        # Check if temperature reduced
        if self.sensors.temperature < self.TEMP_MAX:
            print("Temperature reduced - Attempting recovery")
            self.state = SystemState.ERROR
            
    def _perform_safety_checks(self) -> bool:
        """Perform safety checks, return False if unsafe"""
        # Check coolant level
        if not self.sensors.level_switch:
            if self.low_level_time is None:
                self.low_level_time = time.time()
            elif time.time() - self.low_level_time > 3.0:  # 3 second grace period
                print("ERROR: Coolant level low for >3 seconds")
                self.state = SystemState.ERROR
                return False
        else:
            self.low_level_time = None
            
        # Check critical temperature
        if self.sensors.temperature > self.TEMP_CRITICAL:
            print(f"CRITICAL: Temperature {self.sensors.temperature}°C exceeds limit")
            self.state = SystemState.EMERGENCY_STOP
            return False
            
        # Check over-temperature condition
        if self.sensors.temperature > self.TEMP_MAX:
            if self.over_temp_time is None:
                self.over_temp_time = time.time()
            elif time.time() - self.over_temp_time > 10.0:  # 10 second limit
                print("ERROR: Over-temperature for >10 seconds")
                self.state = SystemState.ERROR
                return False
        else:
            self.over_temp_time = None
            
        return True
        
    def _control_temperature(self):
        """Main temperature control logic"""
        temp = self.sensors.temperature
        
        # Pump control (always on when running)
        self.outputs.pump_on = True
        
        # Fan control with hysteresis
        if temp > self.FAN_START_TEMP:
            self.outputs.fan_on = True
            
            # PID control for fan speed
            self.outputs.fan_speed = self.pid.calculate(temp)
            
        elif temp < (self.FAN_START_TEMP - 5.0):  # 5°C hysteresis
            self.outputs.fan_on = False
            self.outputs.fan_speed = 0
            self.pid.reset()
            
    def _shutdown_system(self):
        """Safely shutdown all components"""
        self.outputs.pump_on = False
        self.outputs.fan_on = False
        self.outputs.fan_speed = 0
        self.state = SystemState.OFF
        

class PIDController:
    """Simple PID controller for fan speed control"""
    def __init__(self, kp: float, ki: float, kd: float, setpoint: float):
        self.kp = kp
        self.ki = ki
        self.kd = kd
        self.setpoint = setpoint
        
        self.integral = 0.0
        self.last_error = 0.0
        self.last_time = time.time()
        
    def calculate(self, current_value: float) -> int:
        """Calculate PID output (0-100%)"""
        current_time = time.time()
        dt = current_time - self.last_time
        
        error = current_value - self.setpoint
        
        # Proportional term
        p_term = self.kp * error
        
        # Integral term with anti-windup
        self.integral += error * dt
        self.integral = max(-50, min(50, self.integral))  # Limit integral
        i_term = self.ki * self.integral
        
        # Derivative term
        d_term = self.kd * (error - self.last_error) / dt if dt > 0 else 0
        
        # Calculate output
        output = p_term + i_term + d_term
        
        # Update state
        self.last_error = error
        self.last_time = current_time
        
        # Clamp output to 0-100%
        return max(0, min(100, int(output)))
        
    def reset(self):
        """Reset controller state"""
        self.integral = 0.0
        self.last_error = 0.0
        self.last_time = time.time()


def main():
    """Demonstration of cooling control system"""
    controller = CoolingController()
    
    print("=== EAE Cooling Control System Demo ===")
    print("Simulating system operation...\n")
    
    # Start controller
    controller.start()
    
    try:
        # Simulate ignition on
        print("\n[t=0s] Turning ignition ON")
        controller.update_sensors(25.0, True, True)
        time.sleep(3)
        
        # Simulate temperature rise
        print("\n[t=3s] Temperature rising...")
        for temp in range(25, 70, 5):
            controller.update_sensors(float(temp), True, True)
            print(f"Temp: {temp}°C, Pump: {controller.outputs.pump_on}, "
                  f"Fan: {controller.outputs.fan_on}, Fan Speed: {controller.outputs.fan_speed}%")
            time.sleep(1)
            
        # Simulate steady state
        print("\n[t=12s] Steady state operation")
        controller.update_sensors(68.0, True, True)
        time.sleep(3)
        
        # Simulate low coolant level
        print("\n[t=15s] Simulating low coolant level")
        controller.update_sensors(68.0, False, True)
        time.sleep(5)
        
        # Restore coolant level
        print("\n[t=20s] Coolant level restored")
        controller.update_sensors(65.0, True, True)
        time.sleep(2)
        
        # Simulate over-temperature
        print("\n[t=22s] Simulating over-temperature condition")
        controller.update_sensors(88.0, True, True)
        time.sleep(2)
        
        # Cool down
        print("\n[t=24s] Cooling down")
        controller.update_sensors(70.0, True, True)
        time.sleep(2)
        
        # Ignition off
        print("\n[t=26s] Turning ignition OFF")
        controller.update_sensors(65.0, True, False)
        time.sleep(2)
        
    finally:
        controller.stop()
        print("\n=== Demo Complete ===")


if __name__ == "__main__":
    main()