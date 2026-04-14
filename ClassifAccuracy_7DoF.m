%% GETTING ACCURACY AT BIN LEVEL AND TRIAL LEVEL FROM 3D ARROW TASK
clc;clear

clc
clear all
close all

clc; close all; clear all


root_path='G:\Ganguly lab\data\B6\';
foldernames = {'20260310'};
files=[];

for i=1:length(foldernames)
    disp([i/length(foldernames)]);
    folderpath = fullfile(root_path, foldernames{i},'GangulyServer',foldernames{i},'Robot3DArrow');
    D=dir(folderpath);

    task_files_temp=[];
    for j=3:length(D)
        filepath=fullfile(folderpath,D(j).name,'BCI_Fixed'); % Imagined, BCI_Fixed
        if exist(filepath)
            task_files_temp = [task_files_temp;findfiles('mat',filepath)'];
        end
    end
    if ~isempty(task_files_temp)
        files = [files;task_files_temp];
    end
end



acc=zeros(7); % trial level decoding accuracy
acc1=zeros(7); % bin level decoding accuracy 
for i=1:length(files)
    file_loaded=1;
    try
        load(files{i});
    catch
        file_loaded=0;
    end

    if file_loaded
        out = TrialData.ClickerState;
        out1 = TrialData.FilteredClickerState;
        tid = TrialData.TargetID;
        if tid>7
            continue
        end
        decodes=[];
        for ii=1:7
            decodes(ii) = sum(out==ii);
        end
        [aa bb]=max(decodes);
        acc(tid,bb) = acc(tid,bb)+1; % trial level
        for j=1:length(out)
            if out(j)>0
                acc1(tid,out(j)) = acc1(tid,out(j))+1; % bin level
            end
        end
    end
end

for i=1:7
    acc(i,:) = acc(i,:)/sum(acc(i,:));
    acc1(i,:) = acc1(i,:)/sum(acc1(i,:));
end

% bin level
clc
figure;
imagesc(acc1)
xlabel('Predicted Label');
ylabel('True Label');
colorbar
colormap bone
caxis([0 1])
title(['Bin level decoding acc. ' num2str(100*mean(diag(acc1)))])
% title(['20251103 - Bin level PNP decoding acc. ' num2str(100*mean(diag(acc1)))])
disp('Bin level decoding accuracy')
disp(acc1)

% trial level
clc
figure;
imagesc(acc)
xlabel('Predicted Label');
ylabel('True Label');
colorbar
colormap bone
caxis([0 1])
title(['Trial level decoding acc. ' num2str(100*mean(diag(acc)))])
disp('Trial level decoding accuracy')
disp(acc1)



