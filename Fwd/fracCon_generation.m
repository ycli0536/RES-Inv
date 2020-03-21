function [direction, SheetShape] = fracCon_generation(fracLoc, fracCon, minSize, count)

% dx = minSize(1); dy = minSize(2); dz = -minSize(3); % negative number
minSize(3) = - minSize(3);
n = 4; % 4*minSize expansion
% which dimension (x/y/z) fracturing sheet loss
objType = find([fracLoc(1)-fracLoc(2); fracLoc(3)-fracLoc(4); fracLoc(5)-fracLoc(6)] == 0);

switch objType
    case 1 % 1 -> YOZ plane
        index = [3 4; 5 6; 2 3]; % [fracCon_index_dim1;fracCon_index_dim2; minSize_dim]
        r = n/2 * abs(minSize(objType)); % basical radius with 3sigma principle
    case 2 % 2 -> XOZ plane
        index = [1 2; 5 6; 1 3];
        r = n/2 * abs(minSize(objType)); % basical radius with 3sigma principle
    case 3 % 3 -> XOY plane
        index = [1 2; 3 4; 1 2];
        r = n/2 * abs(minSize(objType)); % basical radius with 3sigma principle
end

% e.g., YOZplane: [y1, z1] = meshgrid(fracLoc(3):dy:fracLoc(4)-dy, fracLoc(5):dz:fracLoc(6)-dz);
[dim1_1, dim2_1] = meshgrid(fracLoc(index(1,1)):minSize(index(3,1)):fracLoc(index(1,2))-minSize(index(3,1)), ...
                            fracLoc(index(2,1)):minSize(index(3,2)):fracLoc(index(2,2))-minSize(index(3,2)));
[dim1_2, dim2_2] = meshgrid(fracLoc(index(1,1))+minSize(index(3,1)):minSize(index(3,1)):fracLoc(index(1,2)), ...
                            fracLoc(index(2,1)):minSize(index(3,2)):fracLoc(index(2,2))-minSize(index(3,2)));
[dim1_3, dim2_3] = meshgrid(fracLoc(index(1,1))+minSize(index(3,1)):minSize(index(3,1)):fracLoc(index(1,2)), ...
                            fracLoc(index(2,1))+minSize(index(3,2)):minSize(index(3,2)):fracLoc(index(2,2)));
[dim1_4, dim2_4] = meshgrid(fracLoc(index(1,1)):minSize(index(3,1)):fracLoc(index(1,2))-minSize(index(3,1)), ...
                            fracLoc(index(2,1))+minSize(index(3,2)):minSize(index(3,2)):fracLoc(index(2,2)));
nodes = [dim1_1(:) dim1_2(:) dim1_3(:) dim1_4(:) dim2_1(:) dim2_2(:) dim2_3(:) dim2_4(:)];

meshlist = [];
fracturingLoc = repmat(fracLoc, length(nodes), 1);
for i = 1:length(nodes)
    mini_mesh = polyshape(nodes(i,1:4), nodes(i,5:8));
    meshlist = [meshlist; mini_mesh];
    fracturingLoc(i, index(1,1)) = nodes(i, 1);
    fracturingLoc(i, index(1,2)) = nodes(i, 2);
    fracturingLoc(i, index(2,1)) = nodes(i, 6);
    fracturingLoc(i, index(2,2)) = nodes(i, 7);
end

%% randomShape generation
center_dim1 = (fracLoc(index(1,1)) + fracLoc(index(1,2)))/2;
center_dim2 = (fracLoc(index(2,1)) + fracLoc(index(2,2)))/2;

% pseudo-random 8 control points detemining ploygon's shape
[direction, SheetShape] = randomShape(r, center_dim1, center_dim2);

%% shape2coe
Sheetpolygon = polyshape(SheetShape(:,1), SheetShape(:,2));

fracturingCon = nan * ones(length(nodes), 1);
C = cell(length(count),1);
coe = cell(length(count),1);
for i = 1:count
    areas = zeros(num_mesh, 1);
    for j = 1:num_mesh
        polyout = intersect(meshlist(j), Sheetpolygon);
        fracturingCon(j) = fracCon * area(polyout) / (minSize(objType))^2; % formula = fracCon(250) * (area/max_area(2500))
    end
    C{i,1} = [fracturingLoc fracturingCon];
    coe{i,1} = reshape(fracturingCon / fracCon, [2*n 2*n]);
end

%% plot test

% for i = 1:length(nodes)
%     plot(meshlist(i))
%     hold on
%     axis equal
%     axis([-200 200 -2100 -1700])
% end
% plot(Sheetpolygon)

% figure; imagesc((-175:50:175), (-1725:-50:-2075), coe{1,1});
% axis equal
% axis tight
% set(gca,'ydir','normal');

end

