% FUNCTION: [direction, SheetShape] = randomShape(r, center_dim1, center_dim2, screeningflag)
%
% INPUT
%   r: basical radius with 3sigma principle
%   center_dim1: center location in first dimension
%   center_dim2: center location in second dimension
%   screeningflag: wether eliminating strange shapes in advance
function [direction, SheetShape] = randomShape(r, center_dim1, center_dim2, screeningflag)

    if nargin==3
        screeningflag = 'screening'; % default parameter
    end

    % 8 random points arranged clockwise
    points_generation = 1;
    while points_generation == 1
    CtrlLengths = r * ( 1 + 1 / 3 * randn(1, 8) );
    CtrlLengths(CtrlLengths > 2*r) = 2*r;
    CtrlLengths(CtrlLengths < 0) = 0.01 * r;

    if strcmpi(screeningflag,'screening')
        standard = std(CtrlLengths);
        average = mean(CtrlLengths);
        rightdiff = CtrlLengths - [CtrlLengths(2:end), CtrlLengths(1)];
        leftdiff = CtrlLengths - [CtrlLengths(end), CtrlLengths(1:end-1)];
        diff = abs([rightdiff;leftdiff]);
        [~, j] = find(diff - average >= 0);
        if length(unique(j))>=length(j) % normal shape
            points_generation = 0;
        end
    elseif strcmpi(screeningflag,'noscreening')
        points_generation = 0;
    end

    % figure;
    % plot(CtrlLengths)
    end

    num_axes = 8;
    areas = zeros(1,num_axes);
    label = ["U", "UR", "R", "DR", "D", "DL", "L", "UL", "None"]; % direction labels

    SheetShape = [center_dim1, center_dim2 + CtrlLengths(1); center_dim1 + sqrt(2) / 2 * CtrlLengths(2), center_dim2 + sqrt(2) / 2 * CtrlLengths(2);
                center_dim1 + CtrlLengths(3), center_dim2; center_dim1 + sqrt(2) / 2 * CtrlLengths(4), center_dim2 - sqrt(2) / 2 * CtrlLengths(4);
                center_dim1, center_dim2 - CtrlLengths(5); center_dim1 - sqrt(2) / 2 * CtrlLengths(6), center_dim2 - sqrt(2) / 2 * CtrlLengths(6);
                center_dim1 - CtrlLengths(7), center_dim2; center_dim1 - sqrt(2) / 2 * CtrlLengths(8), center_dim2 + sqrt(2) / 2 * CtrlLengths(8)];

    % 8 regions determining 8 directions
    a = 2*r; % long axis
    b = r/2; % short axis
    basicVectors = [  0,   a;   sqrt(2) / 2 * a,   sqrt(2) / 2 * a;
                    a,   0;   sqrt(2) / 2 * a, - sqrt(2) / 2 * a;
                    0, - a; - sqrt(2) / 2 * a, - sqrt(2) / 2 * a;
                    - a,   0; - sqrt(2) / 2 * a,   sqrt(2) / 2 * a];
    CtrlPoints = [center_dim1 - b, center_dim2; center_dim1 - sqrt(2) / 2 * b, center_dim2 + sqrt(2) / 2 * b;
                center_dim1, center_dim2 + b; center_dim1 + sqrt(2) / 2 * b, center_dim2 + sqrt(2) / 2 * b;
                center_dim1 + b, center_dim2; center_dim1 + sqrt(2) / 2 * b, center_dim2 - sqrt(2) / 2 * b;
                center_dim1, center_dim2 - b; center_dim1 - sqrt(2) / 2 * b, center_dim2 - sqrt(2) / 2 * b];
    Sheetpolygon = polyshape(SheetShape(:,1), SheetShape(:,2));
    for i = 1: num_axes/2
        regions(i) = polyshape([CtrlPoints(i,1), CtrlPoints(i,1) + basicVectors(i,1), CtrlPoints(i + num_axes/2,1) + basicVectors(i,1), CtrlPoints(i + num_axes/2,1)], ...
                            [CtrlPoints(i,2), CtrlPoints(i,2) + basicVectors(i,2), CtrlPoints(i + num_axes/2,2) + basicVectors(i,2), CtrlPoints(i + num_axes/2,2)]);
        regions(i + num_axes/2) = polyshape([CtrlPoints(i,1), CtrlPoints(i,1) + basicVectors(i + num_axes/2,1), CtrlPoints(i + num_axes/2,1) + basicVectors(i + num_axes/2,1), CtrlPoints(i + num_axes/2,1)], ...
                                            [CtrlPoints(i,2), CtrlPoints(i,2) + basicVectors(i + num_axes/2,2), CtrlPoints(i + num_axes/2,2) + basicVectors(i + num_axes/2,2), CtrlPoints(i + num_axes/2,2)]);
        polyout1 = intersect(regions(i), Sheetpolygon);
        polyout2 = intersect(regions(i + num_axes/2), Sheetpolygon);
        areas(i) = area(polyout1);
        areas(i + num_axes/2) = area(polyout2);
    end

    % setting label
    th = 0.2;
    if standard <= th * average
        direction = label(9);
    else
        [~, id] = max(areas);
        direction = label(id);
    end
end
