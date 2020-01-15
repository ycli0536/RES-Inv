
%% initial

savePath = 'D:/Yinchu Li/EMG_largeFiles/forloop_noProductionWell/directionalFluid/';

[nodeX, nodeY, nodeZ, edgeCon, faceCon, cellCon, minSize] = RectMeshModelsDesign();
dx = minSize(1);
dy = minSize(2);
dz = 0 - minSize(3);

[source, dataLoc, E] = ABMNsettings();

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

%% Import E_initial
Efield = load('E_initial_WellB.mat');
E_initial = Efield.E_obs;

Ex1 = E_initial(1:length(dataLoc_x));
Ey1 = E_initial(length(dataLoc_y)+1:end);

%% E field diff
Fx = Ex2 - Ex1;
Fy = Ey2 - Ey1;
F_obs = [Fx; Fy];

E_obs_DownExp = F_obs;

% save([savePath 'E_origin_WellB.mat'], 'E_obs_origin');
% save([savePath 'E_leftExp_WellB.mat'], 'E_obs_LeftExp');
% save([savePath 'E_rightExp_WellB.mat'], 'E_obs_RightExp');
% save([savePath 'E_upExp_WellB.mat'], 'E_obs_UpExp');
save([savePath 'E_downExp_WellB.mat'], 'E_obs_DownExp');