% complete mesh info stored in node vectors nodeX, nodeY, nodeZ
% this function calculate most useful parameters of a mesh from node info
function [Nx, Ny, Nz, x0, y0, z0, hx, hy, hz, centerX, centerY, centerZ] ...
    = getMeshPara(nodeX,nodeY,nodeZ)

    Nx = length(nodeX) - 1;
    Ny = length(nodeY) - 1;
    Nz = length(nodeZ) - 1;

    x0 = nodeX(1);
    y0 = nodeY(1);
    z0 = nodeZ(1);

    hx = node2size(nodeX);
    hy = node2size(nodeY);
    hz = node2size(nodeZ);

    centerX = node2center(nodeX);
    centerY = node2center(nodeY);
    centerZ = node2center(nodeZ);

end
