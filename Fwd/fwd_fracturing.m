
%% initial
% PC terminal
% switch parpool(32) and parfor
% savePath_HPC -> savePath_PC (including setup.m)
% dataPath_HPC -> dataPath_PC

clear
parpool(32);
Config_file = 'ModelsDesign_2d.ini';
PATH = config_parser(Config_file, 'PATH');
savePath = PATH.savePath_HPC;
dataPath = PATH.dataPath_HPC;
if exist(savePath, 'dir') == 0;     mkdir(savePath);     end
if exist(dataPath, 'dir') == 0;     mkdir(dataPath);     end

[nodeX, nodeY, nodeZ, ~, ~, ~, ~, source, dataLoc, ~, MaxCount] = setup(Config_file, 1, 'fracturing');
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
%% Import E_initial
[Ex1, Ey1] = E_field(Config_file, MaxCount, nodeX, nodeY, nodeZ, G, s, lengths, Edge2Edge, Face2Edge, Cell2Edge);
E_obs1 = [Ex1; Ey1];

%% Differential E-field calculation and saving
BatchNumber = 30;
BatchSize = 1000;
start_id = 1:BatchSize:1 + BatchNumber * BatchSize;
for k = 1:BatchNumber
    end_id = start_id(k) + BatchSize - 1;
    data = [];
    tic
    parfor i = start_id(k):end_id
        [Ex, Ey] = E_field(Config_file, i, nodeX, nodeY, nodeZ, G, s, lengths, Edge2Edge, Face2Edge, Cell2Edge);
        E_obs2 = [Ex; Ey];
        F_obs = E_obs2 - E_obs1;
        data = [data; F_obs'];
    end
    toc
    save([dataPath 'Fracturing#' num2str(k, '%02d') '.mat'], 'data');
end


function [Ex, Ey] = E_field(Config_file, count, nodeX, nodeY, nodeZ, G, s, lengths, Edge2Edge, Face2Edge, Cell2Edge)
    [~, ~, ~, edgeCon, faceCon, cellCon, ~, ~, ~, E, ~] = setup(Config_file, count, 'fracturing');
    
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
end

