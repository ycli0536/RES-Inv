
%% initial
% Fracturing conductivity
fracCon_list = [150 175 200 225 250];
fracLoc = [300 300 -200 200 -1700 -2100];

[nodeX, nodeY, nodeZ, edgeCon, ~, cellCon, minSize] = RectMeshModelsDesign();
dx = minSize(1);
dy = minSize(2);
dz = 0 - minSize(3);

[source, dataLoc, E] = ABMNsettings();

dataLocX = dataLoc.X;
dataLocY = dataLoc.Y;
% for parfor
dataLoc_x = dataLocX(:);
dataLoc_y = dataLocY(:);

%%  Get fracturing sheet object's facets
N = 5; % Increase resolution N times
n = 4; % 
% which dimension (x/y/z) fracturing sheet loss
fracLoc_dims = [fracLoc(1) - fracLoc(2) == 0 
                fracLoc(3) - fracLoc(4) == 0
                fracLoc(5) - fracLoc(6) == 0]; 
objType = find(fracLoc_dims == 1); 
% 1 -> YOZ plane
% 2 -> XOZ plane
% 3 -> XOY plane

% well location on profile
well_locdim1 = 0;
well_locdim2 = -1900;
%---Define background grid (2n x 2n)
yc = (fracLoc(3) + fracLoc(4))/2;
zc = (fracLoc(5) + fracLoc(6))/2;
dz = 0 - dz; % local dz and dy here
center_dim1 = yc;
center_dim2 = zc;

% pseudo-random 8 control points detemining ploygon's shape
r = n/2 * dz; % basical radius with 3sigma principle

% savePath = '/home/liyinchu/Data/fwd_forloop/new_dataset20191021/';
savePath = 'D:/Yinchu Li/EMG_largeFiles/forloop_noProductionWell/dataset20191219/';
name_SheetCrossSection = 'SheetCrossSection';
name_ObsData = 'ObsData';
name_51X51_ObsData = '51X51_ObsData';

path_SheetCrossSection = [savePath name_SheetCrossSection '/'];
path_ObsData = [savePath name_ObsData '/'];
path_51X51_ObsData = [savePath name_51X51_ObsData '/'];

if exist(path_SheetCrossSection, 'dir') == 0; mkdir(path_SheetCrossSection); end
if exist(path_ObsData, 'dir') == 0;           mkdir(path_ObsData);           end
if exist(path_51X51_ObsData, 'dir') == 0;     mkdir(path_51X51_ObsData);     end

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
% cf = Face2Edge * faceCon; % on faces
cc = Cell2Edge * cellCon; % on cells

%% Import E_initial
E_initial = load('E_initial.txt');

Ex1 = E_initial(1:length(dataLoc_x));
Ey1 = E_initial(length(dataLoc_y)+1:end);

%% parfor producing data
BatchSize = 1000;
BatchNumber = 30;
start_id = 1:BatchSize:1 + BatchNumber * BatchSize;
% label = zeros(imax - imin + 1, 1);
% data = zeros(imax - imin + 1, length(E.Mx));
for k = 1:BatchNumber
end_id = start_id(k) + BatchSize - 1;
label = [];
data = [];
ShapeCollect = [];
fracCons = [];
fracCon = fracCon_list(randi(length(fracCon_list)));
tic
% for i = start_id(k):end_id
parfor i = start_id(k):end_id
% for i = imin:imax

[direction, SheetShape] = randomShape(r, center_dim1, center_dim2);
ShapeCollect = [ShapeCollect, SheetShape];
fracCons = [fracCons; fracCon];

%---Determination based on relationship between polygon and centre of each face
xfaceCenter = (yc-dy*n+dy/2 : dy : yc+dy*n-dy/2);
yfaceCenter = (zc-dz*n+dz/2 : dz : zc+dz*n-dz/2);
[xq, yq] = meshgrid(xfaceCenter, yfaceCenter);
XfaceCenter = xq(:);
YfaceCenter = yq(:);

% pseudocolor plot (high resolution)
xgrid = (yc-dy*n+dy/(2*N) : dy/N : yc+dy*n-dy/(2*N));
ygrid = (zc-dz*n+dz/(2*N) : dz/N : zc+dz*n-dz/(2*N));
[xq, yq] = meshgrid(xgrid, ygrid);
Xq = xq(:);
Yq = yq(:);
[in, ~] = inpolygon(Xq, Yq, SheetShape(:, 1), SheetShape(:, 2));
P = reshape(in, size(xq));

%---Calculate coefficients match coordination of faceCenters
% coefficients determining faceCon values
dim1Dist = N*ones(1, 2*n);
dim2Dist = N*ones(1, 2*n);
coe_cell = mat2cell(P, dim1Dist, dim2Dist);
coe = cellfun(@(lambda) mean(mean(lambda)), coe_cell);
sheetsCenter_coe = [XfaceCenter YfaceCenter coe(:)]; % sheetsCenters and coefficients matrix


faceCon = addfracCon(nodeX, nodeY, nodeZ, fracLoc, fracCon, sheetsCenter_coe);

%% Carry out ResNet DC modeling
% % (1) get connectivity
% [nodes, edges, lengths, faces, cells] = ...
%     formRectMeshConnectivity_t(nodeX, nodeY, nodeZ);
% 
% % (2) get matrices
% Edge2Edge = formEdge2EdgeMatrix_t(edges,lengths);
% Face2Edge = formFace2EdgeMatrix_t(edges,lengths,faces);
% Cell2Edge = formCell2EdgeMatrix_t(edges,lengths,faces,cells);

