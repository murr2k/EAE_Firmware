%% Ziegler-Nichols PID Tuning for Thermal Control System
% Implements both reaction curve and ultimate gain methods

function [pid_params, tuning_results] = ziegler_nichols_tuning(sys, params)
    
    fprintf('\n========================================\n');
    fprintf('   Ziegler-Nichols PID Tuning\n');
    fprintf('========================================\n');
    
    %% Method 1: Reaction Curve Method (Open-Loop)
    fprintf('\n1. Reaction Curve Method\n');
    fprintf('------------------------\n');
    
    % Step response of open-loop system
    [y, t] = step(sys.open_loop);
    
    % Find the inflection point
    dy = diff(y)./diff(t);
    [~, idx_max] = max(dy);
    
    % Tangent line at inflection point
    slope = dy(idx_max);
    y_tangent = y(idx_max) - slope * t(idx_max);
    tangent_line = slope * t + y_tangent;
    
    % Find delay (L) and time constant (T)
    L = -y_tangent / slope;  % x-intercept of tangent
    K = y(end);  % steady-state gain
    T = (0.632 * K - y_tangent) / slope - L;  % 63.2% rise time
    
    fprintf('Process Parameters:\n');
    fprintf('  Delay (L): %.3f seconds\n', L);
    fprintf('  Time Constant (T): %.3f seconds\n', T);
    fprintf('  Static Gain (K): %.3f\n', K);
    
    % Ziegler-Nichols formulas for reaction curve
    reaction_curve = struct();
    reaction_curve.P.Kp = T / (K * L);
    reaction_curve.P.Ki = 0;
    reaction_curve.P.Kd = 0;
    
    reaction_curve.PI.Kp = 0.9 * T / (K * L);
    reaction_curve.PI.Ki = reaction_curve.PI.Kp / (3.33 * L);
    reaction_curve.PI.Kd = 0;
    
    reaction_curve.PID.Kp = 1.2 * T / (K * L);
    reaction_curve.PID.Ki = reaction_curve.PID.Kp / (2 * L);
    reaction_curve.PID.Kd = reaction_curve.PID.Kp * 0.5 * L;
    
    fprintf('\nReaction Curve PID Parameters:\n');
    fprintf('  Kp = %.3f\n', reaction_curve.PID.Kp);
    fprintf('  Ki = %.3f\n', reaction_curve.PID.Ki);
    fprintf('  Kd = %.3f\n', reaction_curve.PID.Kd);
    
    %% Method 2: Ultimate Gain Method (Closed-Loop)
    fprintf('\n2. Ultimate Gain Method\n');
    fprintf('------------------------\n');
    
    % Check if system has delays
    if hasdelay(sys.open_loop)
        % Use Pade approximation for delayed systems
        fprintf('System has delays - using Pade approximation\n');
        [num, den] = pade(0.5, 3);  % 3rd order Pade for 0.5s delay
        sys_approx = tf(num, den) * sys.open_loop;
        sys_approx.InputDelay = 0;  % Remove delay after approximation
    else
        sys_approx = sys.open_loop;
    end
    
    % Find critical gain using root locus
    [rlocus_data, rlocus_k] = rlocus(sys_approx);
    
    % Find where system becomes marginally stable
    for i = 1:length(rlocus_k)
        poles = rlocus_data(:, i);
        if any(real(poles) > -1e-6)  % Pole crosses imaginary axis
            Kc = rlocus_k(i);  % Critical gain
            critical_poles = poles(abs(real(poles)) < 1e-3);
            if ~isempty(critical_poles)
                wc = abs(imag(critical_poles(1)));  % Critical frequency
                Pc = 2 * pi / wc;  % Critical period
                break;
            end
        end
    end
    
    % Alternative: Use Nyquist criterion
    if ~exist('Kc', 'var') || ~exist('Pc', 'var')
        [Gm, ~, ~, Wcg] = margin(sys_approx);
        Kc = Gm;  % Critical gain
        if isfinite(Gm) && Wcg > 0
            Pc = 2 * pi / Wcg;  % Critical period
        else
            % System is very stable, use approximate values
            fprintf('System is very stable - using estimated parameters\n');
            Kc = 100;  % Large gain estimate
            Pc = 10;   % Reasonable period estimate
        end
    end
    
    fprintf('Critical Parameters:\n');
    if isfinite(Kc)
        fprintf('  Critical Gain (Kc): %.3f\n', Kc);
    else
        fprintf('  Critical Gain (Kc): Very large (stable system)\n');
        Kc = 100;  % Use large value for calculations
    end
    
    if exist('Pc', 'var')
        fprintf('  Critical Period (Pc): %.3f seconds\n', Pc);
        fprintf('  Critical Frequency: %.3f rad/s\n', 2*pi/Pc);
    else
        Pc = 10;  % Default value
        fprintf('  Critical Period (Pc): Estimated as %.3f seconds\n', Pc);
    end
    
    % Ziegler-Nichols formulas for ultimate gain
    ultimate_gain = struct();
    ultimate_gain.P.Kp = 0.5 * Kc;
    ultimate_gain.P.Ki = 0;
    ultimate_gain.P.Kd = 0;
    
    ultimate_gain.PI.Kp = 0.45 * Kc;
    ultimate_gain.PI.Ki = ultimate_gain.PI.Kp / (0.833 * Pc);
    ultimate_gain.PI.Kd = 0;
    
    ultimate_gain.PID.Kp = 0.6 * Kc;
    ultimate_gain.PID.Ki = ultimate_gain.PID.Kp / (0.5 * Pc);
    ultimate_gain.PID.Kd = ultimate_gain.PID.Kp * 0.125 * Pc;
    
    fprintf('\nUltimate Gain PID Parameters:\n');
    fprintf('  Kp = %.3f\n', ultimate_gain.PID.Kp);
    fprintf('  Ki = %.3f\n', ultimate_gain.PID.Ki);
    fprintf('  Kd = %.3f\n', ultimate_gain.PID.Kd);
    
    %% Select Initial Parameters (Average of both methods)
    pid_params = struct();
    pid_params.Kp = (reaction_curve.PID.Kp + ultimate_gain.PID.Kp) / 2;
    pid_params.Ki = (reaction_curve.PID.Ki + ultimate_gain.PID.Ki) / 2;
    pid_params.Kd = (reaction_curve.PID.Kd + ultimate_gain.PID.Kd) / 2;
    
    fprintf('\n3. Initial PID Parameters (Average)\n');
    fprintf('------------------------------------\n');
    fprintf('  Kp = %.3f\n', pid_params.Kp);
    fprintf('  Ki = %.3f\n', pid_params.Ki);
    fprintf('  Kd = %.3f\n', pid_params.Kd);
    
    %% Simulate with Initial Parameters
    fprintf('\n4. Simulating System Response\n');
    fprintf('------------------------------\n');
    
    % Create PID controller
    C_pid = pid(pid_params.Kp, pid_params.Ki, pid_params.Kd);
    
    % Closed-loop system
    T_closed = feedback(C_pid * sys.open_loop, 1);
    
    % Step response
    [y_step, t_step] = step(T_closed, params.sim.duration);
    
    % Calculate performance metrics
    info = stepinfo(y_step, t_step);
    
    fprintf('Performance Metrics:\n');
    fprintf('  Rise Time: %.2f seconds\n', info.RiseTime);
    fprintf('  Settling Time: %.2f seconds\n', info.SettlingTime);
    fprintf('  Overshoot: %.2f%%\n', info.Overshoot);
    fprintf('  Peak: %.2f\n', info.Peak);
    fprintf('  Steady-State Error: %.4f\n', abs(1 - y_step(end)));
    
    %% Store Results
    tuning_results = struct();
    tuning_results.reaction_curve = reaction_curve;
    tuning_results.ultimate_gain = ultimate_gain;
    tuning_results.initial_pid = pid_params;
    tuning_results.performance = info;
    tuning_results.time_response.time = t_step;
    tuning_results.time_response.output = y_step;
    tuning_results.closed_loop_tf = T_closed;
    
    %% Plot Results
    figure('Name', 'Ziegler-Nichols Tuning Results', 'Position', [100, 100, 1200, 800]);
    
    % Subplot 1: Open-loop step response with tangent
    subplot(2, 3, 1);
    plot(t, y, 'b-', 'LineWidth', 2);
    hold on;
    plot(t, tangent_line, 'r--', 'LineWidth', 1);
    plot([L, L], [0, K], 'g--', 'LineWidth', 1);
    plot([L+T, L+T], [0, K], 'g--', 'LineWidth', 1);
    grid on;
    xlabel('Time (s)');
    ylabel('Output');
    title('Open-Loop Step Response');
    legend('System', 'Tangent', 'L', 'L+T', 'Location', 'best');
    
    % Subplot 2: Root locus
    subplot(2, 3, 2);
    rlocus(sys_approx);
    hold on;
    critical_idx = find(rlocus_k >= Kc, 1);
    if ~isempty(critical_idx)
        plot(real(rlocus_data(:, critical_idx)), ...
             imag(rlocus_data(:, critical_idx)), ...
             'ro', 'MarkerSize', 10, 'LineWidth', 2);
    end
    title(sprintf('Root Locus (Kc = %.2f)', Kc));
    grid on;
    
    % Subplot 3: Nyquist plot
    subplot(2, 3, 3);
    nyquist(sys_approx);
    title('Nyquist Plot');
    grid on;
    
    % Subplot 4: Closed-loop step response
    subplot(2, 3, 4);
    plot(t_step, y_step, 'b-', 'LineWidth', 2);
    hold on;
    plot([0, params.sim.duration], [1, 1], 'r--', 'LineWidth', 1);
    plot([0, params.sim.duration], [1.05, 1.05], 'g--', 'LineWidth', 0.5);
    plot([0, params.sim.duration], [0.95, 0.95], 'g--', 'LineWidth', 0.5);
    grid on;
    xlabel('Time (s)');
    ylabel('Output');
    title('Closed-Loop Step Response');
    legend('Response', 'Setpoint', '±5% Band', 'Location', 'best');
    
    % Subplot 5: Bode plot
    subplot(2, 3, 5);
    bode(T_closed);
    title('Closed-Loop Bode Plot');
    grid on;
    
    % Subplot 6: Performance comparison
    subplot(2, 3, 6);
    categories = {'Rise Time', 'Settling Time', 'Overshoot'};
    actual = [info.RiseTime, info.SettlingTime, info.Overshoot];
    target = [params.requirements.rise_time, ...
              params.requirements.settling_time, ...
              params.requirements.overshoot];
    
    bar_data = [actual; target]';
    bar(bar_data);
    set(gca, 'XTickLabel', categories);
    ylabel('Value');
    title('Performance vs Requirements');
    legend('Actual', 'Target', 'Location', 'best');
    grid on;
    
    fprintf('\n✓ Ziegler-Nichols tuning completed\n');
end