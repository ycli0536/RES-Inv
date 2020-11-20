function fwd(Cores_num, id_range, Config_file, flag)
% Cores_num: The number of cores used on each node
% id_range: [start_id, end_id]; sample id from start_id to end_id
% Config_file: Configuration file
% flag: 'fracturing' or 'casing'
% 
%% initial
parpool(Cores_num);
start_id = id_range(1);
end_id = id_range(2);

PATH = config_parser(Config_file, 'PATH');
savePath = PATH.savePath_HPC;
dataPath = PATH.dataPath_HPC;
if exist(savePath, 'dir') == 0;     mkdir(savePath);     end
if exist(dataPath, 'dir') == 0;     mkdir(dataPath);     end

other = config_parser(Config_file, 'data_processing');
Noise_level = other.noise_level; % add Gauss noise (0%, 5%, 10%, 15%, 20%)

[nodeX, nodeY, nodeZ, ~, ~, ~, ~, source, dataLoc, ~, ~] = setup(Config_file, 1, flag);
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
[Ex1, Ey1] = E_field(Config_file, 1, nodeX, nodeY, nodeZ, G, s, lengths, Edge2Edge, Face2Edge, Cell2Edge);

%% Differential E-field calculation and saving
tic
data = [];
parfor i = start_id:end_id
    [Ex2, Ey2] = E_field(Config_file, i+1, nodeX, nodeY, nodeZ, G, s, lengths, Edge2Edge, Face2Edge, Cell2Edge)
    Fx = Ex2 - Ex1;
    Fy = Ey2 - Ey1;
    F_obs = [Fx; Fy];
    %         dE_total = repmat(sqrt(Fx.^2 + Fy.^2), 2, 1);
    %         F_obs = F_obs + dE_total*Noise_level.*randn(length(F_obs), 1);
    F_obs = F_obs + F_obs * Noise_level .* randn(length(F_obs), 1);
    data = [data; F_obs'];
end
toc
if Noise_level ~= 0
    save([dataPath 'Noise' num2str(Noise_level) '_' PATH.data_prefix '#' num2str(k, '%02d') '.mat'], 'data');
else
    save([dataPath PATH.data_prefix '#' num2str(k, '%02d') '.mat'], 'data');
end
end

function [Ex, Ey] = E_field(Config_file, count, nodeX, nodeY, nodeZ, G, s, lengths, Edge2Edge, Face2Edge, Cell2Edge)
    [~, ~, ~, edgeCon, faceCon, cellCon, ~, ~, ~, E, ~] = setup(Config_file, count, flag);
    
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