% Form lists of nodes, edges, lengths, faces, areas, cells, volumes for a
% given rectilinear mesh
% function [nodes, edges, lengths, faces, areas, cells, volumes] = ...
%    formRectMeshConnectivity(nodeX,nodeY,nodeZ)
% INPUT
%     nodeX,nodeY,nodeZ: nodes' location in X, Y, Z of a rectilinear mesh
% OUTPUT
%     nodes: a 3-column matrix of X-Y-Z locations for the nodes (grid conjunction)
%     edges: a 2-column matrix of node index for the edges; 1st column for
%     starting node and 2nd column for ending node
%     lengths: a vector of the edges' lengths in meter
%     faces: a 4-column matrix of edge index for the faces
%     areas: a vector of the faces' area in square meter
%     cells: a 6-column matrix of face index for the cells
%     volumes: a vector of the cells' volume in cubic meter
% NOTE
% first level ordering: for directional objects (edge and face's normal), follow x,y,z orientation
% second level ordering: for non-directional objects (cell) and within a
% particular orientation, count in -z,+x,+y order (like UBCGIF meshtools model) 
function [nodes, edges, lengths, faces, areas, cells, volumes] = ...
                                formRectMeshConnectivity(nodeX,nodeY,nodeZ)

    % create nodes lists 
    % # of nodes
    Nx = length(nodeX);
    Ny = length(nodeY);
    Nz = length(nodeZ);
    [a, b, c] = meshgrid(nodeX,nodeZ,nodeY);
    nodes = [a(:) c(:) b(:)]; % X-Y-Z location (note ordering)

    % create edges list (index to nodes)
    % x-direction edges
    [a, b, c] = meshgrid(1:Nx-1,1:Nz,1:Ny);
    xcell = a(:);
    ynode = c(:);
    znode = b(:);
    x1 = (Nx*Nz)*(ynode-1) + Nz*(xcell-1) + znode;
    x2 = x1 + Nz;
    % y-direction edges
    [a, b, c] = meshgrid(1:Nx,1:Nz,1:Ny-1);
    xnode = a(:);
    ycell = c(:);
    znode = b(:);
    y1 = (Nx*Nz)*(ycell-1) + Nz*(xnode-1) + znode;
    y2 = y1 + Nx*Nz;
    % z-direction edges
    [a, b, c] = meshgrid(1:Nx,1:Nz-1,1:Ny);
    xnode = a(:);
    ynode = c(:);
    zcell = b(:);
    z1 = (Nx*Nz)*(ynode-1) + Nz*(xnode-1) + zcell;
    z2 = z1 + 1;
    % assembly in order of x-, y-, z-oriented edges
    n1 = [x1; y1; z1]; % 1st node of each edge
    n2 = [x2; y2; z2]; % 2nd node of each edge
    edges = [n1 n2];

    % create lengths list (in meter)
    lengths = sqrt( sum( ( nodes(edges(:,1),:) - nodes(edges(:,2),:) ).^2 , 2) );

    % create faces list (index to edges)
    NedgesX = (Nx-1) * Ny * Nz;
    NedgesY = Nx * (Ny-1) * Nz;
    NedgesZ = Nx * Ny * (Nz-1);
    % x-face built with y-edge and z-edge
    tmp = reshape(1:NedgesY,Nz,Nx,Ny-1);
    tmp(Nz,:,:) = [];
    xfye1 = reshape(tmp,[],1) + NedgesX; % x-face's y-edge # 1
    xfye2 = xfye1 + 1; % x-face's y-edge # 2
    tmp = reshape(1:NedgesZ,Nz-1,Nx,Ny);
    tmp(:,:,Ny) = [];
    xfze1 = reshape(tmp,[],1) + NedgesX + NedgesY; % x-face's z-edge # 1
    xfze2 = xfze1 + (Nz-1) * Nx; % x-face's z-edge # 2
    % y-face built with x-edge and z-edge
    tmp = reshape(1:NedgesX,Nz,Nx-1,Ny);
    tmp(Nz,:,:) = [];
    yfxe1 = reshape(tmp,[],1); 
    yfxe2 = yfxe1 + 1;
    tmp = reshape(1:NedgesZ,Nz-1,Nx,Ny);
    tmp(:,Nx,:) = [];
    yfze1 = reshape(tmp,[],1) + NedgesX + NedgesY;
    yfze2 = yfze1 + Nz - 1;
    % z-face built with x-edge and y-edge
    tmp = reshape(1:NedgesX,Nz,Nx-1,Ny);
    tmp(:,:,Ny) = [];
    zfxe1 = reshape(tmp,[],1);
    zfxe2 = zfxe1 + Nz * (Nx-1);
    tmp = reshape(1:NedgesY,Nz,Nx,Ny-1);
    tmp(:,Nx,:) = [];
    zfye1 = reshape(tmp,[],1) + NedgesX;
    zfye2 = zfye1 + Nz;
    % assembly: four edges per face, faces in x,y,z orientation
    faces = [xfye1 xfye2 xfze1 xfze2;
            yfxe1 yfxe2 yfze1 yfze2;
            zfxe1 zfxe2 zfye1 zfye2];
        
    % create areas list (in meter squared)
    areas = lengths(faces(:,1)) .* lengths(faces(:,3)); % the 1st and 3rd edges are perpendicular
        
        
    % create cells list (index to faces)
    NfacesX = Nx * (Ny-1) * (Nz-1);
    NfacesY = (Nx-1) * Ny * (Nz-1);
    NfacesZ = (Nx-1) * (Ny-1) * Nz;
    % x-face
    tmp = reshape(1:NfacesX,Nz-1,Nx,Ny-1);
    tmp(:,Nx,:) = [];
    xf1 = reshape(tmp,[],1);
    xf2 = xf1 + Nz - 1;
    % y-face
    tmp = reshape(1:NfacesY,Nz-1,Nx-1,Ny);
    tmp(:,:,Ny) = [];
    yf1 = reshape(tmp,[],1) + NfacesX;
    yf2 = yf1 + (Nz-1) * (Nx-1);
    % z-face
    tmp = reshape(1:NfacesZ,Nz,Nx-1,Ny-1);
    tmp(Nz,:,:) = [];
    zf1 = reshape(tmp,[],1) + NfacesX + NfacesY;
    zf2 = zf1 + 1;
    % assembly: six faces per cell
    cells = [xf1 xf2 yf1 yf2 zf1 zf2];

    % create volumes list (in meter cubed)
    volumes = sqrt( areas(cells(:,1)) .* areas(cells(:,3)) .* areas(cells(:,5)) ); % the 1st, 3rd and 5th faces are perpendicular

end