% G = formPotentialDifferenceMatrix(edges);
% s = formSourceNearestNodes(nodes,source);

% (3) total conductance
% ce = Edge2Edge * edgeCon; % on edges
cf = Face2Edge * faceCon; % on faces
% cc = Cell2Edge * cellCon; % on cells
c = ce + cf + cc; % cc times 3 is important

% (4) solve
[potentials, ~, ~, ~] = solveForward(G,c,s,lengths);

% get dc data in E-field
[potentialDiffs, ~, ~, ~] = getResNetDataRectMesh(nodeX,nodeY,nodeZ,potentials,[E.Mx E.Nx]);
Ex2 = potentialDiffs / E.electrodeSpacing;
[potentialDiffs, ~, ~, ~] = getResNetDataRectMesh(nodeX,nodeY,nodeZ,potentials,[E.My E.Ny]);
Ey2 = potentialDiffs / E.electrodeSpacing;

%% E field diff
Fx = Ex2 - Ex1;
Fy = Ey2 - Ey1;
F_obs = [Fx; Fy];

% dE_total = repmat(sqrt(Fx.^2 + Fy.^2), 2, 1);
% eps = 0.05;
% F_obs = F_obs + dE_total*eps.*randn(length(F_obs), 1); % 5% Gauss noise

% E0 = repmat(sqrt(F0(1:length(Fx)).^2 + F0(length(Fy)+1:end).^2), 2, 1);
% eps1 = 0.05;
% % eps2 = 0.1;
% 
% Fd = F1-F0;
% misfit5 = sum((Fd./(E0.*eps1)).^2);

data = [data; F_obs'];
label = [label; direction];
% data(i - imin + 1, :) = F_obs';
% label(i - imin + 1) = direction;
% if mod(i,5000)==0
%     save(['train#' num2str(i) '.mat'], 'data', 'label');
% end
end
toc

save([savePath 'Sheet#' num2str(fracCon) '_fracCon' num2str(k, '%02d') '.mat'], 'ShapeCollect', 'fracCons');
save([savePath 'train#' num2str(fracCon) '_fracCon' num2str(k, '%02d') '.mat'], 'data', 'label');

end

% %% save data/figures
% for i = 1:end_id
%     
% x = ShapeCollect(2 * i - 1, 1);
% y = ShapeCollect(2 * i - 1, 2);
% 
% shape = figure('Visible', 'off');
% plot([x; x(1)], [y; y(1)]);
% hold on
% axis([yc-dy*n yc+dy*n zc-dz*n zc+dz*n])
% xticks(yc-dy*n : dy : yc+dy*n)
% yticks(zc-dz*n : dz : zc+dz*n)
% box on
% axis square
% grid on
% set(gca, 'GridAlpha', 1, 'GridColor', [0.9 0.6 0.5])
% line (well_locdim1, well_locdim2, 'Marker', 'x', 'MarkerSize', 12, 'MarkerEdgeColor', 'k');
% line (well_locdim1, well_locdim2, 'Marker', 'o', 'MarkerSize', 12, 'MarkerEdgeColor', 'k');
% title('Cross-section view')
% saveas(shape, [path_SheetCrossSection, num2str(i,'%05d'), ...
%     '_', char(label(i)), '_', name_SheetCrossSection, '.jpg'])
% 
% reso = 20;
% cutoff = [1e-10 1e-6];
% 
% obs = figure('Visible', 'off');
% [~, ~, ~, ZI] = imagexyc([dataLoc_x dataLoc_y data(i, 1:length(dataLoc_x)) data(i, length(dataLoc_y)+1:end)], reso,'',cutoff,'log');
% hold on;
% % levellist = -15:0.5:-3;
% % contour(dataLocX, dataLocY, reshape(log10(sqrt(Fx.^2+ Fy.^2)),51,51),...
% %         'showtext','on','levellist',levellist,'linecolor','k');
% % xlabel('X(m)')
% % ylabel('Y(m)')
% % title('fwd result')
% set(gca,'position',[0 0 1 1])
% axis normal
% axis off 
% saveas(obs, [path_ObsData, num2str(i,'%05d'), ...
%     '_', char(label(i)), '_' name_ObsData, '.jpg'])
% imwrite(ZI, [path_51X51_ObsData, num2str(i,'%05d'), ...
%     '_', char(label(i)), '_' name_51X51_ObsData, '.jpg'])
% end
% %% label data
% status_U = movefile([path_51X51_ObsData '*_U_*.jpg'], [path_51X51_ObsData 'U\']);
% status_UR = movefile([path_51X51_ObsData '*_UR_*.jpg'], [path_51X51_ObsData 'UR\']);
% status_R = movefile([path_51X51_ObsData '*_R_*.jpg'], [path_51X51_ObsData 'R\']);
% status_DR = movefile([path_51X51_ObsData '*_DR_*.jpg'], [path_51X51_ObsData 'DR\']);
% status_D = movefile([path_51X51_ObsData '*_D_*.jpg'], [path_51X51_ObsData 'D\']);
% status_DL = movefile([path_51X51_ObsData '*_DL_*.jpg'], [path_51X51_ObsData 'DL\']);
% status_L = movefile([path_51X51_ObsData '*_L_*.jpg'], [path_51X51_ObsData 'L\']);
% status_UL = movefile([path_51X51_ObsData '*_UL_*.jpg'], [path_51X51_ObsData 'UL\']);
% status_None = movefile([path_51X51_ObsData '*_None_*.jpg'], [path_51X51_ObsData 'None\']);
% 
