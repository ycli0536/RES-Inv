
%% initial

savePath = 'D:/Yinchu Li/EMG/Code/Project_code_RES-Inv/Fwd/';

% no Fracturing conductivity (fracCon and fracLoc)
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
Ex = potentialDiffs / E.electrodeSpacing;
[potentialDiffs, ~, ~, ~] = getResNetDataRectMesh(nodeX,nodeY,nodeZ,potentials,[E.My E.Ny]);
Ey = potentialDiffs / E.electrodeSpacing;

E_obs = [Ex; Ey];

save([savePath 'E_initial_WellB.mat'], 'E_obs');

%% load E_initial

% targetPath = 'D:/Yinchu Li/EMG/Code/Project_code_RES-Inv/Fwd/';
targetPath = savePath;
dataFile = 'E_initial_WellB.mat';
E = load([targetPath dataFile]);
E_initial = E.E_obs;

Ex1 = E_initial(1:length(dataLoc_x));
Ey1 = E_initial(length(dataLoc_y)+1:end);

