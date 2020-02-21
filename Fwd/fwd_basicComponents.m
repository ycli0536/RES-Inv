
%% initial
clear

Config_file = 'ModelsDesign.ini';
PATH = config_parser(Config_file, 'PATH');
savePath = PATH.savePath_PC;
if exist(savePath, 'dir') == 0;     mkdir(savePath);     end

% savePath = 'D:/Yinchu Li/EMG_largeFiles/forloop_noProductionWell/directionalFluid/';
% savePath = 'D:/data/forloop_noProductionWell/directionalFluid_500ohm_base/';
% savePath = 'D:/data/forloop_ProductionWell/directionalFluid_verticalComp/';
% savePath = 'D:/data/forloop_ProductionWell/directionalFluid_2Wells/';

% to test Yang's experiments in GEM 2019 Xi'an
% savePath = 'D:/data/forloop_ProductionWell/directionalFluid/';
% savePath = 'D:/data/forloop_ProductionWell/directionalFluid_2019GEM_XiAN/'; % TOTAL SAME TEST
% savePath = '/share/home/liyinchu/DATA/fwd_forloop/directionalFluid/';

% ini in blk_Loc and blk_Con format
% fracLoc_origin = [300 300 -50 50 -1850 -1950];
% fracLoc_upExp = [300 300 -50 50 -1800 -1950];
% fracLoc_downExp = [300 300 -50 50 -1850 -2000];
% fracLoc_leftExp = [300 300 -100 50 -1850 -1950];
% fracLoc_rightExp = [300 300 -50 100 -1850 -1950];
% fracCon = 250;


[nodeX, nodeY, nodeZ, ~, ~, ~, ~, source, dataLoc, ~, MaxCount] = setup(Config_file, 1);

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

data = [];
for i=1:MaxCount
    [~, ~, ~, edgeCon, faceCon, cellCon, minSize, ~, ~, E, ~] = setup(Config_file, i);
    % (3) total conductance
    ce = Edge2Edge * edgeCon; % on edges
    cf = Face2Edge * faceCon; % on faces
    cc = Cell2Edge * cellCon; % on cells
    c = ce + cf + cc; % cc times 3 is important
    % (4) solve
    [potentials, ~, ~, ~] = solveForward(G,c,s,lengths);

    % get dc data in E-field
    [potentialDiffs, ~, ~, ~] = getResNetDataRectMesh(nodeX,nodeY,nodeZ,potentials,[E.Mx E.Nx]);
    Ex = potentialDiffs / E.electrodeSpacing;
    [potentialDiffs, ~, ~, ~] = getResNetDataRectMesh(nodeX,nodeY,nodeZ,potentials,[E.My E.Ny]);
    Ey = potentialDiffs / E.electrodeSpacing;

    if i == 1
        E_obs = [Ex; Ey];
    else
        F_obs = [Ex; Ey] - E_obs;
        data = [data; F_obs'];
    end
end

save([savePath 'diff_data.mat'], 'data');

% save([savePath 'E_leftExp_WellB.mat'], 'E_obs_leftExp');
% save([savePath 'E_rightExp_WellB.mat'], 'E_obs_rightExp');
% save([savePath 'E_upExp_WellB.mat'], 'E_obs_upExp');
% save([savePath 'E_downExp_WellB.mat'], 'E_obs_downExp');

% save([savePath 'E_downExp_WellA_500ohmBase.mat'], 'E_obs_downExp');

% save([savePath 'E_leftExp_2Wells.mat'], 'E_obs_leftExp');
% save([savePath 'E_rightExp_2Wells.mat'], 'E_obs_rightExp');
% save([savePath 'E_upExp_2Wells.mat'], 'E_obs_upExp');
% save([savePath 'E_downExp_2Wells.mat'], 'E_obs_downExp');