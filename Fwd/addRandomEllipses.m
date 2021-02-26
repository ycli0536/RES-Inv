function SheetShape = addRandomEllipses(a_range, b_range, ref_center, max_displacement, points_number)
% a_range = [80, 280];
% b_range = [80, 280];
% ref_center = [0, -1900];
% max_displacement = 30;
mina = a_range(1);
maxa = a_range(2);
minb = b_range(1);
maxb = b_range(2);
mincenterLocX = ref_center(1) - max_displacement;
maxcenterLocX = ref_center(1) + max_displacement;
mincenterLocY = ref_center(2) - max_displacement;
maxcenterLocY = ref_center(2) + max_displacement;

a = mina + (maxa - mina) * rand(1);
b = minb + (maxb - minb) * rand(1);
center = [mincenterLocX + (maxcenterLocX - mincenterLocX) * rand(1), ...
          mincenterLocY + (maxcenterLocY - mincenterLocY) * rand(1)];
R_angle = 360 * rand(1);

SheetShape = addEllipse(a, b, center, R_angle, points_number);

% Sheetpolygon = polyshape(SheetShape(:, 1), SheetShape(:, 2));
% figure; plot(Sheetpolygon)
end
