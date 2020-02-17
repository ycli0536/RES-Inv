
%% initial
clear
parpool(32);
Config_file = 'ModelsDesign.ini';
PATH = config_parser(Config_file, 'PATH');
% savePath = PATH.savePath_HPC;
savePath = '/share/home/liyinchu/DATA/fwd_casing/'
if exist(savePath, 'dir') == 0;     mkdir(savePath);     end

[nodeX, nodeY, nodeZ, ~, ~, ~, ~, source, dataLoc, E] = setup(Config_file, 1);
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

BatchSize = 1000;
BatchNumber = 29;
start_id = 1:BatchSize:1 + BatchNumber * BatchSize;

for k = 1:BatchNumber
end_id = start_id(k) + BatchSize - 1;
data = [];
tic
    parfor i = start_id(k):end_id
        [~, ~, ~, edgeCon, faceCon, cellCon, minSize, ~, dataLoc, E] = setup(Config_file, i);

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
        data = [data; E_obs'];
    end
    toc
    save([savePath 'Casing#' num2str(k, '%02d') '_casingCon' '.mat'], 'data');
end
