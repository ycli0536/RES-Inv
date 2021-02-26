% Make edgeCon, faceCon, cellCon models with blkLoc and blkCon input
% function [edgeCon,faceCon,cellCon] = makeRectMeshModels(nodeX,nodeY,nodeZ,blkLoc,blkCon,undefined)
% INPUT
%     nodeX,nodeY,nodeZ: nodes' location in X, Y, Z of a rectilinear mesh
%     blkLoc: a Nblock x 6 matrix whose columns are [xmin xmax ymin ymax
%     zmax zmin]; if the span of any dimension is zero, that dimension
%     vanishes; one dimension vanishes for 2D sheet object; two dimensions
%     vanish for 1D line object; point object not allowed.
%     blkCon: a Nblock vector for the blocks' conductivity; S/m for 3D
%     volumic object; S for 2D sheet object; S*m for 1D line object.
%     bgCon: background con. model defined at cell centers; used to initialize  
%     cellCon; can be a scalar or vector
% OUTPUT
%     edgeCon: a vector of conductivity model (S*m) defined on all edges
%     faceCon: a vector of conductivity model (S) defined on all faces
%     cellCon: a vector of conductivity model (S/m) defined on all cells
% NOTE
%     Entries in edgeCon and faceCon are directional. 
%     First level ordering: for directional objects (edge and face), follow x,y,z orientation
%     Second level ordering: for non-directional objects (cell) and within a
%     particular orientation, count in -z,+x,+y order (like UBCGIF meshtools model)
function [edgeCon,faceCon,cellCon] = makeRectMeshModels_t(nodeX,nodeY,nodeZ,blkLoc,blkCon,bgCon,dx,dy,dz)

    Nx = length(nodeX);
    Ny = length(nodeY);
    Nz = length(nodeZ);
    Nedges = (Nx-1) * Ny * Nz + Nx * (Ny-1) * Nz + Nx * Ny * (Nz-1);
    Nfaces = (Nx-1) * Ny * (Nz-1) + Nx * (Ny-1) * (Nz-1) + (Nx-1) * (Ny-1) * Nz;
    Ncells = (Nx-1) * (Ny-1) * (Nz-1);

    if isempty(bgCon)
        bgCon = 0;
    end
    edgeCon = zeros(Nedges,1);
    faceCon = zeros(Nfaces,1);
    cellCon = zeros(Ncells,1) + bgCon;

    if isempty(blkLoc) || isempty(blkCon)
        return;
    end

    % internal parameter
    tol = 0.01; % allow small inaccuracy for location of sheet and string

    % get connectivity lists from mesh definition
    [nodes, edges, ~, faces, ~, cells, ~] = ...
                                    formRectMeshConnectivity(nodeX,nodeY,nodeZ);

    Nblk = size(blkLoc,1);
    % replace inf with outmost boundary
    blkLoc(blkLoc(:,1)==-inf,1) = nodeX(1);
    blkLoc(blkLoc(:,2)==inf,2) = nodeX(end);
    blkLoc(blkLoc(:,3)==-inf,3) = nodeY(1);
    blkLoc(blkLoc(:,4)==inf,4) = nodeY(end);
    blkLoc(blkLoc(:,5)==inf,5) = nodeZ(1);
    blkLoc(blkLoc(:,6)==-inf,6) = nodeZ(end);

    % prescreen to identify object types
    dim = ~[abs(blkLoc(:,1)-blkLoc(:,2))==0 ...
            abs(blkLoc(:,3)-blkLoc(:,4))==0 ...
            abs(blkLoc(:,5)-blkLoc(:,6))==0  ]; % 0 indicates that dimension vanished
    objType = sum(dim,2); % dimensionality = 3 for volume, 2 for sheet, 1 for string

    % object center positions
    edgesCenter = 1/2 * (nodes(edges(:,1),:) + nodes(edges(:,2),:));
    facesCenter = 1/4 * ( edgesCenter(faces(:,1),:) + edgesCenter(faces(:,2),:) + ...
                        edgesCenter(faces(:,3),:) + edgesCenter(faces(:,4),:) );
    cellsCenter = 1/6 * ( facesCenter(cells(:,1),:) + facesCenter(cells(:,2),:) + ...
                        facesCenter(cells(:,3),:) + facesCenter(cells(:,4),:) + ...
                        facesCenter(cells(:,5),:) + facesCenter(cells(:,6),:) );
            

    for i = 1:Nblk

        xmin = min(blkLoc(i,1:2));
        xmax = max(blkLoc(i,1:2));
        ymin = min(blkLoc(i,3:4));
        ymax = max(blkLoc(i,3:4));
        zmax = max(blkLoc(i,5:6));
        zmin = min(blkLoc(i,5:6));
        [~, xminInd] = min(abs(nodeX-xmin)); % nearest snap to grid
        [~, xmaxInd] = min(abs(nodeX-xmax));
        [~, yminInd] = min(abs(nodeY-ymin));
        [~, ymaxInd] = min(abs(nodeY-ymax));
        [~, zminInd] = min(abs(nodeZ-zmin));
        [~, zmaxInd] = min(abs(nodeZ-zmax));
        
        
        switch objType(i)
            case 3 % volume -> add to cellCon
                
                ind = cellsCenter(:,1) >= nodeX(xminInd) & cellsCenter(:,1) <= nodeX(xmaxInd) & ...
                    cellsCenter(:,2) >= nodeY(yminInd) & cellsCenter(:,2) <= nodeY(ymaxInd) & ...
                    cellsCenter(:,3) <= nodeZ(zmaxInd) & cellsCenter(:,3) >= nodeZ(zminInd);
                cellCon(ind) = blkCon(i);
                
            case 2 % sheet -> add to faceCon
                
                ind = facesCenter(:,1) >= nodeX(xminInd)-tol & facesCenter(:,1) <= nodeX(xmaxInd)+tol & ...
                    facesCenter(:,2) >= nodeY(yminInd)-tol & facesCenter(:,2) <= nodeY(ymaxInd)+tol & ...
                    facesCenter(:,3) <= nodeZ(zmaxInd)+tol & facesCenter(:,3) >= nodeZ(zminInd)-tol;
    %             if xmin - xmax == 0
    %                 sheetsCenter = LocalSheet((ymax+ymin)/2, (zmax+zmin)/2, dy, 0-dz, 3);
    %                 [~, ind, ~] = intersect(facesCenter, [xmin*ones(length(sheetsCenter), 1) ...
    %                                         sheetsCenter(:,1) sheetsCenter(:,2)], 'rows', 'stable');
    %             elseif ymin-ymax == 0
    %                 sheetsCenter = LocalSheet((xmax+xmin)/2, (zmax+zmin)/2, dx, 0-dz, 3);
    %                 [~, ind, ~] = intersect(facesCenter, [sheetsCenter(:,1) ymin*ones(length(sheetsCenter), 1) ...
    %                                          sheetsCenter(:,2)], 'rows', 'stable');
    %             else
    %                 sheetsCenter = LocalSheet((xmax+xmin)/2, (ymax+ymin)/2, dx, dy, 3);
    %                 [~, ind, ~] = intersect(facesCenter, [sheetsCenter(:,1) sheetsCenter(:,2) ...
    %                                         zmin*ones(length(sheetsCenter), 1) ], 'rows', 'stable');
    %             end
                faceCon(ind) = blkCon(i);
                
            case 1 % string -> add to edgeCon
                
                ind = edgesCenter(:,1) >= nodeX(xminInd)-tol & edgesCenter(:,1) <= nodeX(xmaxInd)+tol & ...
                    edgesCenter(:,2) >= nodeY(yminInd)-tol & edgesCenter(:,2) <= nodeY(ymaxInd)+tol & ...
                    edgesCenter(:,3) <= nodeZ(zmaxInd)+tol & edgesCenter(:,3) >= nodeZ(zminInd)-tol;
                edgeCon(ind) = blkCon(i);
                
            case 0 % point -> no action
                
        end
        
    end

end
