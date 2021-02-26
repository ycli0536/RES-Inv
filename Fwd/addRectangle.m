function SheetShape = addRectangle(length, width, center, R_angle)

     center_dim1 = center(1);
     center_dim2 = center(2);
     theta = R_angle * pi / 180;

     R = [cos(theta) -sin(theta);
          sin(theta)  cos(theta)];
     
     ref_points = [- length / 2,   width / 2;
                    length / 2,   width / 2;
                    length / 2, - width / 2;
               - length / 2, - width / 2];

     initial_points = ref_points * R;

     SheetShape = [initial_points(:, 1) + center_dim1 initial_points(:, 2) + center_dim2];
end
