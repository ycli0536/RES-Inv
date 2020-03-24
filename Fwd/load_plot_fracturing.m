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
fig = figure; histogram(log10(abs(data)))
set(fig, 'Visible', 'off')
saveas(fig, [savePath, 'histogram_data_total', num2str(size(data, 1)), '.png'])
cutoff = [1e-7 1e-2];

BatchNumber = 2;
BatchSize = 100;

loopplot_raw_imagexyc(plotPath, data, cutoff, fracCons, labels, BatchNumber, BatchSize)

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

