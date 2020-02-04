clear

dataGridX = -500:20:500;
dataGridY = -500:20:500;
Ndata = length(dataGridX) * length(dataGridY);
[dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);

% for parfor
dataLoc_x = dataLocX(:);
dataLoc_y = dataLocY(:);

% dataPath = 'D:/Yinchu Li/EMG_largeFiles/forloop_noProductionWell/directionalFluid/';
% dataPath = 'D:/data/forloop_ProductionWell/directionalFluid/';
% dataPath = 'D:/data/forloop_ProductionWell/directionalFluid_2019GEM_XiAN/';
% load([dataPath 'E_leftExp_WellA.mat'])
% load([dataPath 'E_rightExp_WellA.mat'])
% load([dataPath 'E_upExp_WellA.mat'])
% load([dataPath 'E_downExp_WellA.mat'])

% dataPath = 'D:/data/forloop_noProductionWell/directionalFluid/';
dataPath = 'D:/data/forloop_noProductionWell/directionalFluid_500ohm_base/';
load([dataPath 'E_leftExp_WellB.mat'])
load([dataPath 'E_rightExp_WellB.mat'])
load([dataPath 'E_upExp_WellB.mat'])
load([dataPath 'E_downExp_WellB.mat'])

data = [E_obs_leftExp'; E_obs_rightExp'; E_obs_upExp'; E_obs_downExp'];
reso = 20;
cutoff = [1e-12 1e-6];
% figure; histogram(log10(abs(data)))
for i = 1:5
    figure;
    [~, ~, ~, ZI] = imagexyc([dataLoc_x dataLoc_y data(i, 1:length(dataLoc_x))' data(i, length(dataLoc_y)+1:end)'], ...
                         reso,'',cutoff,'log');
    hold on;
    levellist = -15:0.5:-3;
    [ct, h] = contour(dataLoc.X, dataLoc.Y, reshape(log10(sqrt(data(1:length(dataLoc_x)).^2+ data(length(dataLoc_y)+1:end).^2)),51,51), 'linecolor','k');
    clabel(ct,h, levellist, 'FontSize',15,'Color','k')
    clim = caxis;
    c = colorbar('Ticks',[linspace(clim(1),clim(2),7)], 'TickLabels',{'-180','-120','-60','0','60','120','180'});
    c.Label.String = 'degree';
    c.Label.Rotation = 0;
    c.Label.Position = [0.5 -1.25 0];
    colormap(hsv)
end