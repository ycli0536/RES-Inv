% calculate global index of cells in a mesh, with directional hx, hy, hz
% index
function globalInd = DirectionalIndex2GlobalIndex(Nx,Ny,Nz,directionalxyz)
% Nx, Ny, Nz: # of cells of a mesh in x, y, z direction
% directionalxyz: 3-column matrix, each column is the directional index of
% the cell

globalInd = (directionalxyz(:,2)-1)*Nx*Nz + (directionalxyz(:,1)-1)*Nz + directionalxyz(:,3);

end