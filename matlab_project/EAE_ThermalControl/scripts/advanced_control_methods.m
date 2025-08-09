%% Advanced Control Methods for Thermal System
% Implements MPC, Adaptive Control, and Machine Learning approaches

function advanced_control_methods(sys, params)
    
    fprintf('\n========================================\n');
    fprintf('   ADVANCED CONTROL METHODS\n');
    fprintf('========================================\n');
    
    %% 1. Model Predictive Control (MPC)
    fprintf('\n1. Model Predictive Control\n');
    fprintf('----------------------------\n');
    
    % Convert to discrete state-space
    Ts = params.control.sample_time;
    sys_d = c2d(sys.state_space, Ts);
    
    % Create MPC controller
    mpc_controller = mpc(sys_d, Ts);
    
    % Set prediction and control horizons
    mpc_controller.PredictionHorizon = 20;    % 2 seconds ahead
    mpc_controller.ControlHorizon = 5;        % 0.5 seconds
    
    % Set constraints
    mpc_controller.MV.Min = 0;                % Minimum control (pump/fan off)
    mpc_controller.MV.Max = 100;              % Maximum control (full power)
    mpc_controller.MV.RateMin = -50;          % Maximum decrease rate
    mpc_controller.MV.RateMax = 50;           % Maximum increase rate
    
    % Set weights
    mpc_controller.Weights.OutputVariables = 1;     % Temperature tracking
    mpc_controller.Weights.ManipulatedVariables = 0.1;  % Control effort
    mpc_controller.Weights.ManipulatedVariablesRate = 0.05;  % Smooth control
    
    % Set reference tracking
    mpc_controller.Model.Nominal.Y = params.control.temp_setpoint;
    
    % Simulate MPC
    T_sim = params.sim.duration;
    N = T_sim / Ts;
    
    % Initialize
    x = zeros(size(sys_d.A, 1), 1);
    y_mpc = zeros(N, 1);
    u_mpc = zeros(N, 1);
    r = params.control.temp_setpoint * ones(N, 1);
    
    % Add disturbance at t=100
    r(100:150) = params.control.temp_setpoint + 10;
    
    fprintf('Simulating MPC control...\n');
    for k = 1:N-1
        % Get MPC control action
        u_mpc(k) = mpcmove(mpc_controller, x, y_mpc(k), r(k));
        
        % Plant simulation
        x = sys_d.A * x + sys_d.B * u_mpc(k);
        y_mpc(k+1) = sys_d.C * x;
    end
    
    % Plot MPC results
    figure('Name', 'Advanced Control Methods', 'Position', [150, 100, 1200, 900]);
    
    subplot(3, 3, 1);
    t = 0:Ts:T_sim-Ts;
    plot(t, y_mpc, 'b-', 'LineWidth', 2);
    hold on;
    plot(t, r, 'r--', 'LineWidth', 1);
    grid on;
    xlabel('Time (s)');
    ylabel('Temperature');
    title('Model Predictive Control');
    legend('Output', 'Reference', 'Location', 'best');
    
    subplot(3, 3, 4);
    stairs(t, u_mpc, 'g-', 'LineWidth', 1.5);
    grid on;
    xlabel('Time (s)');
    ylabel('Control Signal (%)');
    title('MPC Control Effort');
    
    %% 2. Adaptive Control (Model Reference)
    fprintf('\n2. Model Reference Adaptive Control\n');
    fprintf('------------------------------------\n');
    
    % Reference model (desired closed-loop response)
    omega_n = 0.5;  % Natural frequency
    zeta = 0.7;     % Damping ratio
    ref_model = tf(omega_n^2, [1, 2*zeta*omega_n, omega_n^2]);
    ref_model_d = c2d(ref_model, Ts);
    
    % Initialize adaptive parameters
    theta = [1; 0.1];  % Initial controller parameters
    gamma = 0.01;      % Adaptation gain
    
    % Simulation
    y_adapt = zeros(N, 1);
    u_adapt = zeros(N, 1);
    theta_history = zeros(2, N);
    
    % Reference model states
    [Am, Bm, Cm, Dm] = ssdata(ref_model_d);
    xm = zeros(size(Am, 1), 1);
    
    fprintf('Simulating adaptive control...\n');
    for k = 2:N-1
        % Reference model output
        xm = Am * xm + Bm * r(k);
        ym = Cm * xm;
        
        % Adaptive control law
        phi = [y_adapt(k); u_adapt(k-1)];
        u_adapt(k) = theta' * phi;
        u_adapt(k) = max(0, min(100, u_adapt(k)));  % Saturate
        
        % Plant output (simplified simulation)
        y_adapt(k+1) = 0.9 * y_adapt(k) + 0.1 * u_adapt(k);
        
        % Adaptation law (gradient descent)
        e = y_adapt(k) - ym;
        theta = theta - gamma * e * phi;
        theta_history(:, k) = theta;
    end
    
    subplot(3, 3, 2);
    plot(t, y_adapt, 'b-', 'LineWidth', 2);
    hold on;
    plot(t, r, 'r--', 'LineWidth', 1);
    grid on;
    xlabel('Time (s)');
    ylabel('Temperature');
    title('Model Reference Adaptive Control');
    legend('Output', 'Reference', 'Location', 'best');
    
    subplot(3, 3, 5);
    plot(t, theta_history', 'LineWidth', 1.5);
    grid on;
    xlabel('Time (s)');
    ylabel('Parameter Value');
    title('Adaptive Parameter Evolution');
    legend('\theta_1', '\theta_2', 'Location', 'best');
    
    %% 3. Fuzzy Logic Control
    fprintf('\n3. Fuzzy Logic Control\n');
    fprintf('-----------------------\n');
    
    % Create Fuzzy Inference System
    fis = mamfis('Name', 'ThermalControl');
    
    % Add input: Temperature Error
    fis = addInput(fis, [-30 30], 'Name', 'error');
    fis = addMF(fis, 'error', 'trimf', [-30 -15 0], 'Name', 'NB');  % Negative Big
    fis = addMF(fis, 'error', 'trimf', [-15 -5 5], 'Name', 'NS');   % Negative Small
    fis = addMF(fis, 'error', 'trimf', [-5 5 15], 'Name', 'ZE');    % Zero
    fis = addMF(fis, 'error', 'trimf', [5 15 30], 'Name', 'PS');    % Positive Small
    fis = addMF(fis, 'error', 'trimf', [15 30 30], 'Name', 'PB');   % Positive Big
    
    % Add input: Error Derivative
    fis = addInput(fis, [-10 10], 'Name', 'derror');
    fis = addMF(fis, 'derror', 'trimf', [-10 -5 0], 'Name', 'N');   % Negative
    fis = addMF(fis, 'derror', 'trimf', [-5 0 5], 'Name', 'Z');     % Zero
    fis = addMF(fis, 'derror', 'trimf', [0 5 10], 'Name', 'P');     % Positive
    
    % Add output: Control Signal
    fis = addOutput(fis, [0 100], 'Name', 'control');
    fis = addMF(fis, 'control', 'trimf', [0 0 25], 'Name', 'VL');   % Very Low
    fis = addMF(fis, 'control', 'trimf', [0 25 50], 'Name', 'L');   % Low
    fis = addMF(fis, 'control', 'trimf', [25 50 75], 'Name', 'M');  % Medium
    fis = addMF(fis, 'control', 'trimf', [50 75 100], 'Name', 'H');  % High
    fis = addMF(fis, 'control', 'trimf', [75 100 100], 'Name', 'VH'); % Very High
    
    % Define fuzzy rules
    rules = [
        "error==NB & derror==N => control=VH";
        "error==NB & derror==Z => control=VH";
        "error==NB & derror==P => control=H";
        "error==NS & derror==N => control=H";
        "error==NS & derror==Z => control=H";
        "error==NS & derror==P => control=M";
        "error==ZE & derror==N => control=M";
        "error==ZE & derror==Z => control=M";
        "error==ZE & derror==P => control=M";
        "error==PS & derror==N => control=M";
        "error==PS & derror==Z => control=L";
        "error==PS & derror==P => control=L";
        "error==PB & derror==N => control=L";
        "error==PB & derror==Z => control=VL";
        "error==PB & derror==P => control=VL";
    ];
    fis = addRule(fis, rules);
    
    % Simulate fuzzy control
    y_fuzzy = zeros(N, 1);
    u_fuzzy = zeros(N, 1);
    y_fuzzy(1) = params.env.ambient_temp;
    
    fprintf('Simulating fuzzy logic control...\n');
    for k = 2:N-1
        error = r(k) - y_fuzzy(k);
        derror = (y_fuzzy(k) - y_fuzzy(k-1)) / Ts;
        
        % Evaluate fuzzy controller
        u_fuzzy(k) = evalfis(fis, [error, derror]);
        
        % Simple plant model
        y_fuzzy(k+1) = 0.9 * y_fuzzy(k) + 0.1 * u_fuzzy(k);
    end
    
    subplot(3, 3, 3);
    plot(t, y_fuzzy, 'b-', 'LineWidth', 2);
    hold on;
    plot(t, r, 'r--', 'LineWidth', 1);
    grid on;
    xlabel('Time (s)');
    ylabel('Temperature');
    title('Fuzzy Logic Control');
    legend('Output', 'Reference', 'Location', 'best');
    
    subplot(3, 3, 6);
    stairs(t, u_fuzzy, 'm-', 'LineWidth', 1.5);
    grid on;
    xlabel('Time (s)');
    ylabel('Control Signal (%)');
    title('Fuzzy Control Effort');
    
    %% 4. Neural Network Control (using Deep Learning Toolbox)
    fprintf('\n4. Neural Network Control\n');
    fprintf('--------------------------\n');
    
    % Generate training data from PID controller
    pid_controller = pid(2.5, 0.5, 0.1);  % Use C++ parameters
    T_pid = feedback(pid_controller * sys.open_loop, 1);
    
    % Create training dataset
    n_samples = 1000;
    error_train = 10 * (rand(n_samples, 1) - 0.5);  % Random errors
    derror_train = 5 * (rand(n_samples, 1) - 0.5);   % Random derivatives
    
    % Generate PID outputs for training
    control_train = zeros(n_samples, 1);
    for i = 1:n_samples
        control_train(i) = pid_controller.Kp * error_train(i) + ...
                          pid_controller.Kd * derror_train(i);
        control_train(i) = max(0, min(100, control_train(i)));
    end
    
    % Create and train neural network
    net = feedforwardnet([10, 10]);  % Two hidden layers with 10 neurons each
    net.trainParam.epochs = 100;
    net.trainParam.showWindow = false;
    
    fprintf('Training neural network controller...\n');
    net = train(net, [error_train'; derror_train'], control_train');
    
    % Simulate NN control
    y_nn = zeros(N, 1);
    u_nn = zeros(N, 1);
    y_nn(1) = params.env.ambient_temp;
    
    for k = 2:N-1
        error = r(k) - y_nn(k);
        derror = (y_nn(k) - y_nn(k-1)) / Ts;
        
        % Neural network control
        u_nn(k) = net([error; derror]);
        u_nn(k) = max(0, min(100, u_nn(k)));
        
        % Plant model
        y_nn(k+1) = 0.9 * y_nn(k) + 0.1 * u_nn(k);
    end
    
    subplot(3, 3, 7);
    plot(t, y_nn, 'b-', 'LineWidth', 2);
    hold on;
    plot(t, r, 'r--', 'LineWidth', 1);
    grid on;
    xlabel('Time (s)');
    ylabel('Temperature');
    title('Neural Network Control');
    legend('Output', 'Reference', 'Location', 'best');
    
    %% 5. Comparison
    fprintf('\n5. Performance Comparison\n');
    fprintf('-------------------------\n');
    
    % Calculate performance metrics
    methods = {'MPC', 'Adaptive', 'Fuzzy', 'Neural Net'};
    outputs = {y_mpc, y_adapt, y_fuzzy, y_nn};
    
    subplot(3, 3, 8);
    hold on;
    colors = lines(4);
    for i = 1:4
        plot(t, outputs{i}, 'Color', colors(i, :), 'LineWidth', 1.5);
    end
    plot(t, r, 'k--', 'LineWidth', 1);
    grid on;
    xlabel('Time (s)');
    ylabel('Temperature');
    title('All Methods Comparison');
    legend([methods, {'Reference'}], 'Location', 'best');
    
    % Performance metrics table
    subplot(3, 3, 9);
    axis off;
    
    metrics = zeros(4, 3);  % [ISE, IAE, ITAE]
    for i = 1:4
        e = r - outputs{i};
        metrics(i, 1) = sum(e.^2) * Ts;           % ISE
        metrics(i, 2) = sum(abs(e)) * Ts;         % IAE  
        metrics(i, 3) = sum(t' .* abs(e)) * Ts;   % ITAE
    end
    
    % Display table
    tbl_data = round(metrics, 2);
    tbl = uitable('Data', tbl_data, ...
                  'RowName', methods, ...
                  'ColumnName', {'ISE', 'IAE', 'ITAE'}, ...
                  'Units', 'normalized', ...
                  'Position', [0.1, 0.1, 0.8, 0.8]);
    
    fprintf('\nPerformance Metrics:\n');
    fprintf('Method      | ISE    | IAE    | ITAE\n');
    fprintf('------------|--------|--------|--------\n');
    for i = 1:4
        fprintf('%-11s | %6.2f | %6.2f | %6.2f\n', ...
                methods{i}, metrics(i, 1), metrics(i, 2), metrics(i, 3));
    end
    
    fprintf('\n✓ Advanced control methods analysis complete\n');
end