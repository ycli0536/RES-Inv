%% initial
% Fracturing conductivity
fracCon = 225;
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


% for i = 1:10  
   direction = randomShape(r, center_dim1, center_dim2);
% end

x = SheetShape(:, 1);
y = SheetShape(:, 2);
plot([x; x(1)], [y; y(1)]);
hold on
axis([yc-dy*n yc+dy*n zc-dz*n zc+dz*n])
xticks(yc-dy*n : dy : yc+dy*n)
yticks(zc-dz*n : dz : zc+dz*n)
box on
axis square
grid on
set(gca, 'GridAlpha', 1, 'GridColor', [0.9 0.6 0.5])
line (well_locdim1, well_locdim2, 'Marker', 'x', 'MarkerSize', 12, 'MarkerEdgeColor', 'k');
line (well_locdim1, well_locdim2, 'Marker', 'o', 'MarkerSize', 12, 'MarkerEdgeColor', 'k');
title('Cross-section view')
% plot(SheetShape(:, 1), SheetShape(:, 2))