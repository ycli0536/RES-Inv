clear

Config_file = 'ModelsDesign.ini';
PATH = config_parser(Config_file, 'PATH');
dataPath = PATH.savePath_PC;

dataGridX = -500:20:500;
dataGridY = -500:20:500;
Ndata = length(dataGridX) * length(dataGridY);
[dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);

% for parfor
dataLoc_x = dataLocX(:);
dataLoc_y = dataLocY(:);

load([dataPath 'diff_data.mat']);

reso = 20;
cutoff = [1e-12 1e-6];
% figure; histogram(log10(abs(data)))
for i = 1:size(data, 1)
    fig = figure;
    set(fig, 'Visible', 'off')
    [~, ~, ~, ZI] = imagexyc([dataLoc_x dataLoc_y data(i, 1:length(dataLoc_x))' data(i, length(dataLoc_y)+1:end)'], ...
                         reso,'',cutoff,'log');
    hold on;
    levellist = -10:0.5:-3;
    [ct, h] = contour(dataLocX, dataLocY, reshape(log10(sqrt(data(i, 1:length(dataLoc_x)).^2+ data(i, length(dataLoc_y)+1:end).^2)),51,51), 'LevelStep',0.5, 'linecolor','k');
    clabel(ct,h, levellist, 'FontSize',14,'Color','k')
    clim = caxis;
    c = colorbar('Ticks',linspace(clim(1),clim(2),7), 'TickLabels',{'-180','-120','-60','0','60','120','180'});
    c.Label.String = 'degree';
    c.Label.Rotation = 0;
    c.Label.FontSize = 10;
    c.Label.Units = 'normalized';
    c.Label.Position = [0.5 1.06 0]; % c.Label.Position
    colormap(hsv)
    saveas(gcf, [dataPath num2str(i) '.png'])
end


