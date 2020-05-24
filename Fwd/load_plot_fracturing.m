% HPC terminal
% switch parpool(32 or 40) and parfor
% savePath_PC -> savePath_HPC (including setup.m)
% dataPath_PC -> dataPath_HPC
% targetPath_PC -> targetPath_HPC
% BatchNumber and BatchSize

clear

Config_file = 'ModelsDesign_2d.ini';
PATH = config_parser(Config_file, 'PATH');

if strcmpi(Config_file,'ModelsDesign_2d.ini')
    savePath = PATH.savePath_PC; % home dir
    dataPath = PATH.dataPath_PC; % E-field data path
    data_file = PATH.data_file; % directions and fracCon data
    
    targetPath = PATH.targetPath_PC; % amp_ang/images path
    if exist(targetPath, 'dir') == 0;     mkdir(targetPath);     end
    
    % inputs for function imagexyc
    shape_data = load([savePath, data_file]);
    labels = shape_data.directions;
    fracCons = shape_data.fracCon * ones(length(shape_data.C), 1);
    
    dataGrouplist = dir([dataPath PATH.data_prefix '*.mat']);
    
    data = [];
    for i = 1:length(dataGrouplist)
        temp = load([dataPath dataGrouplist(i).name]);
        data = [data; temp.data];
    end
elseif strcmpi(Config_file,'ModelsDesign_2d_test.ini')
    savePath = PATH.savePath_PC; % home dir
    testPath = PATH.testPath_PC; % test and pred dataset E-field data path
    
    test_dataGrouplist = dir([testPath PATH.data_prefix '*.mat']);
    test_data = [];
    for i = 1:length(test_dataGrouplist)
        temp = load([testPath test_dataGrouplist(i).name]);
        test_data = [test_data; temp.data];
    end
    data = test_data;
elseif strcmpi(Config_file,'ModelsDesign_2d_pred.ini')
    savePath = PATH.savePath_PC; % home dir
    testPath = PATH.testPath_PC; % test and pred dataset E-field data path
    
    pred_dataGrouplist = dir([testPath PATH.data_prefix '*.mat']);
    pred_data = [];
    for i = 1:length(pred_dataGrouplist)
        temp = load([testPath pred_dataGrouplist(i).name]);
        pred_data = [pred_data; temp.data];
    end
    data = pred_data;
end

% figure; histogram(log10(abs(data)))
reso = 20;
fig = figure; histogram(log10(abs(data)))
set(fig, 'Visible', 'off')
saveas(fig, [targetPath, 'histogram_data_total', num2str(size(data, 1)), '.png'])
cutoff = [1e-12 1e-5];

% log amp and [-1, 1] ang
filename_orig = 'orig_fracCon_logAmp_Ang.mat';
data2D_orig(targetPath, filename_orig, data)

% preprocessed: normalized [0, 1] log amp and [0, 1] ang
filename_prep = 'fracCon_normalized_Amp_Ang.mat';
data2D(targetPath, filename_prep, data, log10(cutoff))

% BatchNumber = 2;
% BatchSize = 100;
% loopplot_raw_imagexyc(plotPath, data, cutoff, fracCons, labels, BatchNumber, BatchSize)

function loopplot_raw_imagexyc(plotPath, data, cutoff, fracCons, labels, BatchNumber, BatchSize)

start_id = 1:BatchSize:1 + BatchNumber * BatchSize;

dataGridX = -500:20:500;
dataGridY = -500:20:500;
[dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);

dataLoc_x = dataLocX(:);
dataLoc_y = dataLocY(:);

reso = 20;

for k = 1:BatchNumber
    end_id = start_id(k) + BatchSize - 1;
    for i = start_id(k):end_id % parfor
        [~, ~, ~, ZI] = imagexyc([dataLoc_x dataLoc_y data(i, 1:length(dataLoc_x))' data(i, length(dataLoc_y)+1:end)'], ...
                                 reso,'',cutoff,'log');
        % imwrite
        imwrite(ZI, [plotPath, num2str(i,'%05d'), 'Ed_field_fracCon', num2str(fracCons(i)),...
                '_', char(labels(i)), '.png'])
    end
    disp(end_id)
end
end


function data2D_orig(savePath, filename, data)
    dataGridX = -500:20:500;
    dataGridY = -500:20:500;
    [dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);
    
    dataLoc_x = dataLocX(:);
    dataLoc_y = dataLocY(:);
    data_log_amp_orig = zeros(size(data, 1), 51, 51);
    data_log_ang_orig = zeros(size(data, 1), 51, 51);
    for i = 1:size(data, 1)
        Ex = data(i, 1:length(dataLoc_x));
        Ey = data(i, length(dataLoc_y)+1:end);
        amp = reshape(sqrt(Ex.^2+Ey.^2),51,51);
        amp_log = log10(amp);
        ang = atan2(Ex, -Ey) / pi; % range from -1 to 1
        data_log_amp_orig(i, :, :) = amp_log;
        data_log_ang_orig(i, :, :) = reshape(ang, 51, 51);
    end
    save([savePath filename], 'data_log_amp_orig', 'data_log_ang_orig');
end

function data2D(savePath, filename, data, cutoff)
    dataGridX = -500:20:500;
    dataGridY = -500:20:500;
    [dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);
    
    dataLoc_x = dataLocX(:);
    dataLoc_y = dataLocY(:);
    data_log_amp = zeros(size(data, 1), 51, 51);
    data_log_ang = zeros(size(data, 1), 51, 51);
    for i = 1:size(data, 1)
        Ex = data(i, 1:length(dataLoc_x));
        Ey = data(i, length(dataLoc_y)+1:end);
        amp = reshape(sqrt(Ex.^2+Ey.^2),51,51);
        amp_log = log10(amp);
        amp_log(amp_log <= cutoff(1)) = cutoff(1);
        ampmin = min(min(amp_log));
        ampmax = max(max(amp_log));
        amp_log = interp1([ampmin ampmax],[0 1],amp_log);
        ang = atan2(Ex, -Ey) / pi; % range from -1 to 1
        ang = interp1([-1 1],[0 1],ang);
        data_log_amp(i, :, :) = amp_log;
        data_log_ang(i, :, :) = reshape(ang, 51, 51);
    end
    save([savePath filename], 'data_log_amp', 'data_log_ang');
end


