function [direction, SheetShape] = randomShape_generator(n, R, meshsize1, meshsize2, center_dim1, center_dim2)

% INPUT: r - basical radius with 3sigma principle
%        center_dim1 - center location in first dimension
%        center_dim2 - center location in second dimension

num_axes = 8;
areas = zeros(1,num_axes);
label = ["U", "UR", "R", "DR", "D", "DL", "L", "UL", "None"]; % direction labels

% 8 regions determining 8 directions
a = 2*R; % long axis
b = R/2; % short axis
basicVectors = [  0,   a;   sqrt(2) / 2 * a,   sqrt(2) / 2 * a;
                  a,   0;   sqrt(2) / 2 * a, - sqrt(2) / 2 * a;
                  0, - a; - sqrt(2) / 2 * a, - sqrt(2) / 2 * a;
                - a,   0; - sqrt(2) / 2 * a,   sqrt(2) / 2 * a];
CtrlPoints = [center_dim1 - b, center_dim2; center_dim1 - sqrt(2) / 2 * b, center_dim2 + sqrt(2) / 2 * b;
              center_dim1, center_dim2 + b; center_dim1 + sqrt(2) / 2 * b, center_dim2 + sqrt(2) / 2 * b;
              center_dim1 + b, center_dim2; center_dim1 + sqrt(2) / 2 * b, center_dim2 - sqrt(2) / 2 * b;
              center_dim1, center_dim2 - b; center_dim1 - sqrt(2) / 2 * b, center_dim2 - sqrt(2) / 2 * b];

UPlimit = n * max(meshsize1, meshsize2);
DOWNlimit = 20; % [20, 200]
r = 0.5 * (UPlimit + DOWNlimit);
inter = false;
while inter == false
    a_b = r + (r - DOWNlimit) * 1/3 * randn(1,2);
    a_b(a_b > UPlimit) = UPlimit;
    a_b(a_b < DOWNlimit) = UPlimit;
    a = a_b(1);
    b = a_b(2);
    theta=(0:pi/10:2*pi)';
    alpha = pi * rand;
    x0 = -100 + 200 * rand;
    y0 = -2000 + 200 * rand; % center of ellipse & r = a + (b-a).*rand(N,1) [a, b]
    SheetShape = [x0+a*cos(alpha)*cos(theta)-b*sin(alpha)*sin(theta), ...
        y0+a*sin(alpha)*cos(theta)+b*cos(alpha)*sin(theta)];
    inter = inpolygon(center_dim1, center_dim2, SheetShape(:, 1), SheetShape(:, 2));
end
% plot(x0, y0, 'r+')
% plot(SheetShape(:, 1), SheetShape(:, 2));
% grid on
% hold on          

Sheetpolygon_0 = polyshape(SheetShape(1:length(SheetShape) - 1, 1), SheetShape(1:length(SheetShape) - 1, 2));
% dis = sqrt((SheetShape(:,1) - center_dim1).^2 + (SheetShape(:,2) - center_dim2).^2);
dis = sqrt((x0 - center_dim1).^2 + (y0 - center_dim2).^2);
degree = 360 * rand;
Sheetpolygon = rotate(Sheetpolygon_0, degree, [center_dim1 center_dim2]);

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
if dis <= 40 && abs(a - b) <= 15
    direction = label(9);
else
    [~, id] = max(areas);
    direction = label(id);
end

% figure;plot(regions(1));hold on
% plot(regions(2)); hold on
% plot(regions(3)); hold on
% plot(regions(4)); hold on
% plot(regions(5)); hold on
% plot(regions(6)); hold on
% plot(regions(7)); hold on
% plot(regions(8)); hold on
% % plot(Sheetpolygon_0);hold on
% plot(Sheetpolygon);hold on
% grid on
% title(direction)


end