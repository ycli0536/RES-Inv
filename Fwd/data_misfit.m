% HPC terminal
% switch parpool(32 or 40) and parfor
% savePath_PC -> savePath_HPC (including setup.m)
% testPath_PC -> testPath_HPC

clear

Config_file = 'ModelsDesign_2d.ini';
PATH = config_parser(Config_file, 'PATH');

savePath = PATH.savePath_PC; % home dir
testPath = PATH.testPath_PC; % test and pred dataset E-field data path

test_dataGrouplist = dir([testPath PATH.data_prefix '*.mat']);
test_data = [];
for i = 1:length(test_dataGrouplist)
    temp = load([testPath test_dataGrouplist(i).name]);
    test_data = [test_data; temp.data];
end

pred_dataGrouplist = dir([testPath PATH.data_prefix '*.mat']);
pred_data = [];
for i = 1:length(pred_dataGrouplist)
    temp = load([testPath pred_dataGrouplist(i).name]);
    pred_data = [pred_data; temp.data];
end

eps = 0.05;
misfit5 = zeros(size(test_data, 1), 1);
for i = 1: size(test_data, 1)
    dE0 = test_data(i, :);
    dEx = test_data(i, 1:size(test_data, 2)/2);
    dEy = test_data(i, size(test_data, 2)/2 + 1:end);
    E0_amp = repmat(sqrt(dEx.^2 + dEy.^2), 1, 2);
    
    dE1 = pred_data(i, :);
    ddE = dE1 - dE0;
    misfit5(i) = sum((ddE./(E0_amp.*eps)).^2);
end