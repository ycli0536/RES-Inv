function Preprocessing_2Dinput(Config_file, host)
% Config_file: configuration file with savePath, labelPath, and blk type
% (casing or fracturing)
% host: PC or HPC nodes (flag: 'PC' or 'HPC')

PATH = config_parser(Config_file, 'PATH');

if strcmpi(host, 'PC')
    dataPath = PATH.dataPath_PC; % E-field data path
    labelPath = PATH.targetPath_PC; % amp_ang/images path
elseif strcmpi(host, 'HPC')
    dataPath = PATH.dataPath_HPC; % E-field data path
    labelPath = PATH.targetPath_HPC; % amp_ang/images path
end

if exist(labelPath, 'dir') == 0;     mkdir(labelPath);     end

dataGrouplist = dir([dataPath PATH.data_prefix '*.mat']);
data = [];
for i = 1:length(dataGrouplist)
    temp = load([dataPath dataGrouplist(i).name]);
    data = [data; temp.data];
end

% log amp and [-1, 1] ang
filename = [PATH.data_prefix '_logAmp_scaledAng.mat'];
log_scaled_2d(labelPath, filename, data)

end

function log_scaled_2d(savePath, filename, data)
    dataGridX = -500:20:500;
    dataGridY = -500:20:500;
    [dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);
    
    dataLoc_x = dataLocX(:);
    dataLoc_y = dataLocY(:);
    data_log_amp = zeros(size(data, 1), 51, 51);
    data_scaled_ang = zeros(size(data, 1), 51, 51);
    for i = 1:size(data, 1)
        Ex = data(i, 1:length(dataLoc_x));
        Ey = data(i, length(dataLoc_y)+1:end);
        amp = reshape(sqrt(Ex.^2+Ey.^2),51,51);
        amp_log = log10(amp);
        ang = atan2(Ex, Ey) / pi; % range from -1 to 1
        data_log_amp(i, :, :) = amp_log;
        data_scaled_ang(i, :, :) = reshape(ang, 51, 51);
    end
    save([savePath filename], 'data_log_amp', 'data_scaled_ang');
end