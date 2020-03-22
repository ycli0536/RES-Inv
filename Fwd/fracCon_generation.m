clear

Config_file = 'ModelsDesign_2d.ini';
PATH = config_parser(Config_file, 'PATH');
Mesh = config_parser(Config_file, 'Mesh');
savePath = PATH.savePath_PC;
if exist(savePath, 'dir') == 0;     mkdir(savePath);     end
minSize = Mesh.minSize;

fracLoc = [300 300 -200 200 -1700 -2100];
fracCon = 250;
BatchNumber = 30;
BatchSize = 1000;
for k = 1:BatchNumber
    tic
    filename = ['SheetShape#' num2str(fracCon) '_fracCon' num2str(k, '%02d') '.mat'];
    fracCon_generator(fracLoc, fracCon, minSize, BatchSize, savePath, filename);
    toc
end

function [directions, ShapeCollect, C, coe] = fracCon_generator(fracLoc, fracCon, minSize, count, savePath, filename)

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

center_dim1 = (fracLoc(index(1,1)) + fracLoc(index(1,2)))/2;
center_dim2 = (fracLoc(index(2,1)) + fracLoc(index(2,2)))/2;

C = cell(length(count),1);
coe = cell(length(count),1);
ShapeCollect = zeros(8, count*2);
directions = [];
for i = 1:count
    % randomShape generation
    % pseudo-random 8 control points detemining ploygon's shape
    [direction, SheetShape] = randomShape(r, center_dim1, center_dim2);
    ShapeCollect(:, 2 * i - 1: 2 * i) = SheetShape;
    directions = [directions; direction];
    % shape2coe
    Sheetpolygon = polyshape(SheetShape(:,1), SheetShape(:,2));
    fracturingCon = nan * ones(length(nodes), 1);
    for j = 1:length(nodes)
        polyout = intersect(meshlist(j), Sheetpolygon);
        % formula = fracCon(250) * (area/max_area(2500))
        fracturingCon(j) = fracCon * area(polyout) / abs(minSize(index(3,1)) * minSize(index(3,2)));
    end
    C{i,1} = [fracturingLoc fracturingCon];
    coe{i,1} = reshape(fracturingCon / fracCon, [2*n 2*n]);
end

save([savePath filename], 'ShapeCollect', 'C', 'coe', 'directions', 'fracLoc', 'fracCon');

% --plot test--
% 
% for i = 1:length(nodes)
%     plot(meshlist(i))
%     hold on
%     axis equal
%     axis([-200 200 -2100 -1700])
% end
% 
% k = 5;
% plot(polyshape(ShapeCollect(:, 2 * k - 1), ShapeCollect(:, 2 * k)))
% figure; imagesc((-175:50:175), (-1725:-50:-2075), coe{k,1} * fracCon);
% axis equal
% axis tight
% set(gca,'ydir','normal');
% disp(directions(k))

end

