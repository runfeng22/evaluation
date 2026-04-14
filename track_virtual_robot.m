%% track virtual robot trajectory

clc; close all; clear all
warning('off', 'all');

root_path='G:\Ganguly lab\data\B1\';

foldernames={'20241127'};

cd(root_path)
for day=1:length(foldernames)
task_files={}; python_files = [];ph_all = []; phi_all = []; r1_all =[]; vel_all = [];

k=1;
    disp([day/length(foldernames)]);
    folderpath = fullfile(root_path, foldernames{day},'GangulyServer',foldernames{day},'Robot3D');
    D=dir(folderpath);

    task_files_temp=[];
    for j=3:length(D)
        filepath=fullfile(folderpath,D(j).name,'BCI_Fixed');
        if exist(filepath)
            task_files_temp = [task_files_temp;findfiles('mat',filepath)'];
        end
    end
    if ~isempty(task_files_temp)
        task_files = [task_files;task_files_temp];k=k+1;
    end
end
all_files = task_files;

%% if only take specific blocks
all_files = task_files;
% task_files = all_files(contains(all_files, '111649') | contains(all_files, '111109'));
task_files = all_files(contains(all_files, '111649'));

%% plot confusion matrix
files_not_loaded = [];
colors = lines(10); % Predefine 10 distinct colors for trajectories

% Define axis limits for all subplots
x_limits = [-300, 300]; % X-axis limits
y_limits = [-300, 300]; % Y-axis limits
z_limits = [-300, 300]; % Z-axis limits

% Initialize color tracking for each target (6 targets assumed)
color_indices = ones(1, 6); % Start all color indices at 1

% Create figure
figure(1);
clf;

% Loop through all task files
for i = 1:length(task_files)
    try
        % Load the task file
        load(task_files{i});
        file_loaded = true;
    catch
        % If file loading fails, log it and continue
        file_loaded = false;
        disp(['Could not load ' task_files{i}]);
        files_not_loaded = [files_not_loaded; task_files(i)];
        continue;
    end
    
    % Get the TargetID for the current trial
    target_id = TrialData.TargetID;
    if target_id>6
        continue
    end

    % Create a subplot for the corresponding target
    subplot(1, 6, target_id); % Assuming 6 targets in total
    hold on;
    axis equal;
    grid on;
    view(3); % 3D view
    
    % Extract trajectory data for the current trial
    P = TrialData.CursorState';
    X = P(:, 1); % X position
    Y = P(:, 2); % Y position
    Z = P(:, 3); % Z position
    VX = P(:, 4); % X velocity
    VY = P(:, 5); % Y velocity
    VZ = P(:, 6); % Z velocity
    goals = TrialData.TargetPosition; % Goal positions
    
    % Determine the color for the current trajectory in this subplot
    current_color_index = color_indices(target_id); % Get current color index
    current_color = colors(current_color_index, :);
    color_indices(target_id) = mod(current_color_index, size(colors, 1)) + 1; % Update color index for next trajectory
    
    % Plot start position (fixed green color)
    plot3(X(1), Y(1), Z(1), 'o', 'Color', [0, 1, 0], 'MarkerFaceColor', [0, 1, 0], 'MarkerSize', 8); 
    
    % Plot trajectory (variable color)
    plot3(X, Y, Z, 'Color', current_color, 'LineWidth', 2);
    
    % Plot goal positions (fixed red color)
    plot3(goals(:, 1), goals(:, 2), goals(:, 3), 'o', 'MarkerFaceColor', [1, 0, 0], 'MarkerSize', 12); % Fixed color for goals
    
    % Set axis limits for the subplot
    xlim(x_limits);
    ylim(y_limits);
    zlim(z_limits);
    
    % Set labels and title for the subplot
    xlabel('X Position');
    ylabel('Y Position');
    zlabel('Z Position');
    title(['Target ' num2str(target_id)]);
end

% Add an overall title for the figure
sgtitle('Trajectories for Each Target');

% Add a global legend for start and goal points
legend_ax = axes('Position', [0, 0, 1, 1], 'Visible', 'off'); % Invisible axes for the legend
hold(legend_ax, 'on');
% Dummy plot for start point
plot(legend_ax, NaN, NaN, 'o', 'Color', [0, 1, 0], 'MarkerFaceColor', [0, 1, 0], 'MarkerSize', 8);
% Dummy plot for goal point
plot(legend_ax, NaN, NaN, 'o', 'Color', [1, 0, 0], 'MarkerFaceColor', [1, 0, 0], 'MarkerSize', 12);
legend(legend_ax, {'Start Position', 'Goal Position'}, 'Location', 'BestOutside');

% % Add a global legend
% legend_fig = axes('Position', [0, 0, 1, 1], 'Visible', 'off'); % Invisible axes for the legend
% hold(legend_fig, 'on');
% for i = 1:length(legend_items)
%     plot(legend_fig, NaN, NaN, 'Color', legend_colors(i, :), 'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', legend_colors(i, :)); % Dummy plots for legend
% end
% legend(legend_fig, legend_items, 'Location', 'BestOutside');
% 
