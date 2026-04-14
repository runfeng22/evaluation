%% LOBO single day and plot avg confusion matrix
clear all;
clc;
warning('off', 'all');
% Root path and folder names
root_path = 'G:\Ganguly lab\data\B6\';
addpath('E:\UCB-UCSF Career\Ganguly Lab\project\decoding\B1_new_grid_pnp\mlp');

% foldernames = {'20250708'};
foldernames = {'20260310'};
% foldernames = {'20241218'};
cd(root_path)

day=1;

% Set the current folder path for the given day
folderpath = fullfile(root_path, foldernames{day}, 'GangulyServer', foldernames{day}, 'Robot3DArrow'); %RealRobotBatch,Robot3DArrow,RealRobotBatch_null
D = dir(folderpath);

% Pre-load and store all blocks for the current day
block_data = cell(1, length(D) - 2); % Initialize block_data as a cell array
for j = 3:length(D)
    filepath = fullfile(folderpath, D(j).name, 'BCI_Fixed');
    if ~exist(filepath, 'dir')
        filepath = fullfile(folderpath, D(j).name, 'Imagined');
    end
    if exist(filepath, 'dir')
        block_task_files = findfiles('mat', filepath)';
        if ~isempty(block_task_files)
            % Load and process data for the current block
            block_condn_data = load_data_for_MLP_TrialLevel_B3(block_task_files);

            % Prune to only the first 7 actions and store as struct
            block_struct = struct('neural', {}, 'targetID', {}, 'trial_type', {}); % Initialize struct array
            kk = 1;
            for ii = 1:length(block_condn_data)
                if ~isempty(block_condn_data(ii).neural) && block_condn_data(ii).targetID <= 7
                    block_struct(kk).neural = block_condn_data(ii).neural;
                    block_struct(kk).targetID = block_condn_data(ii).targetID;
                    block_struct(kk).trial_type = block_condn_data(ii).trial_type;
                    kk = kk + 1;
                end
            end
            block_data{j - 2} = block_struct; % Store the struct array for the block
        end
    end
end

%% Leave-One-Block-Out Loop
num_blocks = length(block_data);
block_acc = zeros(num_blocks, 1); % Store accuracy for each leave-one-block-out iteration
% Initialize storage for all predicted and actual labels
all_predicted = [];
all_actual = [];

for test_block = 1:num_blocks-1 % Loop through each block as the test set
    % Split data into training and test sets
    is_test_block = false(1, num_blocks);
    is_test_block(test_block) = true;
    test_data_overall = block_data{test_block}; % Test block data
    train_data_overall = [block_data{~is_test_block}];

    if isempty(test_data_overall)
        warning('No test files found for block %d, skipping iteration.', test_block);
        block_acc(test_block) = NaN; % Mark as NaN to indicate missing data
        continue;
    end

    if isempty(train_data_overall)
        warning('No train files found for block %d, skipping iteration.', test_block);
        block_acc(test_block) = NaN; % Mark as NaN to indicate missing data
        continue;
    end

    % Network training
    net = patternnet(120);
    net.divideParam.trainRatio = 0.70;
    net.divideParam.valRatio = 0.15;
    net.divideParam.testRatio = 0.15;
    net.performParam.regularization = 0.2;
    net.trainParam.showWindow = false;

    % Prepare training data
    [N, T, ~] = get_training_samples_mlp(train_data_overall, 1:length(train_data_overall));
    net = train(net, N, T', 'UseGPU', 'yes');

    % Test the network with the test data
    [N1, T1, ~] = get_training_samples_mlp(test_data_overall, 1:length(test_data_overall));
    test_outputs = net(N1);
    [~, predicted] = max(test_outputs, [], 1);
    [~, actual] = max(T1', [], 1);

    % Store predictions and ground truth
    all_predicted = [all_predicted, predicted];
    all_actual = [all_actual, actual];

    % Calculate accuracy for the current test block
    acc = sum(predicted == actual) / length(actual);
    block_acc(test_block) = acc;
end

% Calculate average accuracy across all blocks
avg_acc = nanmean(block_acc); % Ignore NaN values for skipped blocks
fprintf('Average Accuracy: %.2f%%\n', avg_acc * 100);

% Calculate confusion matrix
conf_matrix = confusionmat(all_actual, all_predicted);

% Normalize confusion matrix to percentages
conf_matrix_normalized = conf_matrix ./ sum(conf_matrix, 2) * 100;

% Plot normalized confusion matrix
figure;
imagesc(conf_matrix_normalized); % Use imagesc to visualize the matrix
colormap('bone'); % Use a colormap for better visualization
colorbar; % Add a colorbar to indicate percentages
caxis([0 100]); % Set color axis range to 0-100 for percentages

% Add title and labels
title(sprintf('Confusion Matrix in Day 20250515 - Avg Acc: %.2f%%', avg_acc * 100));
xlabel('Predicted Label');
ylabel('Actual Label');

% Add text annotations for percentages
[num_classes, ~] = size(conf_matrix_normalized);
for i = 1:num_classes
    for j = 1:num_classes
        percentage = conf_matrix_normalized(i, j);
        if percentage > 0
            text(j, i, sprintf('%.1f%%', percentage), 'HorizontalAlignment', 'center', 'Color', 'black');
        end
    end
end

% Adjust axes
xticks(1:num_classes);
yticks(1:num_classes);
axis square;
