%% Create Thermal System Transfer Functions
% Generates transfer function models for the cooling system

function [sys, components] = create_thermal_model(params)
    
    fprintf('Creating thermal system model...\n');
    
    % Laplace variable
    s = tf('s');
    
    %% Engine Thermal Dynamics
    % Time constant based on thermal mass and heat transfer
    tau_engine = (params.engine.thermal_mass * params.engine.specific_heat) / ...
                 (params.radiator.heat_transfer_coeff * params.radiator.surface_area);
    
    % Engine temperature dynamics (heat input to temperature)
    components.engine = 1 / (params.engine.thermal_mass * params.engine.specific_heat * s + ...
                            params.radiator.heat_transfer_coeff * params.radiator.surface_area);
    
    %% Coolant Flow Dynamics
    % First-order lag for pump response
    components.pump = 1 / (params.pump.response_time * s + 1);
    
    %% Radiator Heat Transfer
    % Heat removal as function of flow rate and temperature difference
    % Simplified model: effectiveness varies with flow rate
    K_radiator = params.radiator.effectiveness * ...
                 params.radiator.heat_transfer_coeff * ...
                 params.radiator.surface_area;
    
    tau_radiator = params.coolant.volume * params.coolant.density * ...
                   params.coolant.specific_heat / K_radiator;
    
    components.radiator = K_radiator / (tau_radiator * s + 1);
    
    %% Fan Dynamics
    % Air flow affects heat transfer coefficient
    tau_fan = 0.3;  % Fan spin-up time constant
    components.fan = 1 / (tau_fan * s + 1);
    
    %% Temperature Sensor Dynamics
    components.sensor = 1 / (params.sensor.response_time * s + 1);
    
    %% Complete System Model
    % Simplified: Engine -> Coolant -> Radiator -> Environment
    % With pump controlling flow rate and fan controlling air flow
    
    % Open-loop transfer function (pump/fan input to temperature output)
    sys.open_loop = components.engine * components.radiator * components.sensor;
    
    % Add time delays for transport lag
    transport_delay = 0.5;  % seconds (coolant circulation time)
    sys.open_loop = sys.open_loop * exp(-transport_delay * s);
    
    %% Create State-Space Model for Advanced Analysis
    [A, B, C, D] = ssdata(sys.open_loop);
    sys.state_space = ss(A, B, C, D);
    
    %% Discrete-Time Model (for digital control)
    sys.discrete = c2d(sys.open_loop, params.control.sample_time, 'zoh');
    
    %% Display Model Properties
    fprintf('\nSystem Model Properties:\n');
    fprintf('------------------------\n');
    
    % Get system characteristics
    [Gm, Pm, Wcg, Wcp] = margin(sys.open_loop);
    fprintf('Gain Margin: %.2f dB at %.2f rad/s\n', 20*log10(Gm), Wcg);
    fprintf('Phase Margin: %.2f degrees at %.2f rad/s\n', Pm, Wcp);
    
    % Poles and zeros
    poles_sys = pole(sys.open_loop);
    zeros_sys = zero(sys.open_loop);
    fprintf('Dominant pole: %.4f\n', max(real(poles_sys)));
    fprintf('System order: %d\n', length(poles_sys));
    
    %% Create Linearized Model Points
    % For different operating conditions
    sys.operating_points = struct();
    
    % Low temperature operation
    sys.operating_points.cold = sys.open_loop * 0.8;  % Reduced effectiveness
    
    % Normal operation
    sys.operating_points.normal = sys.open_loop;
    
    % High temperature operation  
    sys.operating_points.hot = sys.open_loop * 1.1;  % Increased effectiveness
    
    fprintf('\n✓ Thermal model created successfully\n');
end