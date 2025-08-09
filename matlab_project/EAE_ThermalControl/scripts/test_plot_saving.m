%% Test script for plot saving functionality
% This script creates test plots and saves them to verify functionality

clear; clc; close all;

fprintf('Testing plot saving functionality...\n\n');

% Create test figures
fprintf('Creating test figures...\n');

% Figure 1: Simple line plot
fig1 = figure('Name', 'Test Line Plot', 'Position', [100, 100, 800, 600]);
t = 0:0.1:10;
y = sin(t);
plot(t, y, 'b-', 'LineWidth', 2);
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title('Test Sine Wave');

% Figure 2: Multiple subplots
fig2 = figure('Name', 'Test Subplots', 'Position', [200, 200, 1000, 800]);
subplot(2, 2, 1);
plot(t, cos(t), 'r-', 'LineWidth', 2);
grid on;
title('Cosine');

subplot(2, 2, 2);
plot(t, exp(-t/5), 'g-', 'LineWidth', 2);
grid on;
title('Exponential Decay');

subplot(2, 2, 3);
bar([1 2 3 4], [10 25 15 30]);
grid on;
title('Bar Chart');

subplot(2, 2, 4);
scatter(randn(100, 1), randn(100, 1));
grid on;
title('Scatter Plot');

% Create results folder
timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
results_folder = fullfile('results', [timestamp '_test']);

% Test Method 1: Using save_figure_helper
fprintf('\n=== Testing save_figure_helper ===\n');
addpath('scripts');
save_figure_helper(fig1, 'test_line_plot', results_folder);
save_figure_helper(fig2, 'test_subplots', results_folder);

% Test Method 2: Using save_results_and_plots
fprintf('\n=== Testing save_results_and_plots ===\n');
save_results_and_plots('test_saving');

% Test Method 3: Direct saving with different methods
fprintf('\n=== Testing direct save methods ===\n');
test_folder = fullfile('results', 'direct_save_test');
if ~exist(test_folder, 'dir')
    mkdir(test_folder);
end

% Test print command
try
    print(fig1, fullfile(test_folder, 'test_print.png'), '-dpng', '-r300');
    fprintf('✓ print command successful\n');
catch ME
    fprintf('✗ print command failed: %s\n', ME.message);
end

% Test saveas command
try
    saveas(fig1, fullfile(test_folder, 'test_saveas.png'));
    fprintf('✓ saveas command successful\n');
catch ME
    fprintf('✗ saveas command failed: %s\n', ME.message);
end

% Test savefig command
try
    savefig(fig1, fullfile(test_folder, 'test_savefig.fig'));
    fprintf('✓ savefig command successful\n');
catch ME
    fprintf('✗ savefig command failed: %s\n', ME.message);
end

% Test exportgraphics (if available)
if exist('exportgraphics', 'file')
    try
        exportgraphics(fig1, fullfile(test_folder, 'test_exportgraphics.png'), 'Resolution', 300);
        fprintf('✓ exportgraphics command successful\n');
    catch ME
        fprintf('✗ exportgraphics command failed: %s\n', ME.message);
    end
else
    fprintf('- exportgraphics not available in this MATLAB version\n');
end

% Check what files were created
fprintf('\n=== Checking saved files ===\n');

% Check main results folder
if exist(results_folder, 'dir')
    plots_dir = fullfile(results_folder, 'plots');
    if exist(plots_dir, 'dir')
        files = dir(fullfile(plots_dir, '*.*'));
        fprintf('Files in %s:\n', plots_dir);
        for i = 1:length(files)
            if ~files(i).isdir
                fprintf('  - %s (%.1f KB)\n', files(i).name, files(i).bytes/1024);
            end
        end
    end
end

% Check direct save test folder
if exist(test_folder, 'dir')
    files = dir(fullfile(test_folder, '*.*'));
    fprintf('\nFiles in %s:\n', test_folder);
    for i = 1:length(files)
        if ~files(i).isdir
            fprintf('  - %s (%.1f KB)\n', files(i).name, files(i).bytes/1024);
        end
    end
end

fprintf('\n✓ Plot saving test complete!\n');
fprintf('Check the results folders to verify files were saved correctly.\n');