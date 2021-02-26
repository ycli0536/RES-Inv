% calculate directional hx, hy, hz index, with global index of cells in a mesh 
function directionalInd = GlobalIndex2DirectionalIndex(Nx,Ny,Nz,globalInd)
% Nx, Ny, Nz: # of cells of a mesh in x, y, z direction
% globalInd: 1-column vector, global index of the cells
    globalInd = reshape(globalInd,[],1);
    yind = ceil(globalInd./Nx./Nz);
    xind = ceil( (globalInd-(yind-1).*Nx.*Nz) ./ Nz );
    zind = globalInd - (yind-1).*Nx.*Nz - (xind-1).*Nz;
    directionalInd = [xind yind zind];
end
