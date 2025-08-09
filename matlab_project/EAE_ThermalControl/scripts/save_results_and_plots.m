%% Save Results and Plots Function
% Saves all results to timestamped folders

function results_folder = save_results_and_plots(run_name)
    
    if nargin < 1
        run_name = 'analysis';
    end
    
    % Create timestamped folder
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    results_folder = fullfile('results', [timestamp '_' run_name]);
    
    % Create directories
    if ~exist('results', 'dir')
        mkdir('results');
    end
    mkdir(results_folder);
    mkdir(fullfile(results_folder, 'plots'));
    mkdir(fullfile(results_folder, 'data'));
    mkdir(fullfile(results_folder, 'logs'));
    
    fprintf('\nSaving results to: %s\n', results_folder);
    
    %% Save all open figures
    fig_handles = findall(0, 'Type', 'figure');
    
    % Sort figures by number for consistent ordering
    if ~isempty(fig_handles)
        fig_numbers = arrayfun(@(h) h.Number, fig_handles);
        [~, sort_idx] = sort(fig_numbers);
        fig_handles = fig_handles(sort_idx);
    end
    
    for i = 1:length(fig_handles)
        fig = fig_handles(i);
        
        % Make figure visible and bring to front
        set(fig, 'Visible', 'on');
        figure(fig);  % Bring to front
        drawnow;  % Force MATLAB to render the figure
        pause(0.1);  % Small pause to ensure rendering is complete
        
        fig_name = get(fig, 'Name');
        if isempty(fig_name)
            fig_name = sprintf('Figure_%d', fig.Number);
        end
        
        % Clean filename
        fig_name = regexprep(fig_name, '[^a-zA-Z0-9_-]', '_');
        
        % Save as both .fig and .png
        try
            savefig(fig, fullfile(results_folder, 'plots', [fig_name '.fig']));
            fprintf('  Saved .fig: %s\n', fig_name);
        catch ME
            fprintf('  Warning: Could not save .fig for %s: %s\n', fig_name, ME.message);
        end
        
        try
            % Use exportgraphics for better compatibility (MATLAB R2020a+)
            if exist('exportgraphics', 'file')
                exportgraphics(fig, fullfile(results_folder, 'plots', [fig_name '.png']), 'Resolution', 300);
            else
                % Fallback to print for older versions
                print(fig, fullfile(results_folder, 'plots', [fig_name '.png']), '-dpng', '-r300');
            end
            fprintf('  Saved .png: %s\n', fig_name);
        catch ME
            fprintf('  Warning: Could not save .png for %s: %s\n', fig_name, ME.message);
        end
    end
    
    if isempty(fig_handles)
        fprintf('  No figures found to save\n');
    end
    
    %% Save workspace variables
    workspace_file = fullfile(results_folder, 'data', 'workspace.mat');
    evalin('base', sprintf('save(''%s'')', workspace_file));
    fprintf('  Saved workspace to: workspace.mat\n');
    
    %% Save command window output
    % This is tricky in MATLAB - we'll create a diary file
    diary_file = fullfile(results_folder, 'logs', 'command_output.txt');
    diary(diary_file);
    diary off;
    fprintf('  Command output logged to: command_output.txt\n');
    
    %% Create summary report
    create_summary_report(results_folder);
    
    fprintf('\n✓ All results saved to: %s\n', results_folder);
end

function create_summary_report(results_folder)
    % Create HTML summary report
    report_file = fullfile(results_folder, 'summary.html');
    fid = fopen(report_file, 'w');
    
    fprintf(fid, '<html><head><title>Analysis Results Summary</title>\n');
    fprintf(fid, '<style>body {font-family: Arial;} img {max-width: 800px;} table {border-collapse: collapse;} td,th {border: 1px solid #ddd; padding: 8px;}</style>\n');
    fprintf(fid, '</head><body>\n');
    fprintf(fid, '<h1>EAE Thermal Control Analysis Results</h1>\n');
    fprintf(fid, '<p>Generated: %s</p>\n', datestr(now));
    
    % Add plots section
    fprintf(fid, '<h2>Generated Plots</h2>\n');
    plot_files = dir(fullfile(results_folder, 'plots', '*.png'));
    for i = 1:length(plot_files)
        fprintf(fid, '<h3>%s</h3>\n', plot_files(i).name);
        fprintf(fid, '<img src="plots/%s"><br>\n', plot_files(i).name);
    end
    
    % Add parameters section if available
    if evalin('base', 'exist(''params'', ''var'')')
        params = evalin('base', 'params');
        fprintf(fid, '<h2>System Parameters</h2>\n');
        fprintf(fid, '<table>\n');
        fprintf(fid, '<tr><th>Parameter</th><th>Value</th></tr>\n');
        fprintf(fid, '<tr><td>Temperature Setpoint</td><td>%.1f °C</td></tr>\n', params.control.temp_setpoint);
        fprintf(fid, '<tr><td>Sample Time</td><td>%.2f s</td></tr>\n', params.control.sample_time);
        fprintf(fid, '<tr><td>Simulation Duration</td><td>%.0f s</td></tr>\n', params.sim.duration);
        fprintf(fid, '</table>\n');
    end
    
    % Add PID results if available
    if evalin('base', 'exist(''optimized_pid'', ''var'')')
        pid_vals = evalin('base', 'optimized_pid');
        fprintf(fid, '<h2>Optimized PID Parameters</h2>\n');
        fprintf(fid, '<table>\n');
        fprintf(fid, '<tr><th>Parameter</th><th>Value</th></tr>\n');
        fprintf(fid, '<tr><td>Kp</td><td>%.4f</td></tr>\n', pid_vals.Kp);
        fprintf(fid, '<tr><td>Ki</td><td>%.4f</td></tr>\n', pid_vals.Ki);
        fprintf(fid, '<tr><td>Kd</td><td>%.4f</td></tr>\n', pid_vals.Kd);
        fprintf(fid, '</table>\n');
    end
    
    fprintf(fid, '</body></html>\n');
    fclose(fid);
end