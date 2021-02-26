function SheetShape = addRandomRectangles(length_range, width_range, ref_center, max_displacement)
% length_range = [80, 280];
% width_range = [80, 280];
% ref_center = [0, -1900];
% max_displacement = 30;
minlength = length_range(1);
maxlength = length_range(2);
minwidth = width_range(1);
maxwidth = width_range(2);
mincenterLocX = ref_center(1) - max_displacement;
maxcenterLocX = ref_center(1) + max_displacement;
mincenterLocY = ref_center(2) - max_displacement;
maxcenterLocY = ref_center(2) + max_displacement;

length = minlength + (maxlength - minlength) * rand(1);
width = minwidth + (maxwidth - minwidth) * rand(1);
center = [mincenterLocX + (maxcenterLocX - mincenterLocX) * rand(1), ...
          mincenterLocY + (maxcenterLocY - mincenterLocY) * rand(1)];
R_angle = 360 * rand(1);

SheetShape = addRectangle(length, width, center, R_angle);

% Sheetpolygon = polyshape(SheetShape(:, 1), SheetShape(:, 2));
% figure; plot(Sheetpolygon)
end
