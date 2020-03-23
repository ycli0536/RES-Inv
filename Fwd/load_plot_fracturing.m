clear

Config_file = 'ModelsDesign_2d.ini';
PATH = config_parser(Config_file, 'PATH');

savePath = PATH.savePath_PC; % home dir
dataPath = PATH.dataPath_PC; % E-field data path
data_file = PATH.data_file; % directions and fracCon data

plotPath = PATH.targetPath_PC; % images path
if exist(plotPath, 'dir') == 0;     mkdir(plotPath);     end

load([savePath, data_file])

dataGrouplist = dir([dataPath 'Fracturing' '*.mat']);

labels = directions;
fracCons = fracCon * ones(length(C), 1);
data = [];
for i = 1:length(dataGrouplist)
    temp = load([dataPath dataGrouplist(i).name]);
    data = [data; temp.data];
end

reso = 20;
% figure; histogram(log10(abs(data)))
% cutoff = [1e-7 1e-2];
loopplot_raw_imagexyc(plotPath, data, cutoff, fracCons, labels)

function loopplot_raw_imagexyc(plotPath, data, cutoff, fracCons, labels)
    dataGridX = -500:20:500;
    dataGridY = -500:20:500;
    [dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);
    
    dataLoc_x = dataLocX(:);
    dataLoc_y = dataLocY(:);
    
    reso = 20;
    for i = 1:size(data, 1) % parfor
        [~, ~, ~, ZI] = imagexyc([dataLoc_x dataLoc_y data(i, 1:length(dataLoc_x))' data(i, length(dataLoc_y)+1:end)'], ...
                         reso,'',cutoff,'log');
        % test ZI
        imwrite(ZI, [plotPath, num2str(i,'%05d'), 'Ed_field_fracCon', num2str(fracCons(i)),...
                '_', char(labels(i)), '.png'])
    end
end