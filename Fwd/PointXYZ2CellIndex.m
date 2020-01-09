% Input xyz locations, output cell index of the mesh for each point
% return 0 if a point is outside the mesh
% Note: if a point exactly at boundary, consider it for the next possible
% interval on the list; except for the last boundary who doesn't have a
% following interval then a point may be considered for the previous
% interval.
function cellInd = PointXYZ2CellIndex(points,nodeX,nodeY,nodeZ)
% points: 3-column XYZ locations of points
% x0, y0, z0, hx, hy, hz: mesh parameters

[Nx, Ny, Nz, x0, y0, z0, hx, hy, hz, centerX, centerY, centerZ] ...
    = getMeshPara(nodeX,nodeY,nodeZ);


npt = size(points,1);
x = points(:,1);
y = points(:,2);
z = points(:,3);
xpos = zeros(npt,1); % x cell index of points
ypos = zeros(npt,1); % y cell index of points 
zpos = zeros(npt,1); % z cell index of points 

% x
nx = length(nodeX);
[sorted, b] = sortrows([x zeros(npt,1); nodeX -inf(nx,1); nodeX(end) inf],[1 2]); % use -inf as tick indicator; use inf for a faked tick at the end
ind = find(isinf(sorted(:,2)));
for i = 1:nx
    sorted(ind(i)+1:ind(i+1)-1,2) = i;
end
sorted(ind,:) = [];
b(ind,:) = [];
xpos(b) = sorted(:,2);
xpos(xpos==nx) = nx - 1;

% y
ny = length(nodeY);
[sorted, b] = sortrows([y zeros(npt,1); nodeY -inf(ny,1); nodeY(end) inf],[1 2]);
ind = find(isinf(sorted(:,2)));
for i = 1:ny
    sorted(ind(i)+1:ind(i+1)-1,2) = i;
end
sorted(ind,:) = [];
b(ind,:) = [];
ypos(b) = sorted(:,2);
ypos(ypos==ny) = ny - 1;

% z
nz = length(nodeZ);
[sorted, b] = sortrows([z zeros(npt,1); nodeZ -inf(nz,1); nodeZ(end) inf],[-1 2]);
ind = find(isinf(sorted(:,2)));
for i = 1:nz
    sorted(ind(i)+1:ind(i+1)-1,2) = i;
end
sorted(ind,:) = [];
b(ind,:) = [];
zpos(b) = sorted(:,2);
zpos(zpos==nz) = nz - 1;

temp = (ypos-1).*Nx.*Nz + (xpos-1).*Nz + zpos;
cellInd = temp .* sign(xpos.*ypos.*zpos); % filter out outside-mesh points


% BELOW: old codes (slower for many many points)
% npt = size(points,1);
% xpos = zeros(npt,1); xgrid = nodeX;
% ypos = zeros(npt,1); ygrid = nodeY;
% zpos = zeros(npt,1); zgrid = nodeZ;
% % scan x
% for p = 1:Nx
%     xpos(points(:,1)>=xgrid(p) & points(:,1)<xgrid(p+1)) = p;
% end
% % scan y
% for p = 1:Ny
%     ypos(points(:,2)>=ygrid(p) & points(:,2)<ygrid(p+1)) = p;
% end
% % scan z (NOTE: z-ordering is downwards)
% for p = 1:Nz
%     zpos(points(:,3)<=zgrid(p) & points(:,3)>zgrid(p+1)) = p;
% end
% temp = (ypos-1).*Nx.*Nz + (xpos-1).*Nz + zpos;
% cellInd = temp .* sign(xpos.*ypos.*zpos); % filter out outside-mesh points

end