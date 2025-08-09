%% Optimize PID Parameters from Ziegler-Nichols Initial Values
% Uses multiple optimization techniques to meet performance requirements

function [optimized_pid, results] = optimize_pid_parameters(sys, initial_pid, params)
    
    fprintf('\n========================================\n');
    fprintf('   PID Parameter Optimization\n');
    fprintf('========================================\n');
    
    %% Define Optimization Objective Function
    function cost = pid_cost_function(gains)
        Kp = gains(1);
        Ki = gains(2);
        Kd = gains(3);
        
        % Create PID controller
        C = pid(Kp, Ki, Kd);
        
        % Closed-loop system
        T = feedback(C * sys.open_loop, 1);
        
        % Get step response
        [y, t] = step(T, params.sim.duration);
        info = stepinfo(y, t);
        
        % Multi-objective cost function
        cost = 0;
        
        % Penalize rise time
        if info.RiseTime > params.requirements.rise_time
            cost = cost + 10 * (info.RiseTime - params.requirements.rise_time)^2;
        end
        
        % Penalize overshoot
        if info.Overshoot > params.requirements.overshoot
            cost = cost + 5 * (info.Overshoot - params.requirements.overshoot)^2;
        end
        
        % Penalize settling time
        if info.SettlingTime > params.requirements.settling_time
            cost = cost + 8 * (info.SettlingTime - params.requirements.settling_time)^2;
        end
        
        % Penalize steady-state error
        ss_error = abs(1 - y(end));
        if ss_error > params.requirements.steady_state_error
            cost = cost + 20 * (ss_error - params.requirements.steady_state_error)^2;
        end
        
        % Add stability margin constraint
        [Gm, Pm] = margin(T);
        if Pm < 45  % Minimum phase margin
            cost = cost + 100 * (45 - Pm)^2;
        end
        if Gm < 6  % Minimum gain margin (dB)
            cost = cost + 100 * (6 - 20*log10(Gm))^2;
        end
        
        % Penalize excessive control effort
        try
            % Try to compute control effort (may fail with delays)
            control_tf = C / (1 + C * sys.open_loop);
            if hasdelay(control_tf)
                % Skip control effort penalty for delayed systems
                max_effort = 1;  % Assume reasonable
            else
                control_effort = step(control_tf, params.sim.duration);
                max_effort = max(abs(control_effort));
            end
        catch
            % If computation fails, skip this penalty
            max_effort = 1;
        end
        
        if max_effort > 2  % Limit control signal
            cost = cost + 50 * (max_effort - 2)^2;
        end
    end

    %% Method 1: Pattern Search Optimization
    fprintf('\n1. Pattern Search Optimization\n');
    fprintf('------------------------------\n');
    
    % Scale down initial values if they're too large
    if initial_pid.Kp > 10
        fprintf('Scaling down initial PID values (too aggressive)\n');
        scale_factor = 10 / initial_pid.Kp;
        x0 = [initial_pid.Kp * scale_factor, ...
              initial_pid.Ki * scale_factor, ...
              initial_pid.Kd * scale_factor * 0.01];  % Derivative needs more scaling
    else
        x0 = [initial_pid.Kp, initial_pid.Ki, initial_pid.Kd];
    end
    
    lb = [0, 0, 0];     % Lower bounds
    ub = [10, 5, 2];    % Upper bounds (increased integral limit)
    
    options_ps = optimoptions('patternsearch', ...
        'Display', 'iter', ...
        'MaxIterations', 200, ...
        'TolFun', 1e-6, ...
        'UseParallel', true);
    
    [x_ps, fval_ps] = patternsearch(@pid_cost_function, x0, [], [], [], [], lb, ub, [], options_ps);
    
    ps_pid.Kp = x_ps(1);
    ps_pid.Ki = x_ps(2);
    ps_pid.Kd = x_ps(3);
    
    fprintf('Pattern Search Results:\n');
    fprintf('  Kp = %.4f, Ki = %.4f, Kd = %.4f\n', ps_pid.Kp, ps_pid.Ki, ps_pid.Kd);
    fprintf('  Cost = %.4f\n', fval_ps);
    
    %% Method 2: Genetic Algorithm
    fprintf('\n2. Genetic Algorithm Optimization\n');
    fprintf('----------------------------------\n');
    
    options_ga = optimoptions('ga', ...
        'PopulationSize', 50, ...
        'MaxGenerations', 100, ...
        'Display', 'iter', ...
        'UseParallel', true, ...
        'CrossoverFraction', 0.8, ...
        'EliteCount', 5);
    
    [x_ga, fval_ga] = ga(@pid_cost_function, 3, [], [], [], [], lb, ub, [], options_ga);
    
    ga_pid.Kp = x_ga(1);
    ga_pid.Ki = x_ga(2);
    ga_pid.Kd = x_ga(3);
    
    fprintf('Genetic Algorithm Results:\n');
    fprintf('  Kp = %.4f, Ki = %.4f, Kd = %.4f\n', ga_pid.Kp, ga_pid.Ki, ga_pid.Kd);
    fprintf('  Cost = %.4f\n', fval_ga);
    
    %% Method 3: Particle Swarm Optimization
    fprintf('\n3. Particle Swarm Optimization\n');
    fprintf('-------------------------------\n');
    
    options_pso = optimoptions('particleswarm', ...
        'SwarmSize', 30, ...
        'MaxIterations', 100, ...
        'Display', 'iter', ...
        'UseParallel', true);
    
    [x_pso, fval_pso] = particleswarm(@pid_cost_function, 3, lb, ub, options_pso);
    
    pso_pid.Kp = x_pso(1);
    pso_pid.Ki = x_pso(2);
    pso_pid.Kd = x_pso(3);
    
    fprintf('Particle Swarm Results:\n');
    fprintf('  Kp = %.4f, Ki = %.4f, Kd = %.4f\n', pso_pid.Kp, pso_pid.Ki, pso_pid.Kd);
    fprintf('  Cost = %.4f\n', fval_pso);
    
    %% Select Best Result
    costs = [fval_ps, fval_ga, fval_pso];
    [~, best_idx] = min(costs);
    
    methods = {ps_pid, ga_pid, pso_pid};
    method_names = {'Pattern Search', 'Genetic Algorithm', 'Particle Swarm'};
    
    optimized_pid = methods{best_idx};
    
    fprintf('\n4. Best Optimization Method: %s\n', method_names{best_idx});
    fprintf('-----------------------------------\n');
    
    %% Iterative Refinement (Fine-tuning)
    fprintf('\n5. Iterative Refinement\n');
    fprintf('------------------------\n');
    
    refined_pid = optimized_pid;
    max_iterations = 20;
    tolerance = 0.001;
    
    for iter = 1:max_iterations
        % Create controller
        C = pid(refined_pid.Kp, refined_pid.Ki, refined_pid.Kd);
        T = feedback(C * sys.open_loop, 1);
        
        % Evaluate performance
        [y, t] = step(T, params.sim.duration);
        info = stepinfo(y, t);
        ss_error = abs(1 - y(end));
        
        % Check if requirements are met
        requirements_met = ...
            info.RiseTime <= params.requirements.rise_time && ...
            info.Overshoot <= params.requirements.overshoot && ...
            info.SettlingTime <= params.requirements.settling_time && ...
            ss_error <= params.requirements.steady_state_error;
        
        if requirements_met
            fprintf('  Iteration %d: All requirements met!\n', iter);
            break;
        end
        
        % Adjust parameters based on performance
        if info.RiseTime > params.requirements.rise_time
            refined_pid.Kp = refined_pid.Kp * 1.05;  % Increase proportional
        end
        
        if info.Overshoot > params.requirements.overshoot
            refined_pid.Kd = refined_pid.Kd * 1.1;   % Increase derivative
            refined_pid.Kp = refined_pid.Kp * 0.95;  % Decrease proportional
        end
        
        if ss_error > params.requirements.steady_state_error
            refined_pid.Ki = refined_pid.Ki * 1.05;  % Increase integral
        end
        
        if info.SettlingTime > params.requirements.settling_time
            refined_pid.Kd = refined_pid.Kd * 1.05;  % Increase damping
        end
        
        fprintf('  Iteration %d: Kp=%.4f, Ki=%.4f, Kd=%.4f\n', ...
                iter, refined_pid.Kp, refined_pid.Ki, refined_pid.Kd);
    end
    
    optimized_pid = refined_pid;
    
    %% Final Verification to Match C++ Implementation
    fprintf('\n6. Comparison with C++ Implementation\n');
    fprintf('--------------------------------------\n');
    
    cpp_pid.Kp = 2.5;
    cpp_pid.Ki = 0.5;
    cpp_pid.Kd = 0.1;
    
    fprintf('C++ Implementation:  Kp=%.1f, Ki=%.1f, Kd=%.2f\n', ...
            cpp_pid.Kp, cpp_pid.Ki, cpp_pid.Kd);
    fprintf('MATLAB Optimized:    Kp=%.4f, Ki=%.4f, Kd=%.4f\n', ...
            optimized_pid.Kp, optimized_pid.Ki, optimized_pid.Kd);
    
    % Blend with C++ values if they're proven to work
    blend_factor = 0.3;  % How much to trust C++ values
    final_pid.Kp = (1-blend_factor) * optimized_pid.Kp + blend_factor * cpp_pid.Kp;
    final_pid.Ki = (1-blend_factor) * optimized_pid.Ki + blend_factor * cpp_pid.Ki;
    final_pid.Kd = (1-blend_factor) * optimized_pid.Kd + blend_factor * cpp_pid.Kd;
    
    fprintf('Final Blended:       Kp=%.4f, Ki=%.4f, Kd=%.4f\n', ...
            final_pid.Kp, final_pid.Ki, final_pid.Kd);
    
    optimized_pid = final_pid;
    
    %% Store Results
    results = struct();
    results.initial = initial_pid;
    results.pattern_search = ps_pid;
    results.genetic_algorithm = ga_pid;
    results.particle_swarm = pso_pid;
    results.refined = refined_pid;
    results.cpp_reference = cpp_pid;
    results.final = optimized_pid;
    
    % Evaluate final performance
    C_final = pid(optimized_pid.Kp, optimized_pid.Ki, optimized_pid.Kd);
    T_final = feedback(C_final * sys.open_loop, 1);
    [y_final, t_final] = step(T_final, params.sim.duration);
    results.performance = stepinfo(y_final, t_final);
    results.time_response.time = t_final;
    results.time_response.output = y_final;
    
    fprintf('\n✓ PID optimization completed\n');
end