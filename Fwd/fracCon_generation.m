%fraCon_generation - blk_info random generation for fracturing forward problem
%
% FUNCTION: [directions, ShapeCollect, C, coe] = ...
%           fracCon_generation(randomShape, num_vertices, fracLoc, fracCon, minSize, Count, Config_file, host)
%
% INPUT
% randomShape: Rule of random sheet shape generator
% num_vertices: The number of vertices of set polygon (e.g., 8)
% fracLoc: [xmin xmax ymin ymax zmax zmin] the area where fractruing plane is set (e.g., [300 300 -200 200 -1700 -2100])
% fracCon: A simplified conductivity value of fracturing zone reflecting saturation (e.g., fracCon = 250)
% minSize: Mesh size of core volume area (e.g., [50, 50, 50])
% Count: The number of samples to be generated (e.g., 30000)
% Config_file: configuration file with labelPath and a filename about generated lables with blk_info
% OUTPUT
% directions: General direction set of fracturing fluid distribution
% ShapeCollect: Shape set of fracturing fluid distribution
% C: The cell structure contains blk_info [blkLoc blkCon]
% coe: Area-averaging coe matrix (fracturing Conductivity distribution matrix = coe * fracCon)
function [directions, ShapeCollect, C, coe] = ...
            fracCon_generation(randomShape, num_vertices, fracLoc, fracCon, minSize, Count, Config_file)

    PATH = config_parser(Config_file, 'PATH');

    labelPath = PATH.labelPath;

    if exist(labelPath, 'dir') == 0;     mkdir(labelPath);     end
    filename = PATH.label_file;

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

    C = cell(Count+1,1); % one more C data
    C{1, 1} = [fracturingLoc zeros(length(nodes), 1)]; % first for initial E-field data
    coe = cell(length(Count),1);
    ShapeCollect = zeros(num_vertices, Count*2);
    directions = [];
    for i = 2:Count + 1
        % randomShape generation
        if strcmpi(randomShape, 'ellipse')
            SheetShape = addRandomEllipses([50, 150], [80, 180], [center_dim1, center_dim2], 15, num_vertices);
        elseif strcmpi(randomShape, 'rectangle')
            SheetShape = addRandomRectangles([80, 260], [80, 260], [center_dim1, center_dim2], 20);
        elseif strcmpi(randomShape, 'polygon8')
            % pseudo-random 8 control points detemining ploygon's shape
            [~, SheetShape] = randomShape(r, center_dim1, center_dim2);
        elseif strcmpi(randomShape, 'polygonN')
            SheetShape = addRandomShapes([30, 150], [center_dim1, center_dim2], num_vertices, 30);
        end

        ShapeCollect(:, 2 * i - 1: 2 * i) = SheetShape;
        % directions = [directions; direction];
        % shape2coe
        Sheetpolygon = polyshape(SheetShape(:,1), SheetShape(:,2));
        fracturingCon = nan * ones(length(nodes), 1);
        for j = 1:length(nodes)
            polyout = intersect(meshlist(j), Sheetpolygon);
            % formula = fracCon(250) * (area/max_area(2500))
            fracturingCon(j) = fracCon * area(polyout) / abs(minSize(index(3,1)) * minSize(index(3,2)));
        end
        C{i, 1} = [fracturingLoc fracturingCon];
        coe{i - 1, 1} = reshape(fracturingCon / fracCon, [2*n 2*n]);
    end

    save([labelPath filename], 'ShapeCollect', 'C', 'coe', 'directions', 'fracLoc', 'fracCon');

    % --plot test--
    % 
    % for i = 1:length(nodes)
    %     plot(meshlist(i))
    %     hold on
    %     axis equal
    %     axis([-200 200 -2100 -1700])
    % end
    % % 
    % k = 5;
    % plot(polyshape(ShapeCollect(:, 2 * k + 1), ShapeCollect(:, 2 * (k + 1))))
    % figure; imagesc((-175:50:175), (-1725:-50:-2075), coe{k,1} * fracCon);
    % axis equal
    % axis tight
    % set(gca,'ydir','normal');
    % % disp(directions(k))

end
