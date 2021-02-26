function SheetShape = addEllipse(a, b, center, R_angle, pointsN)

center_dim1 = center(1);
center_dim2 = center(2);
theta = R_angle * pi / 180;

R = [cos(theta) -sin(theta);
     sin(theta)  cos(theta)];

t = linspace(0, 2 * pi, pointsN + 1);
x = a * cos(t);
y = b * sin(t);
ref_points = [x(1: pointsN)' y(1: pointsN)'];
initial_points = ref_points * R;

SheetShape = [initial_points(:, 1) + center_dim1 initial_points(:, 2) + center_dim2];
end