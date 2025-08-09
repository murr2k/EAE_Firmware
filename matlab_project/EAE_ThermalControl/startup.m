%% EAE Thermal Control System - Project Startup Script
% Author: Murray Kopit
% Date: July 31, 2025
% MATLAB Version: R2025a

fprintf('=====================================\n');
fprintf('EAE Thermal Control System Project\n');
fprintf('=====================================\n');

% Add project paths
addpath(genpath('scripts'));
addpath(genpath('models'));
addpath(genpath('lib'));
addpath(genpath('data'));

% Set up Simulink preferences
try
    set_param(0, 'CharacterEncoding', 'UTF-8');
catch
    % Character encoding might not be available in all versions
end

% Note: SaveFormat parameter removed - not available in all MATLAB versions

% Load default parameters
run('scripts/load_default_parameters.m');

fprintf('✓ Project paths configured\n');
fprintf('✓ Default parameters loaded\n');
fprintf('✓ Ready for thermal system modeling\n\n');

% Display available scripts
fprintf('Available Commands:\n');
fprintf('  >> thermal_system_analysis    - Run complete system analysis\n');
fprintf('  >> ziegler_nichols_tuning     - Perform PID tuning\n');
fprintf('  >> run_simulations            - Execute all simulations\n');
fprintf('  >> generate_reports           - Create analysis reports\n');
fprintf('\nTo start, open: models/cooling_system_model.slx\n');