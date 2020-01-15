clear

dataGridX = -500:20:500;
dataGridY = -500:20:500;
Ndata = length(dataGridX) * length(dataGridY);
[dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);

% for parfor
dataLoc_x = dataLocX(:);
dataLoc_y = dataLocY(:);

dataPath = 'D:/Yinchu Li/EMG_largeFiles/forloop_noProductionWell/directionalFluid/';
load([dataPath 'E_leftExp_WellB.mat'])
load([dataPath 'E_rightExp_WellB.mat'])
load([dataPath 'E_upExp_WellB.mat'])
load([dataPath 'E_downExp_WellB.mat'])

data = [E_obs_LeftExp'; E_obs_RightExp'; E_obs_UpExp'; E_obs_DownExp'];
reso = 20;
cutoff = [1e-11 1e-6];
for i = 1:5
figure;
[~, ~, ~, ZI] = imagexyc([dataLoc_x dataLoc_y data(i, 1:length(dataLoc_x))' data(i, length(dataLoc_y)+1:end)'], ...
                         reso,'',cutoff,'log');
end