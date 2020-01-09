% form a interpolation matrix to project values on a lattice grid to
% arbitrary points (getting data from fwd modeling)
% FUNCTION P = formLatticeTrilinearInterpMatrix(nodeX,nodeY,nodeZ,points)
% INPUT
%     nodeX, nodeY, nodeZ: define a lattice structure
%     points: a x--y-z matrix of the inquiry points
% OUTPUT
%     P: a sparse projection matrix
function P = formLatticeTrilinearInterpMatrix(nodeX,nodeY,nodeZ,points)

Nnode = length(nodeX) * length(nodeY) * length(nodeZ);
Np = size(points,1);
x = points(:,1);
y = points(:,2);
z = points(:,3);
Nx = length(nodeX)-1;
Ny = length(nodeY)-1;
Nz = length(nodeZ)-1;

% in case a point is beyond lattice limits, find the nearest for them
% to make sure all inquiry points are within the lattice structure
x(x<nodeX(1)) = nodeX(1);
x(x>nodeX(end)) = nodeX(end);
y(y<nodeY(1)) = nodeY(1);
y(y>nodeY(end)) = nodeY(end);
z(z>nodeZ(1)) = nodeZ(1);
z(z<nodeZ(end)) = nodeZ(end);

% Trilinear interp: a point in a cubic volume; the weight of a particular
% vertex is proportional to its cooresponding 3D diagonally opposite volume.

% convert points to cellInd, then to directional ind
cellInd = PointXYZ2CellIndex([x y z],nodeX,nodeY,nodeZ);
directionalInd = GlobalIndex2DirectionalIndex(Nx,Ny,Nz,cellInd);
xind = directionalInd(:,1);
yind = directionalInd(:,2);
zind = directionalInd(:,3); 
% nodes ind for the enclosing cube (used for entry position in projection matrix)
n1ind = DirectionalIndex2GlobalIndex(Nx+1,Ny+1,Nz+1,[xind yind zind]); % node # 1
n2ind = DirectionalIndex2GlobalIndex(Nx+1,Ny+1,Nz+1,[xind yind zind+1]); % node # 2
n3ind = DirectionalIndex2GlobalIndex(Nx+1,Ny+1,Nz+1,[xind+1 yind zind]); % node # 3
n4ind = DirectionalIndex2GlobalIndex(Nx+1,Ny+1,Nz+1,[xind+1 yind zind+1]); % node # 4
n5ind = DirectionalIndex2GlobalIndex(Nx+1,Ny+1,Nz+1,[xind yind+1 zind]); % node # 5
n6ind = DirectionalIndex2GlobalIndex(Nx+1,Ny+1,Nz+1,[xind yind+1 zind+1]); % node # 6
n7ind = DirectionalIndex2GlobalIndex(Nx+1,Ny+1,Nz+1,[xind+1 yind+1 zind]); % node # 7
n8ind = DirectionalIndex2GlobalIndex(Nx+1,Ny+1,Nz+1,[xind+1 yind+1 zind+1]); % node # 8
% location of the enclosing cube (used for weights in projection matrix)
xmin = nodeX(xind); xmax = nodeX(xind+1);
ymin = nodeY(yind); ymax = nodeY(yind+1);
zmax = nodeZ(zind); zmin = nodeZ(zind+1);
dx1 = x-xmin; dx2 = xmax-x; % sub-cell dimensions
dy1 = y-ymin; dy2 = ymax-y; % sub-cell dimensions
dz1 = zmax-z; dz2 = z-zmin; % sub-cell dimensions
vol = (xmax-xmin) .* (ymax-ymin) .* (zmax-zmin); % cell volumes
n8wgt = dx1 .* dy1 .* dz1 ./ vol; % normalized vol of sub-cell # 1 = weight for node # 8
n7wgt = dx1 .* dy1 .* dz2 ./ vol; % normalized vol of sub-cell # 2 = weight for node # 7
n6wgt = dx2 .* dy1 .* dz1 ./ vol; % normalized vol of sub-cell # 3 = weight for node # 6
n5wgt = dx2 .* dy1 .* dz2 ./ vol; % normalized vol of sub-cell # 4 = weight for node # 5
n4wgt = dx1 .* dy2 .* dz1 ./ vol; % normalized vol of sub-cell # 5 = weight for node # 4
n3wgt = dx1 .* dy2 .* dz2 ./ vol; % normalized vol of sub-cell # 6 = weight for node # 3
n2wgt = dx2 .* dy2 .* dz1 ./ vol; % normalized vol of sub-cell # 7 = weight for node # 2
n1wgt = dx2 .* dy2 .* dz2 ./ vol; % normalized vol of sub-cell # 8 = weight for node # 1
% form projection matrix
I = repmat((1:Np)',8,1);
J = [n1ind; n2ind; n3ind; n4ind; n5ind; n6ind; n7ind; n8ind];
S = [n1wgt; n2wgt; n3wgt; n4wgt; n5wgt; n6wgt; n7wgt; n8wgt]; 
P = sparse(I,J,S,Np,Nnode); % bilinear interp.

end