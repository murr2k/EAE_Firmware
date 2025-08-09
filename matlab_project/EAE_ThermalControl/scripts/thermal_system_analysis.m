%% Complete Thermal System Analysis and PID Tuning
% Main script for EAE thermal control system modeling

clear; clc; close all;

% Start diary to capture command window output
if ~exist('results', 'dir')
    mkdir('results');
end
timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
diary_file = fullfile('results', [timestamp '_console_output.txt']);
diary(diary_file);

fprintf('=====================================\n');
fprintf(' EAE THERMAL CONTROL SYSTEM ANALYSIS\n');
fprintf('=====================================\n\n');
fprintf('Session: %s\n\n', timestamp);

%% Load System Parameters
load_default_parameters;

%% Create Thermal System Model
[sys, components] = create_thermal_model(params);

%% Perform Ziegler-Nichols Tuning
[initial_pid, zn_results] = ziegler_nichols_tuning(sys, params);

%% Optimize PID Parameters
[optimized_pid, opt_results] = optimize_pid_parameters(sys, initial_pid, params);

%% Compare Different Control Strategies
fprintf('\n========================================\n');
fprintf('   Control Strategy Comparison\n');
fprintf('========================================\n');

% Define controllers to compare
controllers = struct();
controllers.P_only.C = pid(initial_pid.Kp, 0, 0);
controllers.P_only.name = 'P Only';

controllers.PI.C = pid(initial_pid.Kp, initial_pid.Ki, 0);
controllers.PI.name = 'PI Control';

controllers.ZN_PID.C = pid(initial_pid.Kp, initial_pid.Ki, initial_pid.Kd);
controllers.ZN_PID.name = 'Ziegler-Nichols PID';

controllers.Optimized.C = pid(optimized_pid.Kp, optimized_pid.Ki, optimized_pid.Kd);
controllers.Optimized.name = 'Optimized PID';

controllers.CPP_Impl.C = pid(2.5, 0.5, 0.1);
controllers.CPP_Impl.name = 'C++ Implementation';

% Evaluate each controller
controller_names = fieldnames(controllers);
performance_data = [];

figure('Name', 'Control Strategy Comparison', 'Position', [50, 50, 1400, 900]);

for i = 1:length(controller_names)
    name = controller_names{i};
    C = controllers.(name).C;
    
    % Closed-loop system
    T = feedback(C * sys.open_loop, 1);
    
    % Step response
    [y, t] = step(T, params.sim.duration);
    info = stepinfo(y, t);
    
    % Store performance metrics
    performance_data(i, :) = [info.RiseTime, info.SettlingTime, ...
                              info.Overshoot, abs(1 - y(end))];
    
    % Plot step response
    subplot(3, 2, i);
    plot(t, y, 'LineWidth', 2);
    hold on;
    plot([0, params.sim.duration], [1, 1], 'r--', 'LineWidth', 1);
    plot([0, params.sim.duration], [1.05, 1.05], 'g--', 'LineWidth', 0.5);
    plot([0, params.sim.duration], [0.95, 0.95], 'g--', 'LineWidth', 0.5);
    grid on;
    xlabel('Time (s)');
    ylabel('Temperature (normalized)');
    title(controllers.(name).name);
    legend('Response', 'Setpoint', '±5% Band', 'Location', 'best');
    
    % Add performance text
    text(0.5, 0.2, sprintf('Rise: %.1fs\nSettle: %.1fs\nOvershoot: %.1f%%', ...
         info.RiseTime, info.SettlingTime, info.Overshoot), ...
         'Units', 'normalized', 'FontSize', 9);
end

% Add comparison table
subplot(3, 2, 6);
axis off;

