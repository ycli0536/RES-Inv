
%% initial
clear
% savePath = 'D:/Yinchu Li/EMG_largeFiles/forloop_noProductionWell/directionalFluid/';
% savePath = 'D:/data/forloop_noProductionWell/directionalFluid_500ohm_base/';
% savePath = 'D:/data/forloop_ProductionWell/directionalFluid_verticalComp/';
savePath = 'D:/data/forloop_ProductionWell/directionalFluid_2Wells/';

% to test Yang's experiments in GEM 2019 Xi'an
% savePath = 'D:/data/forloop_ProductionWell/directionalFluid/';
% savePath = 'D:/data/forloop_ProductionWell/directionalFluid_2019GEM_XiAN/'; % TOTAL SAME TEST
% savePath = '/share/home/liyinchu/DATA/fwd_forloop/directionalFluid/';

fracLoc_origin = [300 300 -50 50 -1850 -1950];
fracLoc_upExp = [300 300 -50 50 -1800 -1950];
fracLoc_downExp = [300 300 -50 50 -1850 -2000];
fracLoc_leftExp = [300 300 -100 50 -1850 -1950];
fracLoc_rightExp = [300 300 -50 100 -1850 -1950];
fracCon = 250;

[nodeX, nodeY, nodeZ, edgeCon, faceCon, cellCon, minSize] = RectMeshModelsDesign(fracLoc_rightExp, fracCon);
dx = minSize(1);
dy = minSize(2);
dz = 0 - minSize(3);

source = [0 0 0 1; % HSV? 
          10000 0 0 -1];
% % #### change source location ####
% source = [0 50 0 1; 
%           10000 0 0 -1];

dataGridX = -500:20:500;
dataGridY = -500:20:500;
dataGrid = [dataGridX; dataGridY];

[dataLoc, E] = ABMNsettings(dataGrid);

% for parfor
dataLoc_x = dataLoc.X(:);
dataLoc_y = dataLoc.Y(:);

% (1) get connectivity
[nodes, edges, lengths, faces, cells] = ...
    formRectMeshConnectivity_t(nodeX, nodeY, nodeZ);

% (2) get matrices
Edge2Edge = formEdge2EdgeMatrix_t(edges,lengths);
Face2Edge = formFace2EdgeMatrix_t(edges,lengths,faces);
Cell2Edge = formCell2EdgeMatrix_t(edges,lengths,faces,cells);

G = formPotentialDifferenceMatrix(edges);
s = formSourceNearestNodes(nodes,source);

% (3) total conductance
ce = Edge2Edge * edgeCon; % on edges
cf = Face2Edge * faceCon; % on faces
cc = Cell2Edge * cellCon; % on cells
c = ce + cf + cc; % cc times 3 is important

% (4) solve
[potentials, ~, ~, ~] = solveForward(G,c,s,lengths);

% get dc data in E-field
[potentialDiffs, ~, ~, ~] = getResNetDataRectMesh(nodeX,nodeY,nodeZ,potentials,[E.Mx E.Nx]);
Ex2 = potentialDiffs / E.electrodeSpacing;
[potentialDiffs, ~, ~, ~] = getResNetDataRectMesh(nodeX,nodeY,nodeZ,potentials,[E.My E.Ny]);
Ey2 = potentialDiffs / E.electrodeSpacing;

% E_obs = [Ex2; Ey2];
% save([savePath 'E_WellB_with_1stFrac.mat'], 'E_obs');
% save([savePath 'E_WellA_with_1stFrac.mat'], 'E_obs');
% save([savePath 'E_WellA_with_1stFrac_500ohmBase.mat'], 'E_obs');
% save([savePath 'E_2Wells_with_1stFrac.mat'], 'E_obs');

%% Import E_initial
Efield = load([savePath 'E_2Wells_with_1stFrac.mat']);
E_initial = Efield.E_obs;

Ex1 = E_initial(1:length(dataLoc_x));
Ey1 = E_initial(length(dataLoc_y)+1:end);

%% E field diff
Fx = Ex2 - Ex1;
Fy = Ey2 - Ey1;
F_obs = [Fx; Fy];

E_obs_rightExp = F_obs;

% save([savePath 'E_leftExp_WellB.mat'], 'E_obs_leftExp');
% save([savePath 'E_rightExp_WellB.mat'], 'E_obs_rightExp');
% save([savePath 'E_upExp_WellB.mat'], 'E_obs_upExp');
% save([savePath 'E_downExp_WellB.mat'], 'E_obs_downExp');

% save([savePath 'E_downExp_WellA_500ohmBase.mat'], 'E_obs_downExp');

% save([savePath 'E_leftExp_2Wells.mat'], 'E_obs_leftExp');
save([savePath 'E_rightExp_2Wells.mat'], 'E_obs_rightExp');
% save([savePath 'E_upExp_2Wells.mat'], 'E_obs_upExp');
% save([savePath 'E_downExp_2Wells.mat'], 'E_obs_downExp');