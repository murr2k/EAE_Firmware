%% Load Default System Parameters
% Physical parameters for thermal cooling system

% Clear workspace
clear params;

%% Engine/Inverter Parameters
params.engine.heat_generation_max = 50000;     % Watts (50 kW max heat)
params.engine.thermal_mass = 20;               % kg
params.engine.specific_heat = 460;             % J/(kg·K) - cast iron
params.engine.surface_area = 2.5;              % m^2

%% Coolant Parameters
params.coolant.specific_heat = 4186;           % J/(kg·K) - water/glycol mix
params.coolant.density = 1050;                 % kg/m^3
params.coolant.volume = 0.012;                 % m^3 (12 liters)
params.coolant.flow_rate_max = 0.002;          % m^3/s (120 L/min)

%% Radiator Parameters
params.radiator.effectiveness = 0.75;          % Heat exchanger effectiveness
params.radiator.surface_area = 0.8;            % m^2
params.radiator.heat_transfer_coeff = 150;     % W/(m^2·K)

%% Fan Parameters
params.fan.air_flow_max = 3.0;                 % m^3/s
params.fan.power_max = 500;                    % Watts
params.fan.efficiency = 0.65;                  % Fan efficiency

%% Pump Parameters
params.pump.power_rated = 150;                 % Watts
params.pump.efficiency = 0.70;                 % Pump efficiency
params.pump.response_time = 0.5;               % seconds

%% Sensor Parameters
params.sensor.temp_range = [0, 150];           % °C
params.sensor.accuracy = 0.5;                  % °C
params.sensor.response_time = 0.2;             % seconds
params.sensor.noise_level = 0.1;               % °C RMS

%% Environmental Parameters
params.env.ambient_temp = 25;                  % °C
params.env.air_density = 1.2;                  % kg/m^3
params.env.air_specific_heat = 1005;           % J/(kg·K)

%% Control Parameters
params.control.sample_time = 0.1;              % seconds (10 Hz)
params.control.temp_setpoint = 65;             % °C
params.control.temp_critical = 95;             % °C
params.control.temp_warning = 85;              % °C

%% Initial PID Parameters (from C++ implementation)
params.pid.Kp = 1.0;                          % Proportional gain
params.pid.Ki = 0.1;                          % Integral gain
params.pid.Kd = 0.01;                         % Derivative gain
params.pid.output_min = 0;                    % Minimum output
params.pid.output_max = 100;                  % Maximum output (%)
params.pid.integral_limit = 50;               % Anti-windup limit

%% Simulation Parameters
params.sim.duration = 300;                     % seconds (5 minutes)
params.sim.solver = 'ode45';                   % ODE solver
params.sim.max_step = 0.01;                    % Maximum step size

%% Performance Requirements (from REVIEWER_QA.md)
params.requirements.rise_time = 30;            % seconds
params.requirements.overshoot = 5;             % °C
params.requirements.settling_time = 60;        % seconds
params.requirements.steady_state_error = 0.5;  % °C

% Save to workspace
assignin('base', 'params', params);
fprintf('Parameters loaded into workspace as ''params''\n');