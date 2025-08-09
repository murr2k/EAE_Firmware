%% Run complete thermal analysis with guaranteed plot saving
% This wrapper ensures all plots are properly saved

clear; clc; close all;

% Add scripts to path
addpath('scripts');

% Create timestamp for this session
timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
results_folder = fullfile('results', [timestamp '_complete_analysis']);

% Create folder structure
if ~exist('results', 'dir')
    mkdir('results');
end
mkdir(results_folder);
mkdir(fullfile(results_folder, 'plots'));
mkdir(fullfile(results_folder, 'data'));
mkdir(fullfile(results_folder, 'logs'));

% Start diary to capture console output
diary_file = fullfile(results_folder, 'logs', 'console_output.txt');
diary(diary_file);

fprintf('=====================================\n');
fprintf(' EAE THERMAL CONTROL SYSTEM ANALYSIS\n');
fprintf('=====================================\n\n');
fprintf('Session: %s\n', timestamp);
fprintf('Results folder: %s\n\n', results_folder);

%% Run the main analysis
try
    % Load parameters
    fprintf('Loading system parameters...\n');
    load_default_parameters;
    
    % Create thermal model
    fprintf('Creating thermal system model...\n');
    [sys, components] = create_thermal_model(params);
    
    % Perform Ziegler-Nichols tuning
    fprintf('Performing Ziegler-Nichols tuning...\n');
    [initial_pid, zn_results] = ziegler_nichols_tuning(sys, params);
    
    % Save ZN tuning figure immediately
    zn_fig = findall(0, 'Type', 'figure', 'Name', 'Ziegler-Nichols Tuning Results');
    if ~isempty(zn_fig)
        save_figure_helper(zn_fig(1), 'Ziegler_Nichols_Tuning', results_folder);
    end
    
    % Optimize PID parameters
    fprintf('Optimizing PID parameters...\n');
    [optimized_pid, opt_results] = optimize_pid_parameters(sys, initial_pid, params);
    
    % No figures from optimization (console output only)
    
    % Run comparison analysis
    fprintf('\nRunning control strategy comparison...\n');
    
    % Create comparison figure
    comparison_fig = figure('Name', 'Control Strategy Comparison', 'Position', [50, 50, 1400, 900]);
    
    % Define controllers
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
    
    % Plot each controller response
    controller_names = fieldnames(controllers);
    performance_data = [];
    
    for i = 1:length(controller_names)
        name = controller_names{i};
        C = controllers.(name).C;
        T = feedback(C * sys.open_loop, 1);
        [y, t] = step(T, params.sim.duration);
        info = stepinfo(y, t);
        
        performance_data(i, :) = [info.RiseTime, info.SettlingTime, ...
                                  info.Overshoot, abs(1 - y(end))];
        
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
        
        text(0.5, 0.2, sprintf('Rise: %.1fs\nSettle: %.1fs\nOvershoot: %.1f%%', ...
             info.RiseTime, info.SettlingTime, info.Overshoot), ...
             'Units', 'normalized', 'FontSize', 9);
    end
    
    % Force figure update and save
    drawnow;
    pause(0.5);
    save_figure_helper(comparison_fig, 'Control_Strategy_Comparison', results_folder);
    
    % Create robustness analysis figure
    fprintf('Running robustness analysis...\n');
    robustness_fig = figure('Name', 'Robustness Analysis', 'Position', [100, 150, 1200, 800]);
    
    C_robust = pid(optimized_pid.Kp, optimized_pid.Ki, optimized_pid.Kd);
    variations = [0.7, 0.85, 1.0, 1.15, 1.3];
    colors = lines(length(variations));
    
    % Parameter variation
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
    T_dist = feedback(sys.open_loop, C_robust);
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
    
    % Stability margins
    subplot(2, 2, 4);
    margin(C_robust * sys.open_loop);
    title('Stability Margins');
    
    % Force figure update and save
    drawnow;
    pause(0.5);
    save_figure_helper(robustness_fig, 'Robustness_Analysis', results_folder);
    
    %% Save all data
    fprintf('\nSaving all data and workspace...\n');
    save(fullfile(results_folder, 'data', 'complete_results.mat'), ...
         'sys', 'components', 'initial_pid', 'optimized_pid', ...
         'zn_results', 'opt_results', 'params', 'performance_data', ...
         'controllers', 'controller_names');
    
    %% Generate HTML report
    fprintf('Generating HTML report...\n');
    generate_html_report(results_folder, params, initial_pid, optimized_pid, opt_results);
    
    %% Final summary
    fprintf('\n========================================\n');
    fprintf('   Analysis Complete!\n');
    fprintf('========================================\n');
    fprintf('Results saved to: %s\n', results_folder);
    fprintf('\nPID Evolution:\n');
    fprintf('  Ziegler-Nichols: Kp=%.3f, Ki=%.3f, Kd=%.3f\n', ...
            initial_pid.Kp, initial_pid.Ki, initial_pid.Kd);
    fprintf('  Optimized:       Kp=%.3f, Ki=%.3f, Kd=%.3f\n', ...
            optimized_pid.Kp, optimized_pid.Ki, optimized_pid.Kd);
    fprintf('  C++ Reference:   Kp=%.3f, Ki=%.3f, Kd=%.3f\n', 2.5, 0.5, 0.1);
    
    % List saved files
    fprintf('\nSaved files:\n');
    list_saved_files(results_folder);
    