% Create requirements column to match the number of controllers
num_controllers = size(performance_data, 1);
requirements_col = repmat([params.requirements.rise_time; ...
                           params.requirements.settling_time; ...
                           params.requirements.overshoot; ...
                           params.requirements.steady_state_error]', num_controllers, 1);
requirements_col(2:end, :) = NaN;  % Only show requirements once

data_table = [performance_data, requirements_col(1, :)'];

row_names = {};
for i = 1:length(controller_names)
    row_names{i} = controllers.(controller_names{i}).name;
end
row_names{end+1} = 'Requirements';

col_names = {'Rise Time (s)', 'Settling (s)', 'Overshoot (%)', 'SS Error'};

% Create table
tbl = uitable('Data', data_table, ...
              'RowName', row_names, ...
              'ColumnName', col_names, ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.05, 0.9, 0.9]);

%% Robustness Analysis
fprintf('\n========================================\n');
fprintf('   Robustness Analysis\n');
fprintf('========================================\n');

figure('Name', 'Robustness Analysis', 'Position', [100, 150, 1200, 800]);

% Use optimized controller
C_robust = pid(optimized_pid.Kp, optimized_pid.Ki, optimized_pid.Kd);

% Test with parameter variations
variations = [0.7, 0.85, 1.0, 1.15, 1.3];  % ±30% variation
colors = lines(length(variations));

subplot(2, 2, 1);
hold on;
for i = 1:length(variations)
    sys_var = sys.open_loop * variations(i);
    T_var = feedback(C_robust * sys_var, 1);
    [y_var, t_var] = step(T_var, params.sim.duration);
    plot(t_var, y_var, 'Color', colors(i, :), 'LineWidth', 1.5);
end
plot([0, params.sim.duration], [1, 1], 'k--', 'LineWidth', 1);
grid on;
xlabel('Time (s)');
ylabel('Output');
title('Parameter Variation Robustness');
legend(strcat(string(variations*100), '% nominal'), 'Location', 'best');

% Disturbance rejection
subplot(2, 2, 2);
T_dist = feedback(sys.open_loop, C_robust);  % Disturbance to output
[y_dist, t_dist] = step(T_dist, params.sim.duration);
plot(t_dist, y_dist, 'LineWidth', 2);
grid on;
xlabel('Time (s)');
ylabel('Output');
title('Disturbance Rejection');
legend('Load disturbance response', 'Location', 'best');

% Noise sensitivity
subplot(2, 2, 3);
T_noise = feedback(C_robust * sys.open_loop, 1);
t_noise = 0:params.control.sample_time:params.sim.duration;
noise = params.sensor.noise_level * randn(size(t_noise));
[y_clean, ~] = step(T_noise, t_noise);
y_noisy = y_clean + noise';
plot(t_noise, y_clean, 'b-', 'LineWidth', 2);
hold on;
plot(t_noise, y_noisy, 'r-', 'LineWidth', 0.5);
grid on;
xlabel('Time (s)');
ylabel('Output');
title('Noise Sensitivity');
legend('Clean', 'With sensor noise', 'Location', 'best');

% Frequency domain margins
subplot(2, 2, 4);
margin(C_robust * sys.open_loop);
title('Stability Margins');

%% Generate Simulink Model Code
fprintf('\n========================================\n');
fprintf('   Generating Simulink Model\n');
fprintf('========================================\n');

% Create new Simulink model
model_name = 'cooling_system_model';
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end
new_system(model_name);

% Add blocks
add_block('simulink/Sources/Step', [model_name '/Temperature_Setpoint']);
add_block('simulink/Continuous/PID Controller', [model_name '/PID_Controller']);
add_block('simulink/Continuous/Transfer Fcn', [model_name '/Thermal_System']);
add_block('simulink/Math Operations/Sum', [model_name '/Error_Sum']);
add_block('simulink/Sinks/Scope', [model_name '/Temperature_Output']);
add_block('simulink/Sources/Band-Limited White Noise', [model_name '/Sensor_Noise']);
add_block('simulink/Math Operations/Sum', [model_name '/Noise_Sum']);
add_block('simulink/Sinks/To Workspace', [model_name '/Data_Logger']);

% Set parameters
[num, den] = tfdata(sys.open_loop, 'v');
set_param([model_name '/Thermal_System'], 'Numerator', mat2str(num));
set_param([model_name '/Thermal_System'], 'Denominator', mat2str(den));

set_param([model_name '/PID_Controller'], 'P', num2str(optimized_pid.Kp));
set_param([model_name '/PID_Controller'], 'I', num2str(optimized_pid.Ki));
set_param([model_name '/PID_Controller'], 'D', num2str(optimized_pid.Kd));

set_param([model_name '/Temperature_Setpoint'], 'Time', '0');
set_param([model_name '/Temperature_Setpoint'], 'Before', '0');
set_param([model_name '/Temperature_Setpoint'], 'After', num2str(params.control.temp_setpoint));

set_param([model_name '/Sensor_Noise'], 'Cov', num2str(params.sensor.noise_level^2));
set_param([model_name '/Sensor_Noise'], 'Ts', num2str(params.control.sample_time));

% Connect blocks
add_line(model_name, 'Temperature_Setpoint/1', 'Error_Sum/1');
add_line(model_name, 'Error_Sum/1', 'PID_Controller/1');
add_line(model_name, 'PID_Controller/1', 'Thermal_System/1');
add_line(model_name, 'Thermal_System/1', 'Noise_Sum/1');
add_line(model_name, 'Sensor_Noise/1', 'Noise_Sum/2');
add_line(model_name, 'Noise_Sum/1', 'Temperature_Output/1');
add_line(model_name, 'Noise_Sum/1', 'Error_Sum/2');
add_line(model_name, 'Noise_Sum/1', 'Data_Logger/1');

% Auto-arrange
Simulink.BlockDiagram.arrangeSystem(model_name);

% Save model
save_system(model_name, fullfile('models', [model_name '.slx']));

fprintf('✓ Simulink model created: models/%s.slx\n', model_name);

%% Generate Report
fprintf('\n========================================\n');
fprintf('   Final Report\n');
fprintf('========================================\n');

fprintf('\nPID Tuning Evolution:\n');
fprintf('---------------------\n');
fprintf('1. Ziegler-Nichols:  Kp=%.3f, Ki=%.3f, Kd=%.3f\n', ...
        initial_pid.Kp, initial_pid.Ki, initial_pid.Kd);
fprintf('2. Optimized:        Kp=%.3f, Ki=%.3f, Kd=%.3f\n', ...
        optimized_pid.Kp, optimized_pid.Ki, optimized_pid.Kd);
fprintf('3. C++ Reference:    Kp=%.3f, Ki=%.3f, Kd=%.3f\n', ...
        2.5, 0.5, 0.1);

fprintf('\nPerformance Achievement:\n');
fprintf('------------------------\n');
fprintf('Metric           | Required | Achieved | Status\n');
fprintf('-----------------|----------|----------|--------\n');
fprintf('Rise Time        | <%.1fs    | %.1fs     | %s\n', ...
        params.requirements.rise_time, ...
        opt_results.performance.RiseTime, ...
        ternary(opt_results.performance.RiseTime <= params.requirements.rise_time, '✓', '✗'));
fprintf('Settling Time    | <%.1fs   | %.1fs    | %s\n', ...
        params.requirements.settling_time, ...
        opt_results.performance.SettlingTime, ...
        ternary(opt_results.performance.SettlingTime <= params.requirements.settling_time, '✓', '✗'));
fprintf('Overshoot        | <%.1f%%    | %.1f%%     | %s\n', ...
        params.requirements.overshoot, ...
        opt_results.performance.Overshoot, ...
        ternary(opt_results.performance.Overshoot <= params.requirements.overshoot, '✓', '✗'));
fprintf('SS Error         | <%.2f    | %.3f    | %s\n', ...
        params.requirements.steady_state_error, ...
        abs(1 - opt_results.time_response.output(end)), ...
        ternary(abs(1 - opt_results.time_response.output(end)) <= params.requirements.steady_state_error, '✓', '✗'));

% Create results folder for this session
results_folder = fullfile('results', [timestamp '_thermal_analysis']);
if ~exist('results', 'dir')
    mkdir('results');
end
mkdir(results_folder);
mkdir(fullfile(results_folder, 'plots'));
mkdir(fullfile(results_folder, 'data'));
mkdir(fullfile(results_folder, 'logs'));

% Save figures that were created
addpath('scripts');  % Make sure scripts are in path

% Get all open figures and save them
all_figs = findall(0, 'Type', 'figure');
fprintf('\nSaving %d figures...\n', length(all_figs));

% Save each figure individually
for idx = 1:length(all_figs)
    fig = all_figs(idx);
    fig_name = get(fig, 'Name');
    if isempty(fig_name)
        fig_name = sprintf('Figure_%d', fig.Number);
    end
    save_figure_helper(fig, fig_name, results_folder);
end

% Also call the comprehensive save function
save_results_and_plots('thermal_analysis');

% Also save specific analysis results
save(fullfile(results_folder, 'data', 'tuning_results.mat'), ...
     'sys', 'components', 'initial_pid', ...
     'optimized_pid', 'zn_results', 'opt_results', 'params');

% Stop diary
diary off;

% Copy diary to results folder
copyfile(diary_file, fullfile(results_folder, 'logs', 'console_output.txt'));

fprintf('\n✓ Analysis complete!\n');
fprintf('✓ Results saved to: %s\n', results_folder);
fprintf('✓ Simulink model saved to: models/cooling_system_model.slx\n');
fprintf('✓ Open summary.html in the results folder for a complete report\n');

%% Helper function
function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end