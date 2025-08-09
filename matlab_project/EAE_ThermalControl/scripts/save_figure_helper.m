%% Helper function to save individual figures immediately
% This ensures figures are saved as they are created

function save_figure_helper(fig_handle, fig_name, results_folder)
    if nargin < 3
        % Use default results folder if not specified
        timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
        results_folder = fullfile('results', [timestamp '_analysis']);
    end
    
    % Ensure directories exist
    if ~exist(results_folder, 'dir')
        mkdir(results_folder);
    end
    plots_folder = fullfile(results_folder, 'plots');
    if ~exist(plots_folder, 'dir')
        mkdir(plots_folder);
    end
    
    % Clean filename
    fig_name = regexprep(fig_name, '[^a-zA-Z0-9_-]', '_');
    
    % Make figure current and visible
    figure(fig_handle);
    set(fig_handle, 'Visible', 'on');
    drawnow;  % Force rendering
    pause(0.2);  % Wait for rendering to complete
    
    % Save as .fig
    try
        fig_path = fullfile(plots_folder, [fig_name '.fig']);
        savefig(fig_handle, fig_path);
        fprintf('  Saved figure: %s.fig\n', fig_name);
    catch ME
        fprintf('  Warning: Could not save %s.fig: %s\n', fig_name, ME.message);
    end
    
    % Save as .png with multiple methods
    png_path = fullfile(plots_folder, [fig_name '.png']);
    saved = false;
    
    % Method 1: Try exportgraphics (MATLAB R2020a+)
    if exist('exportgraphics', 'file') && ~saved
        try
            exportgraphics(fig_handle, png_path, 'Resolution', 300);
            saved = true;
            fprintf('  Saved figure: %s.png (using exportgraphics)\n', fig_name);
        catch
            % Silent fail, try next method
        end
    end
    
    % Method 2: Try print with -dpng
    if ~saved
        try
            print(fig_handle, png_path, '-dpng', '-r300');
            saved = true;
            fprintf('  Saved figure: %s.png (using print)\n', fig_name);
        catch
            % Silent fail, try next method
        end
    end
    
    % Method 3: Try saveas
    if ~saved
        try
            saveas(fig_handle, png_path);
            saved = true;
            fprintf('  Saved figure: %s.png (using saveas)\n', fig_name);
        catch ME
            fprintf('  Error: Could not save %s.png: %s\n', fig_name, ME.message);
        end
    end
    
    % Also save as EPS for publication quality
    try
        eps_path = fullfile(plots_folder, [fig_name '.eps']);
        print(fig_handle, eps_path, '-depsc2', '-r300');
        fprintf('  Saved figure: %s.eps (vector format)\n', fig_name);
    catch
        % EPS saving is optional, silent fail
    end
end