catch ME
    fprintf('\n!!! Error during analysis: %s\n', ME.message);
    fprintf('Error in: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
end

% Stop diary
diary off;

%% Helper Functions

function generate_html_report(results_folder, params, initial_pid, optimized_pid, opt_results)
    report_file = fullfile(results_folder, 'analysis_report.html');
    fid = fopen(report_file, 'w');
    
    fprintf(fid, '<!DOCTYPE html>\n<html>\n<head>\n');
    fprintf(fid, '<title>EAE Thermal Control Analysis Report</title>\n');
    fprintf(fid, '<style>\n');
    fprintf(fid, 'body { font-family: Arial, sans-serif; margin: 40px; }\n');
    fprintf(fid, 'h1 { color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }\n');
    fprintf(fid, 'h2 { color: #555; margin-top: 30px; }\n');
    fprintf(fid, 'table { border-collapse: collapse; width: 100%%; margin: 20px 0; }\n');
    fprintf(fid, 'th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }\n');
    fprintf(fid, 'th { background-color: #4CAF50; color: white; }\n');
    fprintf(fid, 'tr:nth-child(even) { background-color: #f2f2f2; }\n');
    fprintf(fid, 'img { max-width: 100%%; height: auto; margin: 20px 0; }\n');
    fprintf(fid, '.success { color: green; font-weight: bold; }\n');
    fprintf(fid, '.fail { color: red; font-weight: bold; }\n');
    fprintf(fid, '</style>\n</head>\n<body>\n');
    
    fprintf(fid, '<h1>EAE Thermal Control System Analysis Report</h1>\n');
    fprintf(fid, '<p><strong>Generated:</strong> %s</p>\n', datestr(now));
    
    % System parameters
    fprintf(fid, '<h2>System Parameters</h2>\n');
    fprintf(fid, '<table>\n');
    fprintf(fid, '<tr><th>Parameter</th><th>Value</th></tr>\n');
    fprintf(fid, '<tr><td>Temperature Setpoint</td><td>%.1f °C</td></tr>\n', params.control.temp_setpoint);
    fprintf(fid, '<tr><td>Sample Time</td><td>%.2f s</td></tr>\n', params.control.sample_time);
    fprintf(fid, '<tr><td>Simulation Duration</td><td>%.0f s</td></tr>\n', params.sim.duration);
    fprintf(fid, '</table>\n');
    
    % PID parameters comparison
    fprintf(fid, '<h2>PID Parameters Evolution</h2>\n');
    fprintf(fid, '<table>\n');
    fprintf(fid, '<tr><th>Method</th><th>Kp</th><th>Ki</th><th>Kd</th></tr>\n');
    fprintf(fid, '<tr><td>Ziegler-Nichols</td><td>%.4f</td><td>%.4f</td><td>%.4f</td></tr>\n', ...
            initial_pid.Kp, initial_pid.Ki, initial_pid.Kd);
    fprintf(fid, '<tr><td>Optimized</td><td>%.4f</td><td>%.4f</td><td>%.4f</td></tr>\n', ...
            optimized_pid.Kp, optimized_pid.Ki, optimized_pid.Kd);
    fprintf(fid, '<tr><td>C++ Reference</td><td>2.5000</td><td>0.5000</td><td>0.1000</td></tr>\n');
    fprintf(fid, '</table>\n');
    
    % Performance metrics
    fprintf(fid, '<h2>Performance Metrics</h2>\n');
    fprintf(fid, '<table>\n');
    fprintf(fid, '<tr><th>Metric</th><th>Required</th><th>Achieved</th><th>Status</th></tr>\n');
    
    rise_ok = opt_results.performance.RiseTime <= params.requirements.rise_time;
    fprintf(fid, '<tr><td>Rise Time</td><td>&lt;%.1f s</td><td>%.2f s</td><td class="%s">%s</td></tr>\n', ...
            params.requirements.rise_time, opt_results.performance.RiseTime, ...
            ternary(rise_ok, 'success', 'fail'), ternary(rise_ok, '✓ PASS', '✗ FAIL'));
    
    settle_ok = opt_results.performance.SettlingTime <= params.requirements.settling_time;
    fprintf(fid, '<tr><td>Settling Time</td><td>&lt;%.1f s</td><td>%.2f s</td><td class="%s">%s</td></tr>\n', ...
            params.requirements.settling_time, opt_results.performance.SettlingTime, ...
            ternary(settle_ok, 'success', 'fail'), ternary(settle_ok, '✓ PASS', '✗ FAIL'));
    
    overshoot_ok = opt_results.performance.Overshoot <= params.requirements.overshoot;
    fprintf(fid, '<tr><td>Overshoot</td><td>&lt;%.1f%%</td><td>%.2f%%</td><td class="%s">%s</td></tr>\n', ...
            params.requirements.overshoot, opt_results.performance.Overshoot, ...
            ternary(overshoot_ok, 'success', 'fail'), ternary(overshoot_ok, '✓ PASS', '✗ FAIL'));
    
    fprintf(fid, '</table>\n');
    
    % Plots
    fprintf(fid, '<h2>Analysis Plots</h2>\n');
    plot_files = dir(fullfile(results_folder, 'plots', '*.png'));
    for i = 1:length(plot_files)
        [~, name, ~] = fileparts(plot_files(i).name);
        name_formatted = strrep(name, '_', ' ');
        fprintf(fid, '<h3>%s</h3>\n', name_formatted);
        fprintf(fid, '<img src="plots/%s" alt="%s">\n', plot_files(i).name, name_formatted);
    end
    
    fprintf(fid, '</body>\n</html>\n');
    fclose(fid);
    fprintf('  HTML report saved: analysis_report.html\n');
end

function list_saved_files(results_folder)
    % List plots
    plots_dir = fullfile(results_folder, 'plots');
    if exist(plots_dir, 'dir')
        plot_files = dir(fullfile(plots_dir, '*.*'));
        fprintf('  Plots:\n');
        for i = 1:length(plot_files)
            if ~plot_files(i).isdir && ~startsWith(plot_files(i).name, '.')
                fprintf('    - %s (%.1f KB)\n', plot_files(i).name, plot_files(i).bytes/1024);
            end
        end
    end
    
    % List data files
    data_dir = fullfile(results_folder, 'data');
    if exist(data_dir, 'dir')
        data_files = dir(fullfile(data_dir, '*.mat'));
        fprintf('  Data:\n');
        for i = 1:length(data_files)
            fprintf('    - %s (%.1f KB)\n', data_files(i).name, data_files(i).bytes/1024);
        end
    end
    
    % List logs
    logs_dir = fullfile(results_folder, 'logs');
    if exist(logs_dir, 'dir')
        log_files = dir(fullfile(logs_dir, '*.txt'));
        fprintf('  Logs:\n');
        for i = 1:length(log_files)
            fprintf('    - %s (%.1f KB)\n', log_files(i).name, log_files(i).bytes/1024);
        end
    end
    
    % Check for HTML report
    if exist(fullfile(results_folder, 'analysis_report.html'), 'file')
        fprintf('  Report: analysis_report.html\n');
    end
end

function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end