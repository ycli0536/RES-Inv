
%% initial

Config_file = 'ModelsDesign.ini';
savePath = config_parser(Config_file, 'PATH');
[nodeX, nodeY, nodeZ, edgeCon, faceCon, cellCon, ~, source, dataLoc, E] = setup(Config_file);
if exist(savePath, 'dir') == 0;     mkdir(savePath);     end

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

% save([savePath 'E_rightExp_2Wells.mat'], 'E_obs_rightExp');
